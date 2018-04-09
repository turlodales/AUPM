#import "AUPMAppDelegate.h"
#import "AUPMDatabaseManager.h"
#import "Repos/AUPMRepoListViewController.h"
#import "Packages/AUPMPackageListViewController.h"
#import "AUPMDataViewController.h"

@implementation AUPMAppDelegate

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	self.window.backgroundColor = [UIColor whiteColor]; //Fixes a weird visual issue after pushing a vc


	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"firstSetupComplete"]) {
		AUPMDataViewController *dataLoadViewController = [[AUPMDataViewController alloc] initWithAction:1];

		self.window.rootViewController = dataLoadViewController;
	}
	else {
		AUPMDataViewController *dataLoadViewController = [[AUPMDataViewController alloc] init];

		self.window.rootViewController = dataLoadViewController;
	}

	[self.window makeKeyAndVisible];
}

@end
