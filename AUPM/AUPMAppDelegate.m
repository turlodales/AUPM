#import "AUPMAppDelegate.h"
#import "AUPMDatabaseManager.h"

@implementation AUPMAppDelegate

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	self.window.backgroundColor = [UIColor whiteColor]; //Fixes a weird visual issue after pushing a vc

	BOOL firstLaunch = true;
	//![[NSUserDefaults standardUserDefaults] boolForKey:@"dbSetupComplete"]
	if (!firstLaunch) {
		UINavigationController *reposNavController = [[UINavigationController alloc] initWithRootViewController:[[AUPMRepoListViewController alloc] init]];
		UITabBarItem *repoIcon = [[UITabBarItem alloc] initWithTitle:@"Repo" image:[UIImage imageNamed:@"Repo.png"] tag:0];
		[repoIcon setFinishedSelectedImage:[UIImage imageNamed:@"Repo.png"] withFinishedUnselectedImage:[UIImage imageNamed:@"Repo.png"]];
		[reposNavController setTabBarItem:repoIcon];

		UINavigationController *packagesNavController = [[UINavigationController alloc] initWithRootViewController:[[AUPMPackageListViewController alloc] init]];
		UITabBarItem *packageIcon = [[UITabBarItem alloc] initWithTitle:@"Packages" image:[UIImage imageNamed:@"Packages.png"] tag:0];
		[packageIcon setFinishedSelectedImage:[UIImage imageNamed:@"Packages.png"] withFinishedUnselectedImage:[UIImage imageNamed:@"Packages.png"]];
		[packagesNavController setTabBarItem:packageIcon];

		self.tabBarController = [[UITabBarController alloc] init];
		self.tabBarController.viewControllers = [NSArray arrayWithObjects:reposNavController, packagesNavController,nil];
		self.window.rootViewController = self.tabBarController;
	}
	else {
		AUPMDataViewController *dataLoadViewController = [[AUPMDataViewController alloc] init];

		self.window.rootViewController = dataLoadViewController;
	}

	[self.window makeKeyAndVisible];
}

@end
