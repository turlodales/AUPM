#import "AUPMRepo.h"
#import "../Packages/AUPMPackage.h"

@interface AUPMRepoManager : NSObject
- (NSArray *)managedRepoList;
- (NSArray *)packageListForRepo:(AUPMRepo *)repo;
@end
