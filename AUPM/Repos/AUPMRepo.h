@interface AUPMRepo : NSObject {
    NSData *icon;
    NSString *repoName;
    NSString *repoBaseFileName;
    NSString *description;
    NSString *repoURL;
}
- (id)initWithRepoInformation:(NSDictionary *)information;
- (void)setIcon:(NSData *)icon;
- (void)setRepoName:(NSString *)name;
- (void)setRepoBaseFileName:(NSString *)url;
- (void)setDescription:(NSString *)description;
- (void)setRepoURL:(NSString *)url;
- (NSData *)icon;
- (NSString *)repoName;
- (NSString *)repoBaseFileName;
- (NSString *)description;
- (NSString *)repoURL;
@end
