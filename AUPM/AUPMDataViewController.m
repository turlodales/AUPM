#import "AUPMDataViewController.h"

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

    AUPMDatabaseManager *databaseManager = [[AUPMDatabaseManager alloc] initWithDatabaseFilename:@"aupmpackagedb.sql"];
    [databaseManager firstLoadPopulation];
}

@end
