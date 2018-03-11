#import <sqlite3.h>
#import <pthread.h>
#import "NSTask.h"
#import "Repos/AUPMRepoManager.h"
#import "Packages/AUPMPackage.h"
#import "AUPMAppDelegate.h"

@interface AUPMDatabaseManager : NSObject
@property (nonatomic, strong) NSMutableArray *arrColumnNames;
@property (nonatomic) int affectedRows;
@property (nonatomic) long long lastInsertedRowID;

- (id)initWithDatabaseFilename:(NSString *)filename;
- (void)firstLoadPopulation:(void (^)(BOOL success))completion;
- (NSArray *)cachedListOfRepositories;
- (NSArray *)cachedPackageListForRepo:(AUPMRepo *)repo;
@end
