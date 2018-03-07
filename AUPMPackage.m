@implementation AUPMPackage

- (id)initWthPackageIdentifier:(NSString *)identifier {
    NSArray *arguments = [[NSArray alloc] initWithObjects: @"dpkg", @"-s", identifier, nil];
	[self executeCommandWithLaunchPath:@"/Applications/AUPM.app/seadoo" arguments:arguments];
}

@end
