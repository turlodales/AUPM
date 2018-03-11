#import "../Packages/AUPMPackage.h"
#import "../Packages/AUPMPackageViewController.h"
#import "AUPMRepoManager.h"
#import "../AUPMDatabaseManager.h"

@interface AUPMRepoPackageListViewController : UITableViewController
- (id)initWithRepo:(AUPMRepo *)repo;
@end
