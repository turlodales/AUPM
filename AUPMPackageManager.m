#import "AUPMPackageManager.h"

@implementation AUPMPackageManager

//Parse installed package list from dpkg and create a Package for each one and return an array
- (NSMutableArray *)installedPackageList {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/Applications/AUPM.app/seadoo"];
    NSArray *arguments = [[NSArray alloc] initWithObjects: @"dpkg", @"--get-selections", nil];
    [task setArguments:arguments];

    NSPipe *out = [NSPipe pipe];
    [task setStandardOutput:out];

    [task launch];
    [task waitUntilExit];

    NSData *data = [[out fileHandleForReading] readDataToEndOfFile];
    NSString *ouputString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    NSArray *split = [ouputString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    split = [split filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];
    NSString *res = [split componentsJoinedByString:@" "];
    NSArray *array = [res componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    array = [array filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != ''"]];

    NSMutableArray *fixedArray = [array mutableCopy];
    [fixedArray removeObject:@"install"];
    [fixedArray removeObject:@"deinstall"]; //This still includes the "deinstall"'d packages in the array, need to fix this later

    NSMutableArray *packageArray = [[NSMutableArray alloc] init];
    for (NSString *packageID in fixedArray) {
        AUPMPackage *package = [[AUPMPackage alloc] initWthPackageIdentifier:packageID];
        [packageArray addObject:package];
    }

    HBLogInfo(@"Package Array: %@", packageArray);

    return packageArray;
}

@end
