@interface AUPMRepo : NSObject {
    NSData *icon;
    NSString *repoName;
    NSString *repoURL;
    NSString *description;
}
- (id)initWithRepoInformation:(NSDictionary *)information;
- (void)setIcon:(NSData *)icon;
- (void)setRepoName:(NSString *)name;
- (void)setRepoURL:(NSString *)url;
- (void)setDescription:(NSString *)description;
- (NSData *)icon;
- (NSString *)repoName;
- (NSString *)repoURL;
- (NSString *)description;
@end
