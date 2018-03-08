#import "AUPMPackage.h"

@implementation AUPMPackage

- (id)initWithPackageInformation:(NSDictionary *)information {
    [self setPackageName:information[@"Name"]];
    [self setPackageIdentifier:information[@"Package"]];
    [self setPackageVersion:information[@"Version"]];

    return self;
}

- (void)setPackageName:(NSString *)name {
    if (name != NULL) {
        packageName = name;
    }
    else {
        packageName = @"";
    }
}
- (void)setPackageIdentifier:(NSString *)identifier {
    if (identifier != NULL) {
        packageID = identifier;
    }
    else {
        packageID = @"";
    }
}
- (void)setPackageVersion:(NSString *)vers {
    if (vers != NULL) {
        version = vers;
    }
    else {
        version = @"";
    }
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
