#import "AUPMDatabaseManager.h"
#import "NSTask.h"
#import "Repos/AUPMRepoManager.h"
#import "Repos/AUPMRepo.h"
#import "Packages/AUPMPackage.h"

@interface AUPMDatabaseManager ()
@property (nonatomic, strong) NSString *documentsDirectory;
@property (nonatomic, strong) NSString *databaseFilename;
@property (nonatomic, strong) NSMutableArray *arrResults;

- (void)copyDatabaseIntoDocumentsDirectory;
@end

@implementation AUPMDatabaseManager

- (id)initWithDatabaseFilename:(NSString *)filename {
    self = [super init];
    if (self) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        self.documentsDirectory = [paths objectAtIndex:0];
        self.databaseFilename = filename;

        [self copyDatabaseIntoDocumentsDirectory];
    }
    return self;
}

//Runs apt-get update and cahces all information from apt into a database
- (void)firstLoadPopulation:(void (^)(BOOL success))completion {
    HBLogInfo(@"Beginning first load preparation");
    NSString *databasePath = [self.documentsDirectory stringByAppendingPathComponent:self.databaseFilename];

    if (self.arrResults != nil) {
        [self.arrResults removeAllObjects];
        self.arrResults = nil;
    }
    self.arrResults = [[NSMutableArray alloc] init];

    if (self.arrColumnNames != nil) {
        [self.arrColumnNames removeAllObjects];
        self.arrColumnNames = nil;
    }
    self.arrColumnNames = [[NSMutableArray alloc] init];
    //Since this should only be called on the first load, lets nuke the database just in case... (I'll change this later)
    [self purgeRecords:databasePath];

    AUPMRepoManager *repoManager = [[AUPMRepoManager alloc] init];

    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/Applications/AUPM.app/supersling"];
    NSArray *arguments = [[NSArray alloc] initWithObjects: @"apt-get", @"update", nil];
    [task setArguments:arguments];

    [task launch];
    [task waitUntilExit];

    HBLogInfo(@"APT Done, starting db parsing");
    sqlite3_config(SQLITE_CONFIG_SERIALIZED);
    NSArray *repoArray = [repoManager managedRepoList];
    dispatch_group_t group = dispatch_group_create();
    static pthread_mutex_t mutex;
    pthread_mutex_init(&mutex,NULL);
    //dispatch_queue_t queue = dispatch_queue_create("com.xtm3x.aupm.database", DISPATCH_QUEUE_SERIAL);
    for (AUPMRepo *repo in repoArray) {
        dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
            sqlite3 *sqlite3Database;
            sqlite3_open([databasePath UTF8String], &sqlite3Database);
            sqlite3_stmt *repoStatement;
            NSString *repoQuery = @"insert into repos(repoName, repoBaseFileName, description, repoURL, icon) values(?,?,?,?,?)";

            //Populate repo database
            pthread_mutex_lock(&mutex);
            if (sqlite3_prepare_v2(sqlite3Database, [repoQuery UTF8String], -1, &repoStatement, nil) == SQLITE_OK) {
                sqlite3_bind_text(repoStatement, 1, [[repo repoName] UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(repoStatement, 2, [[repo repoBaseFileName] UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(repoStatement, 3, [[repo description] UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(repoStatement, 4, [[repo repoURL] UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_blob(repoStatement, 5, (__bridge const void *)[repo icon], -1, SQLITE_TRANSIENT);
                sqlite3_step(repoStatement);
            }
            else {
                HBLogError(@"%s", sqlite3_errmsg(sqlite3Database));
            }
            sqlite3_finalize(repoStatement);
            pthread_mutex_unlock(&mutex);

            long long lastRowId = sqlite3_last_insert_rowid(sqlite3Database);

            NSArray *packagesArray = [repoManager packageListForRepo:repo];
            HBLogInfo(@"Started to parse packages for repo %@", [repo repoName]);
            NSString *packageQuery = @"insert into packages(repoID, packageName, packageIdentifier, version, section, description, depictionURL, md5sum) values(?,?,?,?,?,?,?,?)";
            sqlite3_stmt *packageStatement;
            pthread_mutex_lock(&mutex);
            sqlite3_exec(sqlite3Database, "BEGIN TRANSACTION", NULL, NULL, NULL);
            if (sqlite3_prepare_v2(sqlite3Database, [packageQuery UTF8String], -1, &packageStatement, nil) == SQLITE_OK) {
                for (AUPMPackage *package in packagesArray) {
                    //Populate packages database with packages from repo
                    sqlite3_bind_int(packageStatement, 1, (int)lastRowId);
                    sqlite3_bind_text(packageStatement, 2, [[package packageName] UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(packageStatement, 3, [[package packageIdentifier] UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(packageStatement, 4, [[package version] UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(packageStatement, 5, [[package section] UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(packageStatement, 6, [[package description] UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(packageStatement, 7, [[package depictionURL].absoluteString UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(packageStatement, 8, [[package sum] UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_step(packageStatement);
                    sqlite3_reset(packageStatement);
                    sqlite3_clear_bindings(packageStatement);
                }
                HBLogInfo(@"Finished packages for repo %@", [repo repoName]);
            }
            else {
                HBLogError(@"%s", sqlite3_errmsg(sqlite3Database));
            }
            sqlite3_finalize(packageStatement);
            sqlite3_exec(sqlite3Database, "COMMIT TRANSACTION", NULL, NULL, NULL);
            pthread_mutex_unlock(&mutex);
        });
    }
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    completion(true);
}

- (void)updateDatabaseWithDifferences:(void (^)(BOOL success))completion {
    NSString *databasePath = [self.documentsDirectory stringByAppendingPathComponent:self.databaseFilename];
    AUPMRepoManager *repoManager = [[AUPMRepoManager alloc] init];
    NSArray *repos = [repoManager managedRepoList];

    sqlite3 *sqlite3Database;
    sqlite3_open([databasePath UTF8String], &sqlite3Database);

    for (AUPMRepo *repo in repos) {
        NSDictionary *differences = [repoManager packagesChangedInRepo:repo];
        NSArray *added = differences[@"added"];
        NSArray *removed = differences[@"removed"];

        int repoID = 0;
        NSString *query = @"select * from repos where repoBaseFileName = ?";
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(sqlite3Database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [[repo repoBaseFileName] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_step(statement);
            HBLogError(@"%s", sqlite3_errmsg(sqlite3Database));
            int iden = sqlite3_column_int(statement, 0);
            HBLogInfo(@"iden: %d", iden);
            repoID = iden;
            sqlite3_reset(statement);
            sqlite3_clear_bindings(statement);
        }
        else {
            HBLogError(@"%s", sqlite3_errmsg(sqlite3Database));
        }
        sqlite3_finalize(statement);

        HBLogInfo(@"Repo ID: %d", repoID);

        if ([added count] != 0) {
            HBLogInfo(@"Adding: %@", added);
            sqlite3_exec(sqlite3Database, "BEGIN TRANSACTION", NULL, NULL, NULL);
            NSString *packageQuery = @"insert into packages(repoID, packageName, packageIdentifier, version, section, description, depictionURL, md5sum) values(?,?,?,?,?,?,?,?)";
            sqlite3_stmt *packageStatement;
            HBLogInfo(@"Updated pacakge with repo id: %d", [repo repoIdentifier]);
            if (sqlite3_prepare_v2(sqlite3Database, [packageQuery UTF8String], -1, &packageStatement, nil) == SQLITE_OK) {
                for (NSString *string in added) {
                    NSArray *keyValuePairs = [string componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
                    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

                    for (NSString *keyValuePair in keyValuePairs) {
                        NSString *trimmedPair = [keyValuePair stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

                        NSArray *keyValues = [trimmedPair componentsSeparatedByString:@":"];

                        dict[[keyValues.firstObject stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]] = [keyValues.lastObject stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    }

                    sqlite3_bind_int(packageStatement, 1, repoID);
                    sqlite3_bind_text(packageStatement, 2, [dict[@"Name"] UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(packageStatement, 3, [dict[@"Package"] UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(packageStatement, 4, [dict[@"Version"] UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(packageStatement, 5, [dict[@"Section"] UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(packageStatement, 6, [dict[@"Description"] UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(packageStatement, 7, [[NSString stringWithFormat:@"http:%@", dict[@"Depiction"]] UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(packageStatement, 8, [dict[@"MD5sum"] UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_step(packageStatement);
                    sqlite3_reset(packageStatement);
                    sqlite3_clear_bindings(packageStatement);
                }
            }
            else {
                HBLogError(@"%s", sqlite3_errmsg(sqlite3Database));
            }
            sqlite3_finalize(packageStatement);
            sqlite3_exec(sqlite3Database, "COMMIT TRANSACTION", NULL, NULL, NULL);
        }

        if ([removed count] != 0) {
            HBLogInfo(@"Removing: %@", removed);
            sqlite3_stmt *packageStatement;
            sqlite3_exec(sqlite3Database, "BEGIN TRANSACTION", NULL, NULL, NULL);
            for (NSString *sum in removed) {
                NSString *packageQuery = [NSString stringWithFormat:@"DELETE FROM packages WHERE md5sum='%@'", sum];
                if (sqlite3_prepare_v2(sqlite3Database, [packageQuery UTF8String], -1, &packageStatement, nil) == SQLITE_OK) {
                    sqlite3_bind_text(packageStatement, 1, [sum UTF8String], -1, SQLITE_TRANSIENT);
                    while (sqlite3_step(packageStatement) == SQLITE_ROW) {
                        const char *packageNameChars = (const char *)sqlite3_column_text(packageStatement, 3);
                        NSString *packageName = [[NSString alloc] initWithUTF8String:packageNameChars];
                        HBLogInfo(@"Removal Result: %@", packageName);
                    }
                    sqlite3_reset(packageStatement);
                    sqlite3_clear_bindings(packageStatement);
                }
                else {
                    HBLogError(@"%s", sqlite3_errmsg(sqlite3Database));
                }
            }
            sqlite3_finalize(packageStatement);
            sqlite3_exec(sqlite3Database, "COMMIT TRANSACTION", NULL, NULL, NULL);

        }
        sqlite3_close(sqlite3Database);
    }
    completion(true);
}

- (NSArray *)cachedListOfRepositories {
    HBLogInfo(@"Getting cached list of repos");
    sqlite3 *database;
    NSString *path = [self.documentsDirectory stringByAppendingPathComponent:self.databaseFilename];
    sqlite3_open([path UTF8String], &database);
    NSMutableArray *listOfRepositories = [[NSMutableArray alloc] init];
    NSString *query = @"SELECT * FROM repos";
    sqlite3_stmt *statement;
    //packageName, packageIdentifier, version, section, description, depictionURL
    if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            int uniqueId = sqlite3_column_int(statement, 0);
            const char *repoNameChars = (const char *)sqlite3_column_text(statement, 1);
            const char *repoFileNameChars = (const char *)sqlite3_column_text(statement, 2);
            const char *descriptionChars = (const char *)sqlite3_column_text(statement, 3);
            const char *repoURLChars = (const char *)sqlite3_column_text(statement, 4);
            NSString *repoName = [[NSString alloc] initWithUTF8String:repoNameChars];
            NSString *repoBaseFileName = [[NSString alloc] initWithUTF8String:repoFileNameChars];
            NSString *description = [[NSString alloc] initWithUTF8String:descriptionChars];
            NSString *repoURL = [[NSString alloc] initWithUTF8String:repoURLChars];
            AUPMRepo *repo = [[AUPMRepo alloc] initWithRepoID:uniqueId name:repoName baseFileName:repoBaseFileName description:description url:repoURL];
            [listOfRepositories addObject:repo];
        }
        sqlite3_finalize(statement);
    }
    else {
        HBLogError(@"%s", sqlite3_errmsg(database));
    }
    sqlite3_close(database);
    NSSortDescriptor *sortByRepoName = [NSSortDescriptor sortDescriptorWithKey:@"repoName" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortByRepoName];

    return (NSArray*)[listOfRepositories sortedArrayUsingDescriptors:sortDescriptors];
}

- (NSArray *)cachedPackageListForRepo:(AUPMRepo *)repo {
    HBLogInfo(@"Getting installed pacakges for repo");
    sqlite3 *database;
    NSString *path = [self.documentsDirectory stringByAppendingPathComponent:self.databaseFilename];
    sqlite3_open([path UTF8String], &database);
    NSMutableArray *listOfPackages = [[NSMutableArray alloc] init];
    NSString *query = @"SELECT * FROM packages WHERE repoID = ?";
    sqlite3_stmt *statement;
    if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
        sqlite3_bind_int(statement, 1, [repo repoIdentifier]);
        while (sqlite3_step(statement) == SQLITE_ROW) {
            //int uniqueId = sqlite3_column_int(statement, 0);
            const char *packageNameChars = (const char *)sqlite3_column_text(statement, 2);
            const char *packageIDChars = (const char *)sqlite3_column_text(statement, 3);
            const char *versionChars = (const char *)sqlite3_column_text(statement, 4);
            const char *sectionChars = (const char *)sqlite3_column_text(statement, 5);
            const char *descriptionChars = (const char *)sqlite3_column_text(statement, 6);
            const char *depictionChars = (const char *)sqlite3_column_text(statement, 7);
            const char *sumChars = (const char *)sqlite3_column_text(statement, 9);
            NSString *packageName = [[NSString alloc] initWithUTF8String:packageNameChars];
            NSString *packageID = [[NSString alloc] initWithUTF8String:packageIDChars];
            NSString *version = [[NSString alloc] initWithUTF8String:versionChars];
            NSString *section = [[NSString alloc] initWithUTF8String:sectionChars];
            NSString *description = [[NSString alloc] initWithUTF8String:descriptionChars];
            NSString *depictionURL;
            if (depictionChars == NULL)
                depictionURL = nil;
            else
                depictionURL = [[NSString alloc] initWithUTF8String:depictionChars];
            NSString *md5sum = [[NSString alloc] initWithUTF8String:sumChars];

            AUPMPackage *package = [[AUPMPackage alloc] initWithPackageName:packageName packageID:packageID version:version section:section description:description depictionURL:depictionURL sum:md5sum];
            [listOfPackages addObject:package];
        }
        sqlite3_finalize(statement);
    }
    else {
        HBLogError(@"%s", sqlite3_errmsg(database));
    }
    sqlite3_close(database);
    AUPMRepoManager *repoManager = [[AUPMRepoManager alloc] init];
    NSSortDescriptor *sortByPackageName = [NSSortDescriptor sortDescriptorWithKey:@"packageName" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortByPackageName];

    return [[repoManager cleanUpDuplicatePackages:listOfPackages] sortedArrayUsingDescriptors:sortDescriptors];
}

- (void)copyDatabaseIntoDocumentsDirectory {
    NSString *destinationPath = [self.documentsDirectory stringByAppendingPathComponent:self.databaseFilename];
    if (![[NSFileManager defaultManager] fileExistsAtPath:destinationPath]) {
        NSString *sourcePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:self.databaseFilename];
        NSError *error;
        [[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:destinationPath error:&error];

        if (error != nil) {
            HBLogError(@"%@", [error localizedDescription]);
        }
    }
}

- (void)purgeRecords:(NSString *)path {
    sqlite3 *database;
    sqlite3_open([path UTF8String], &database);
    sqlite3_exec(database, "DELETE FROM REPOS", NULL, NULL, NULL);
    sqlite3_exec(database, "DELETE FROM PACKAGES", NULL, NULL, NULL);
    sqlite3_close(database);
}

@end
