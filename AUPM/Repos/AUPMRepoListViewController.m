#import "AUPMRepoListViewController.h"
#import "../AUPMDatabaseManager.h"
#import "../Packages/AUPMConsoleViewController.h"
#import "AUPMRepo.h"
#import "AUPMRepoPackageListViewController.h"

@implementation AUPMRepoListViewController {
	NSMutableArray *_objects;
}

- (void)loadView {
	[super loadView];

	AUPMDatabaseManager *databaseManager = [[AUPMDatabaseManager alloc] initWithDatabaseFilename:@"aupmpackagedb.sql"];
	_objects = [[databaseManager cachedListOfRepositories] mutableCopy];

	UIBarButtonItem *refreshItem = [[UIBarButtonItem alloc] initWithTitle:@"Refresh" style:UIBarButtonItemStyleDone target:self action:@selector(refreshPackages)];
	self.navigationItem.rightBarButtonItem = refreshItem;

	self.title = @"Repos";
}

- (void)refreshPackages {
	AUPMConsoleViewController *console = [[AUPMConsoleViewController alloc] initWithRefresh:true];
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:console];
    [self presentViewController:navController animated:true completion:nil];
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
	AUPMRepoPackageListViewController *packageListVC = [[AUPMRepoPackageListViewController alloc] initWithRepo:repo];
    [self.navigationController pushViewController:packageListVC animated:YES];
}

@end
