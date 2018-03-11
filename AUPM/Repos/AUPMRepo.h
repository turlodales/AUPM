@interface AUPMRepo : NSObject {
    NSData *icon;
    NSString *repoName;
    NSString *repoBaseFileName;
    NSString *description;
    NSString *repoURL;
    int repoIdentifier;
}
- (id)initWithRepoInformation:(NSDictionary *)information;
- (id) initWithRepoID:(int)id name:(NSString *)name baseFileName:(NSString *)baseFileName description:(NSString *)repoDescription url:(NSString *)url;
- (void)setIcon:(NSData *)icon;
- (void)setRepoName:(NSString *)name;
- (void)setRepoBaseFileName:(NSString *)url;
- (void)setDescription:(NSString *)description;
- (void)setRepoURL:(NSString *)url;
- (void)setRepoID:(int)identifier;
- (NSData *)icon;
- (NSString *)repoName;
- (NSString *)repoBaseFileName;
- (NSString *)description;
- (NSString *)repoURL;
- (int)repoIdentifier;
@end
