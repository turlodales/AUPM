#import "NSTask.h"

@interface AUPMPackage : NSObject {
    NSString *packageName;
    NSString *packageID;
    NSString *version;
}
- (id)initWthPackageIdentifier:(NSString *)identifier;
+ (NSString *)packageNameFromIdentifier:(NSString *)identifier;
- (NSDictionary *)parseDpkgInformation:(NSString *)information;
- (void)setPackageName:(NSString *)name;
- (void)setPackageIdentifier:(NSString *)identifier;
- (void)setPackageVersion:(NSString *)version;
- (NSString *)packageName;
- (NSString *)packageIdentifier;
- (NSString *)version;
@end
