#import "AUPMRepoManager.h"
#import "AUPMRepo.h"
#import "../Packages/AUPMPackage.h"
#include "dpkgver.c"

@interface AUPMRepoManager ()
    @property (nonatomic, retain) NSArray *repos;
@end

@implementation AUPMRepoManager

id packages_to_id(const char *path);

+ (id)sharedInstance {
    static AUPMRepoManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [AUPMRepoManager new];
    });
    return instance;
}

- (id)init {
    self = [super init];

    if (self) {
        self.repos = [self getRepos];
    }

    return self;
}

- (NSArray *)getRepos {
    NSArray *repos = [self reposFromDefaults];
    if (repos != NULL) {
        return repos;
    }
    else {
        repos = [self reposFromAPTList];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:repos forKey:@"Repos"];

        return repos;
    }
}

- (NSArray *)reposFromDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    return [defaults objectForKey:@"Repos"];
}

- (NSArray *)reposFromAPTList {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *aptListDirectory = @"/var/lib/apt/lists";
    NSArray *listOfFiles = [fileManager contentsOfDirectoryAtPath:aptListDirectory error:nil];
    NSMutableArray *repoArray = [[NSMutableArray alloc] init];

    for (NSString *path in listOfFiles) {
        if (([path rangeOfString:@"Release"].location != NSNotFound) && ([path rangeOfString:@".gpg"].location == NSNotFound)) {
            NSString *fullPath = [NSString stringWithFormat:@"/var/lib/apt/lists/%@", path];
            NSString *content = [NSString stringWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:NULL];

            NSString *trimmedString = [content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSArray *keyValuePairs = [trimmedString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];

            for (NSString *keyValuePair in keyValuePairs) {
                NSString *trimmedPair = [keyValuePair stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

                NSArray *keyValues = [trimmedPair componentsSeparatedByString:@":"];

                dict[[keyValues.firstObject stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]] = [keyValues.lastObject stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            }

            NSString *baseFileName = [path stringByReplacingOccurrencesOfString:@"_Release" withString:@""];
            dict[@"baseFileName"] = baseFileName;
            NSString *repoURL = baseFileName;
            repoURL = [repoURL stringByReplacingOccurrencesOfString:@"_" withString:@"/"];
            repoURL = [NSString stringWithFormat:@"http://%@", repoURL];
            dict[@"URL"] = repoURL;

            [repoArray addObject:dict];
        }
    }

    NSSortDescriptor *sortByRepoName = [NSSortDescriptor sortDescriptorWithKey:@"Origin" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortByRepoName];

    return (NSArray*)[repoArray sortedArrayUsingDescriptors:sortDescriptors];
}

- (NSArray *)managedRepoList {
    NSMutableArray *managedRepoList = [[NSMutableArray alloc] init];

    int i = 1;
    for (NSDictionary *repo in _repos) {
        AUPMRepo *source = [[AUPMRepo alloc] initWithRepoInformation:repo];
        [source setRepoID:i];
        i++;
        [managedRepoList addObject:source];
    }

    return managedRepoList;
}

- (NSArray *)cleanUpDuplicatePackages:(NSArray *)packageList {
    NSMutableDictionary *packageVersionDict = [[NSMutableDictionary alloc] init];
    NSMutableArray *cleanedPackageList = [packageList mutableCopy];

    for (AUPMPackage *package in packageList) {
        if (packageVersionDict[[package packageIdentifier]] == NULL) {
            packageVersionDict[[package packageIdentifier]] = package;
        }

        NSString *arrayVersion = [(AUPMPackage *)packageVersionDict[[package packageIdentifier]] version];
        NSString *packageVersion = [package version];
        int result = verrevcmp([packageVersion UTF8String], [arrayVersion UTF8String]);

        if (result > 0) {
            [cleanedPackageList removeObject:packageVersionDict[[package packageIdentifier]]];
            packageVersionDict[[package packageIdentifier]] = package;
        }
        else if (result < 0) {
            [cleanedPackageList removeObject:package];
        }
    }

    return (NSArray *)cleanedPackageList;
}

- (NSArray *)packageListForRepo:(AUPMRepo *)repo {
    HBLogInfo(@"Package List For Repo: %@", [repo repoName]);
    NSString *cachedPackagesFile = [NSString stringWithFormat:@"/var/lib/apt/lists/%@_Packages", [repo repoBaseFileName]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:cachedPackagesFile]) {
        cachedPackagesFile = [NSString stringWithFormat:@"/var/lib/apt/lists/%@_main_binary-iphoneos-arm_Packages", [repo repoBaseFileName]]; //Do some funky package file with the default repos
        HBLogInfo(@"Default Repo Packages File: %@", cachedPackagesFile);
    }

    NSArray *packageJSONArray = packages_to_id([cachedPackagesFile UTF8String]);
    NSMutableArray *packageListForRepo = [[NSMutableArray alloc] init];

    for (NSMutableDictionary *dict in packageJSONArray) {
        if (dict[@"Name"] == NULL) {
            dict[@"Name"] = dict[@"Package"];
        }

        if ([dict[@"Package"] rangeOfString:@"gsc"].location == NSNotFound && [dict[@"Package"] rangeOfString:@"cy+"].location == NSNotFound) {
            AUPMPackage *package = [[AUPMPackage alloc] initWithPackageInformation:dict];
            [packageListForRepo addObject:package];
        }
    }

    return packageListForRepo;
}

- (void)addSource:(NSURL *)sourceURL {
    NSString *URL = [sourceURL absoluteString];
    NSString *output;

    for (NSDictionary *repo in _repos) {
        output = [output stringByAppendingFormat:@"deb %@ ./\n", repo[@"URL"]];
    }
    output = [output stringByAppendingFormat:@"deb %@ ./\n", URL];

    NSError *error;
    [output writeToFile:@"/etc/apt/sources.list.d/cydia.list" atomically:TRUE encoding:NSUTF8StringEncoding error:&error];

    if (error != NULL) {
        HBLogError(@"Error while writing sources to file: %@", error);
    }
}

- (void)updateDefaultsFromAPTLists {
    NSArray *repos = [self reposFromAPTList];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:repos forKey:@"Repos"];
}

@end
