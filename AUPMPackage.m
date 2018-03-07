#import "AUPMPackage.h"

@implementation AUPMPackage

- (id)initWthPackageIdentifier:(NSString *)identifier {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/Applications/AUPM.app/seadoo"];
    NSArray *arguments = [[NSArray alloc] initWithObjects: @"dpkg", @"-s", identifier, nil];
    [task setArguments:arguments];

    NSPipe *out = [NSPipe pipe];
    [task setStandardOutput:out];

    [task launch];
    [task waitUntilExit];

    NSData *data = [[out fileHandleForReading] readDataToEndOfFile];
    NSString *outputString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    NSDictionary *packageInformation = [self parseDpkgInformation:outputString];

    packageName = packageInformation[@"Name"];
    packageID = packageInformation[@"Package"];
    version = packageInformation[@"Version"];

    return self;
}

- (NSDictionary *)parseDpkgInformation:(NSString *)information {
    NSString *trimmedString = [information stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSArray *keyValuePairs = [trimmedString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

    NSMutableDictionary *dict  = [NSMutableDictionary dictionary];

    for (NSString *keyValuePair in keyValuePairs) {
        NSString *trimmedPair = [keyValuePair stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

        NSArray *keyValues = [trimmedPair componentsSeparatedByString:@":"];

        dict[[keyValues.firstObject stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]] = [keyValues.lastObject stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }

    return dict;
}

- (void)setPackageName:(NSString *)name {
    packageName = name;
}
- (void)setPackageIdentifier:(NSString *)identifier {
    packageID = identifier;
}
- (void)setPackageVersion:(NSString *)vers {
    version = vers;
}

- (NSString *)packageName {
    return packageName;
}

- (NSString *)packageIdentifier {
    return packageID;
}

- (NSString *)version {
    return version;
}

@end
