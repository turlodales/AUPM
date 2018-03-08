#import "AUPMPackageListViewController.h"

@implementation AUPMPackageListViewController {
	NSMutableArray *_objects;
}

- (void)loadView {
	[super loadView];

	AUPMPackageManager *packageManager = [[AUPMPackageManager alloc] init];
	_objects = [packageManager installedPackageList];

	self.title = [NSString stringWithFormat:@"Packages: %lu", (unsigned long)[_objects count]];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return _objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *identifier = @"InstalledPackageTableViewCell";
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
