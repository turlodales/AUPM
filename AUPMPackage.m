#import "AUPMPackage.h"

@implementation AUPMPackage

- (id)initWithPackageInformation:(NSDictionary *)information {
    packageName = information[@"Name"];
    packageID = information[@"Package"];
    version = information[@"Version"];

    return self;
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
