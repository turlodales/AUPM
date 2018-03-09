#import "AUPMRepoPackageListViewController.h"

@implementation AUPMRepoPackageListViewController {
	NSMutableArray *_objects;
	AUPMRepo *_repo;
}

- (id)initWithRepo:(AUPMRepo *)repo {
	_repo = repo;

	return self;
}

- (void)loadView {
	[super loadView];

	AUPMRepoManager *repoManager = [[AUPMRepoManager alloc] init];
	_objects = [[repoManager packageListForRepo:_repo] mutableCopy];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return _objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *identifier = @"RepoPackageCell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
	AUPMPackage *package = _objects[indexPath.row];

	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
	}

	UIImage *sectionImage = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/Applications/Cydia.app/Sections/%@", [package section]]];
	cell.imageView.image = sectionImage;
	cell.textLabel.text = [package packageName];
	cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ (%@)", [package packageIdentifier], [package version]];
	return cell;
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
