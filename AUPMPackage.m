#import "AUPMPackage.h"

@implementation AUPMPackage

- (id)initWithPackageInformation:(NSDictionary *)information {
    [self setPackageName:information[@"Name"]];
    [self setPackageIdentifier:information[@"Package"]];
    [self setPackageVersion:information[@"Version"]];
    [self setSection:information[@"Section"]];
    [self setDescription:information[@"Description"]];

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

- (void)setSection:(NSString *)sect {
    if (sect != NULL) {
        section = sect;
    }
    else {
        section = @"";
    }
}

- (void)setDescription:(NSString *)desc {
    if (desc != NULL) {
        description = desc;
    }
    else {
        description = @"";
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

- (NSString *)section {
    return section;
}

- (NSString *)description {
    return description;
}

@end
