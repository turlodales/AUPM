#import "AUPMRepoListViewController.h"
#import "../AUPMConsoleViewController.h"
#import "AUPMRepo.h"
#import "AUPMRepoManager.h"
#import "../AUPMDataViewController.h"
#import "../Packages/AUPMPackageListViewController.h"

@implementation AUPMRepoListViewController {
	NSMutableArray *_objects;
}

- (void)loadView {
	[super loadView];

	AUPMRepoManager *repoManager = [[AUPMRepoManager alloc] init];
	_objects = [[repoManager managedRepoList] mutableCopy];

	UIBarButtonItem *refreshItem = [[UIBarButtonItem alloc] initWithTitle:@"Refresh" style:UIBarButtonItemStyleDone target:self action:@selector(refreshPackages)];
	self.navigationItem.rightBarButtonItem = refreshItem;

	UIBarButtonItem *addItem = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStyleDone target:self action:@selector(showAddRepoAlert)];
	self.navigationItem.leftBarButtonItem = addItem;

	self.title = @"Sources";
}

- (void)refreshPackages {
	AUPMDataViewController *dataLoadViewController = [[AUPMDataViewController alloc] init];

	[[UIApplication sharedApplication] keyWindow].rootViewController = dataLoadViewController;
}

- (void)showAddRepoAlert {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Enter URL"
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Add"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action) {
                                                          UITextField *textField = alertController.textFields[0];
                                                          [self addSourceWithURL:textField.text];
                                                      }]];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = @"http://";
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
        textField.keyboardType = UIKeyboardTypeURL;
        textField.returnKeyType = UIReturnKeyNext;
    }];
    [self presentViewController:alertController animated:true completion:nil];
}

- (void)addSourceWithURL:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        HBLogError(@"invalid URL: %@", urlString);
		return;
    }
	HBLogInfo(@"Adding repo: %@", urlString);

	AUPMRepoManager *repoManager = [[AUPMRepoManager alloc] init];
	[repoManager addSource:url];
	[self refreshPackages];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return _objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *identifier = @"RepoTableViewCell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
	AUPMRepo *repo = _objects[indexPath.row];

	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
	}

    cell.textLabel.text = [repo repoName];
    cell.detailTextLabel.text = [repo repoURL];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.imageView.image = [UIImage imageWithData:[repo icon]];
	return cell;
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	AUPMRepo *repo = _objects[indexPath.row];
	AUPMPackageListViewController *packageListVC = [[AUPMPackageListViewController alloc] initWithRepo:repo];
    [self.navigationController pushViewController:packageListVC animated:YES];
}

@end
