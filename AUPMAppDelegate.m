#import "AUPMAppDelegate.h"
#import "AUPMPackageListViewController.h"

@implementation AUPMAppDelegate

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	_packageManager = [[AUPMPackageManager alloc] init];
	_window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	_rootViewController = [[UINavigationController alloc] initWithRootViewController:[[AUPMPackageListViewController alloc] init]];
	_window.rootViewController = _rootViewController;
	[_window makeKeyAndVisible];
}

@end
