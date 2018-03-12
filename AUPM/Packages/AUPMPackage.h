#import "../NSTask.h"

@interface AUPMPackage : NSObject {
    NSString *packageName;
    NSString *packageID;
    NSString *version;
    NSString *section;
    NSString *description;
    NSURL *depictionURL;
}
- (id)initWithPackageInformation:(NSDictionary *)information;
- (id)initWithPackageName:(NSString *)name packageID:(NSString *)identifier version:(NSString *)version section:(NSString *)section description:(NSString *)description depictionURL:(NSString *)url;
- (BOOL)isInstalled;
- (void)setPackageName:(NSString *)name;
- (void)setPackageIdentifier:(NSString *)identifier;
- (void)setPackageVersion:(NSString *)version;
- (void)setSection:(NSString *)section;
- (void)setDescription:(NSString *)description;
- (void)setDepictionURL:(NSURL *)url;
- (NSString *)packageName;
- (NSString *)packageIdentifier;
- (NSString *)version;
- (NSString *)section;
- (NSString *)description;
- (NSURL *)depictionURL;
@end
