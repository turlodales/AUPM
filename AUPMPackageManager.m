#import "AUPMPackageManager.h"

@implementation AUPMPackageManager

//Parse installed package list from dpkg and create an AUPMPackage for each one and return an array
- (NSArray *)installedPackageList {
    NSString *dbPath = @"/var/lib/dpkg/status";
    NSError *error;
    NSString *dbContents = [NSString stringWithContentsOfFile:dbPath encoding:NSUTF8StringEncoding error:&error];
    NSArray *packageInfoArray = [dbContents componentsSeparatedByString:@"\n\n"];
    NSMutableArray *installedPackageList = [[NSMutableArray alloc] init];

    for (NSString *package in packageInfoArray) {
        NSString *trimmedString = [package stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSArray *keyValuePairs = [trimmedString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

        NSMutableDictionary *dict  = [NSMutableDictionary dictionary];

        for (NSString *keyValuePair in keyValuePairs) {
            NSString *trimmedPair = [keyValuePair stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

            NSArray *keyValues = [trimmedPair componentsSeparatedByString:@":"];

            dict[[keyValues.firstObject stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]] = [keyValues.lastObject stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        }

        AUPMPackage *package = [[AUPMPackage alloc] initWithPackageInformation:dict];
        [installedPackageList addObject:package];
    }

    return (NSArray*)installedPackageList;
}

@end
