#import "AUPMRepoManager.h"

@implementation AUPMRepoManager

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
            dict[@"URL"] = baseFileName;

            // NSArray *urlItems = [path componentsSeparatedByString:@"_"];
            // NSString *baseUrlString = urlItems[0];
            // NSString *url = [NSString stringWithFormat:@"http://www.%@/", baseUrlString];
            // dict[@"URL"] = url;
            //
            // NSString *repoIconURL = [NSString stringWithFormat:@"%@CydiaIcon.png", url];
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

- (NSArray *)packageListForRepo:(AUPMRepo *)repo {
    NSString *cachedPackagesFile = [NSString stringWithFormat:@"/var/lib/apt/lists/%@_Packages", [repo repoURL]];
    NSMutableArray *packageListForRepo = [[NSMutableArray alloc] init];
    NSString *content = [NSString stringWithContentsOfFile:cachedPackagesFile encoding:NSUTF8StringEncoding error:NULL];

    NSArray *packageInfoArray = [content componentsSeparatedByString:@"\n\n"];

    for (NSString *package in packageInfoArray) {
        NSString *trimmedString = [package stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSArray *keyValuePairs = [trimmedString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];

        for (NSString *keyValuePair in keyValuePairs) {
            NSString *trimmedPair = [keyValuePair stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

            NSArray *keyValues = [trimmedPair componentsSeparatedByString:@":"];

            dict[[keyValues.firstObject stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]] = [keyValues.lastObject stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        }

        if (dict[@"Name"] == NULL) {
            dict[@"Name"] = dict[@"Package"];
        }

        if ([dict[@"Package"] rangeOfString:@"gsc"].location == NSNotFound && [dict[@"Package"] rangeOfString:@"cy+"].location == NSNotFound) {
            AUPMPackage *package = [[AUPMPackage alloc] initWithPackageInformation:dict];
            [packageListForRepo addObject:package];
        }

    }

    NSSortDescriptor *sortByPackageName = [NSSortDescriptor sortDescriptorWithKey:@"packageName" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortByPackageName];

    return (NSArray*)[packageListForRepo sortedArrayUsingDescriptors:sortDescriptors];
}

@end
