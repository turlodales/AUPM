@class AUPMRepo;

@interface AUPMRepoManager : NSObject
- (NSArray *)managedRepoList;
- (NSArray *)packageListForRepo:(AUPMRepo *)repo;
- (NSDictionary *)packagesChangedInRepo:(AUPMRepo *)repo;
- (NSArray *)cleanUpDuplicatePackages:(NSArray *)packageList;
@end
