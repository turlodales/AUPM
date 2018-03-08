#import "NSTask.h"

@interface AUPMPackage : NSObject {
    NSString *packageName;
    NSString *packageID;
    NSString *version;
}
- (id)initWithPackageInformation:(NSDictionary *)information;
- (void)setPackageName:(NSString *)name;
- (void)setPackageIdentifier:(NSString *)identifier;
- (void)setPackageVersion:(NSString *)version;
- (NSString *)packageName;
- (NSString *)packageIdentifier;
- (NSString *)version;
@end
