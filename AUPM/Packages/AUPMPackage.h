@interface AUPMPackage : NSObject {
    NSString *packageName;
    NSString *packageID;
    NSString *version;
    NSString *section;
    NSString *description;
}
- (id)initWithPackageInformation:(NSDictionary *)information;
- (void)setPackageName:(NSString *)name;
- (void)setPackageIdentifier:(NSString *)identifier;
- (void)setPackageVersion:(NSString *)version;
- (void)setSection:(NSString *)section;
- (void)setDescription:(NSString *)description;
- (NSString *)packageName;
- (NSString *)packageIdentifier;
- (NSString *)version;
- (NSString *)section;
- (NSString *)description;
@end
