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
    [task release];

    NSData *data = [[out fileHandleForReading] readDataToEndOfFile];
    NSString *ouputString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];

    NSArray *split = [ouputString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    split = [split filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];
    NSString *res = [split componentsJoinedByString:@" "];
    NSArray *array = [res componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    array = [array filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != ''"]];

    NSMutableArray *packageArray = [array mutableCopy];
    for (int i = 0; i < packageArray.count; i++) {
        if ([packageArray[i] isEqual:@"deinstall"]) {
            [packageArray removeObjectAtIndex:i - 1];
            [packageArray removeObjectAtIndex:i];
        }
        else if ([packageArray[i] isEqual:@"install"]) {
            [packageArray removeObjectAtIndex:i];
        }
    }
    // for (int i = 0; i < packageArray.length; i++) {
    //     if (packageArray[i] == @"installed") {
    //         AUPMPackage *package = [[AUPMPackage] alloc] initWithPackageIdentifier:packageArray[i]];
    //         [installedPackageList addObject:package];
    //     }
    // }
    HBLogInfo(@"Package Array: %@", packageArray);

    return packageArray;
}

@end
