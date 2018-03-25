@class AUPMRepo;

@interface AUPMRepoManager : NSObject
- (NSArray *)managedRepoList;
- (NSArray *)packageListForRepo:(AUPMRepo *)repo;
- (NSArray *)cleanUpDuplicatePackages:(NSArray *)packageList;
@end
