#import "AUPMPackage.h"

@implementation AUPMPackage

- (id)initWithPackageInformation:(NSDictionary *)information {
    [self setPackageName:information[@"Name"]];
    [self setPackageIdentifier:information[@"Package"]];
    [self setPackageVersion:information[@"Version"]];
    [self setSection:information[@"Section"]];
    [self setDescription:information[@"Description"]];
    [self setDepictionURL:[NSURL URLWithString:[NSString stringWithFormat:@"http:%@", information[@"Depiction"]]]];

    return self;
}

- (BOOL)isInstalled {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/Applications/AUPM.app/supersling"];
    NSArray *arguments = [[NSArray alloc] initWithObjects: @"dpkg", @"-l", nil];
    [task setArguments:arguments];

    NSPipe *out = [NSPipe pipe];
    [task setStandardOutput:out];

    [task launch];
    [task waitUntilExit];

    NSData *data = [[out fileHandleForReading] readDataToEndOfFile];
    NSString *outputString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    if ([outputString rangeOfString:packageID].location != NSNotFound) {
        return true;
    }
    return false;
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

- (void)setDepictionURL:(NSURL *)url {
    if (url != NULL) {
        depictionURL = url;
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

- (NSURL *)depictionURL {
    return depictionURL;
}

@end
