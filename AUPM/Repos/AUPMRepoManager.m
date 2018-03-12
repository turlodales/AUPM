#import "AUPMRepoManager.h"
#import "AUPMRepo.h"
#import "../Packages/AUPMPackage.h"
#include "dpkgver.c"

@implementation AUPMRepoManager

id packages_to_id(const char *path);

//Parse repo list from apt and convert to an AUPMRepo file for each one and return an array of them
- (NSArray *)managedRepoList {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *aptListDirectory = @"/var/lib/apt/lists";
    NSArray *listOfFiles = [fileManager contentsOfDirectoryAtPath:aptListDirectory error:nil];
    NSMutableArray *managedRepoList = [[NSMutableArray alloc] init];

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

            // NSString *repoIconURL = [NSString stringWithFormat:@"%@/CydiaIcon.png", repoURL];
            // HBLogInfo(@"Repo Icon URL: %@", repoIconURL);
            // dict[@"Icon"] = [NSData dataWithContentsOfURL:[NSURL URLWithString:repoIconURL]];

            AUPMRepo *repo = [[AUPMRepo alloc] initWithRepoInformation:dict];
            [managedRepoList addObject:repo];
        }
    }

    NSSortDescriptor *sortByRepoName = [NSSortDescriptor sortDescriptorWithKey:@"repoName" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortByRepoName];

    return (NSArray*)[managedRepoList sortedArrayUsingDescriptors:sortDescriptors];
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

- (NSArray *)rawPackageListForRepo:(AUPMRepo *)repo {
    HBLogInfo(@"Package List For Repo: %@", [repo repoName]);
    NSString *cachedPackagesFile = [NSString stringWithFormat:@"/var/lib/apt/lists/%@_Packages", [repo repoBaseFileName]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:cachedPackagesFile]) {
        cachedPackagesFile = [NSString stringWithFormat:@"/var/lib/apt/lists/%@_main_binary-iphoneos-arm_Packages", [repo repoBaseFileName]]; //Do some funky package file with the default repos
        HBLogInfo(@"Default Repo Packages File: %@", cachedPackagesFile);
    }

    NSArray *packageJSONArray = packages_to_id([cachedPackagesFile UTF8String]);

    return packageJSONArray;
}

- (NSArray *)packagesChangedInRepo:(AUPMRepo *)repo {
    NSString *cachedPackagesFile = [NSString stringWithFormat:@"/var/mobile/Library/Caches/com.xtm3x.aupm/lists/%@_Packages", [repo repoBaseFileName]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:cachedPackagesFile]) {
        cachedPackagesFile = [NSString stringWithFormat:@"/var/mobile/Library/Caches/com.xtm3x.aupm/lists/%@_main_binary-iphoneos-arm_Packages", [repo repoBaseFileName]]; //Do some funky package file with the default repos
        HBLogInfo(@"Default Cached Repo Packages File: %@", cachedPackagesFile);
    }

    NSString *localPackagesFile = [NSString stringWithFormat:@"/var/lib/apt/lists/%@_Packages", [repo repoBaseFileName]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:localPackagesFile]) {
        localPackagesFile = [NSString stringWithFormat:@"/var/lib/apt/lists/%@_main_binary-iphoneos-arm_Packages", [repo repoBaseFileName]]; //Do some funky package file with the default repos
        HBLogInfo(@"Default Local Repo Packages File: %@", cachedPackagesFile);
    }

    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/Applications/AUPM.app/supersling"];
    NSArray *arguments = [[NSArray alloc] initWithObjects: @"diff", cachedPackagesFile, localPackagesFile, nil];
    [task setArguments:arguments];

    NSPipe *out = [NSPipe pipe];
    [task setStandardOutput:out];
    //[task setStandardError:out];

    HBLogInfo(@"Running command diff %@ %@", cachedPackagesFile, localPackagesFile);
    [task launch];
    [task waitUntilExit];

    NSData *data = [[out fileHandleForReading] readDataToEndOfFile];
    NSString *outputString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    HBLogInfo(@"Diff Result: %@", outputString);

    NSMutableArray *changedPackageSums = [[NSMutableArray alloc] init];

    if (![outputString isEqual:@""]) {
        NSArray *changes = [outputString componentsSeparatedByString:@"---"];
        for (NSString *change in changes) {
            NSArray *lines = [change componentsSeparatedByString:@"\n"];
            for (NSString *diff in lines) {
                if ([diff hasPrefix:@"> MD5sum: "]) {
                    NSString *sum = [diff stringByReplacingOccurrencesOfString:@"> MD5sum: " withString:@""];
                    HBLogInfo(@"Found added sum: %@", sum);
                    [changedPackageSums addObject:sum];
                }
            }
        }
    }

    NSArray *results;
    for (NSString *sum in changedPackageSums) {
        NSString *content = [NSString stringWithContentsOfFile:localPackagesFile encoding:NSUTF8StringEncoding error:NULL];
        NSArray *rawPackagesArray = [content componentsSeparatedByString:@"\n\n"];

        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[c] %@", sum];
        results = [rawPackagesArray filteredArrayUsingPredicate:predicate];

        HBLogInfo(@"Changes: %@", results);
    }

    return results;
}

-(NSString *)differenceBetween:(NSString *)string and:(NSString *)anotherString {
    int i = string.length;
    int j = anotherString.length;
    NSString *result, *longest, *shortest;

    if (i == j) {
        result = @"";
        return result;
    }

    if (i > j) {
        longest = string;
        shortest = anotherString;
    } else {
        longest = anotherString;
        shortest = string;
    }

    NSArray *fa = [longest componentsSeparatedByString: @" " ];
    NSArray *sa = [shortest componentsSeparatedByString: @" "];
    NSMutableArray *remainder = [NSMutableArray arrayWithArray:fa];
    [remainder removeObjectsInArray:sa];
    result = [remainder componentsJoinedByString:@" "];
    return result;
}

@end
