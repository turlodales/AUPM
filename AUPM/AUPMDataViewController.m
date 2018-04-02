#import "AUPMAppDelegate.h"
#import "AUPMDataViewController.h"
#import "AUPMDatabaseManager.h"
#import "Repos/AUPMRepoListViewController.h"
#import "Packages/AUPMPackageListViewController.h"

@implementation AUPMDataViewController

- (void)loadView {
    [super loadView];

    [self.view setBackgroundColor:[UIColor whiteColor]];

    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.view addSubview:activityIndicator];
    [activityIndicator startAnimating];
    activityIndicator.center = self.view.center;

    UILabel *warningLabel = [[UILabel alloc] init];
    warningLabel.text = @"This may take an absurdly long time...";
    [warningLabel sizeToFit];
    warningLabel.center = CGPointMake(self.view.center.x, self.view.center.y + 30);
    [self.view addSubview:warningLabel];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    AUPMDatabaseManager *databaseManager = [(AUPMAppDelegate*) [[UIApplication sharedApplication] delegate] databaseManager];
    if ([databaseManager open]) {
        [databaseManager firstLoadPopulation:^(BOOL success) {
            [databaseManager close];
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"firstSetupComplete"];
            [[NSUserDefaults standardUserDefaults] synchronize];

            UITabBarController *tabController = [[UITabBarController alloc] init];

            UINavigationController *reposNavController = [[UINavigationController alloc] initWithRootViewController:[[AUPMRepoListViewController alloc] init]];
    		UITabBarItem *repoIcon = [[UITabBarItem alloc] initWithTitle:@"Sources" image:[UIImage imageNamed:@"Repo.png"] tag:0];
    		[repoIcon setFinishedSelectedImage:[UIImage imageNamed:@"Repo.png"] withFinishedUnselectedImage:[UIImage imageNamed:@"Repo.png"]];
    		[reposNavController setTabBarItem:repoIcon];

    		UINavigationController *packagesNavController = [[UINavigationController alloc] initWithRootViewController:[[AUPMPackageListViewController alloc] init]];
    		UITabBarItem *packageIcon = [[UITabBarItem alloc] initWithTitle:@"Packages" image:[UIImage imageNamed:@"Packages.png"] tag:0];
    		[packageIcon setFinishedSelectedImage:[UIImage imageNamed:@"Packages.png"] withFinishedUnselectedImage:[UIImage imageNamed:@"Packages.png"]];
    		[packagesNavController setTabBarItem:packageIcon];

    		tabController.viewControllers = [NSArray arrayWithObjects:reposNavController, packagesNavController,nil];
    		[[UIApplication sharedApplication] keyWindow].rootViewController = tabController;
        }];    
    }
}

@end
