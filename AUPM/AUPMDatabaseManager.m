#import "AUPMDatabaseManager.h"

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
- (void)firstLoadPopulation {
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
        //dispatch_queue_t queue = dispatch_queue_create("com.xtm3x.aupm.database", DISPATCH_QUEUE_SERIAL);
        for (AUPMRepo *repo in repoArray) {
            dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
                sqlite3 *sqlite3Database;
                sqlite3_open([databasePath UTF8String], &sqlite3Database);
                sqlite3_stmt *repoStatement;
                NSString *repoQuery = @"insert into repos(repoName, repoBaseFileName, description, repoURL, icon) values(?,?,?,?,?)";

                //Populate repo database
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

                long long lastRowId = sqlite3_last_insert_rowid(sqlite3Database);

                NSArray *packagesArray = [repoManager packageListForRepo:repo];
                HBLogInfo(@"Started to parse packages for repo %@", [repo repoName]);
                NSString *packageQuery = @"insert into packages(repoID, packageName, packageIdentifier, version, section, description, depictionURL) values(?,?,?,?,?,?,?)";
                sqlite3_exec(sqlite3Database, "BEGIN TRANSACTION", NULL, NULL, NULL);
                sqlite3_stmt *packageStatement;
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
                        sqlite3_step(packageStatement);
                        sqlite3_reset(packageStatement);
                        sqlite3_clear_bindings(packageStatement);
                    }
                    sqlite3_exec(sqlite3Database, "COMMIT TRANSACTION", NULL, NULL, NULL);
                    HBLogInfo(@"Finished packages for repo %@", [repo repoName]);
                }
                else {
                    HBLogError(@"%s", sqlite3_errmsg(sqlite3Database));
                }
                sqlite3_finalize(packageStatement);
            });
        }
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
        HBLogInfo(@"First load preparation complete");
}

- (void)copyDatabaseIntoDocumentsDirectory{
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
