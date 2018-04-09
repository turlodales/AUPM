#import "AUPMAppDelegate.h"
#import "AUPMDataViewController.h"
#import "AUPMDatabaseManager.h"
#import "Repos/AUPMRepoListViewController.h"
#import "Packages/AUPMPackageListViewController.h"

@interface AUPMDataViewController () {
    BOOL _action;
}
@end

@implementation AUPMDataViewController

- (id)init {
    self = [super init];
    if (self) {
        _action = 0;
    }
    return self;
}

- (id)initWithAction:(int)action {
    self = [super init];
    if (self) {
        _action = action;
    }
    return self;
}

- (void)loadView {
    [super loadView];

    [self.view setBackgroundColor:[UIColor whiteColor]];

    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.view addSubview:activityIndicator];
    [activityIndicator startAnimating];
    activityIndicator.center = self.view.center;

    UILabel *warningLabel = [[UILabel alloc] init];
    warningLabel.text = @"Updating database...";
    [warningLabel sizeToFit];
    warningLabel.center = CGPointMake(self.view.center.x, self.view.center.y + 30);
    [self.view addSubview:warningLabel];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    AUPMDatabaseManager *databaseManager = [[AUPMDatabaseManager alloc] initWithDatabaseFilename:@"aupmpackagedb.sql"];
    if (_action == 0) {
        [databaseManager firstLoadPopulation:^(BOOL success) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"firstSetupComplete"];
            [[NSUserDefaults standardUserDefaults] synchronize];

            [self goAway];
        }];
    }
    else if (_action == 1) {
        [databaseManager updatePopulation:^(BOOL success) {
            [self goAway];
        }];
    }
    else {
        HBLogInfo(@"Invalid action...");
        [self goAway];
    }
}

- (void)goAway {
    if ([self presentingViewController]) {
        [self dismissViewControllerAnimated:true completion:nil];
    }
    else {
        UITabBarController *tabController = [[UITabBarController alloc] init];

        UINavigationController *reposNavController = [[UINavigationController alloc] initWithRootViewController:[[AUPMRepoListViewController alloc] init]];
        UITabBarItem *repoIcon = [[UITabBarItem alloc] initWithTitle:@"Sources" image:[UIImage imageNamed:@"Repo.png"] tag:0];
        [repoIcon setFinishedSelectedImage:[UIImage imageNamed:@"Repo.png"] withFinishedUnselectedImage:[UIImage imageNamed:@"Repo.png"]];
        [reposNavController setTabBarItem:repoIcon];

        UINavigationController *packagesNavController = [[UINavigationController alloc] initWithRootViewController:[[AUPMPackageListViewController alloc] init]];
        UITabBarItem *packageIcon = [[UITabBarItem alloc] initWithTitle:@"Packages" image:[UIImage imageNamed:@"Packages.png"] tag:1];
        [packageIcon setFinishedSelectedImage:[UIImage imageNamed:@"Packages.png"] withFinishedUnselectedImage:[UIImage imageNamed:@"Packages.png"]];
        [packagesNavController setTabBarItem:packageIcon];

        tabController.viewControllers = [NSArray arrayWithObjects:reposNavController, packagesNavController,nil];
        [[UIApplication sharedApplication] keyWindow].rootViewController = tabController;
    }
}

@end
