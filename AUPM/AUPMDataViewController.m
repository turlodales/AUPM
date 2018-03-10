#import "AUPMDataViewController.h"

@implementation AUPMDataViewController

- (void)loadView {
    [super loadView];

    [self.view setBackgroundColor:[UIColor whiteColor]];

    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.view addSubview:activityIndicator];
    [activityIndicator startAnimating];
    activityIndicator.center = self.view.center;


}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    AUPMDatabaseManager *databaseManager = [[AUPMDatabaseManager alloc] initWithDatabaseFilename:@"aupmpackagedb.sql"];
    [databaseManager firstLoadPopulation];
}

@end
