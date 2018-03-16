#import "AUPMConsoleViewController.h"
#import "../AUPMDatabaseManager.h"
#import "../NSTask.h"

@implementation AUPMConsoleViewController {
    NSTask *_task;
    BOOL _refresh;
    UITextView *_consoleOutputView;
}

- (id)initWithTask:(NSTask *)task {
    _task = task;

    return self;
}

- (id)initWithRefresh:(BOOL)refresh {
    _refresh = refresh;

    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/Applications/AUPM.app/supersling"];
    NSArray *arguments = [[NSArray alloc] initWithObjects: @"apt-get", @"update", nil];
    [task setArguments:arguments];

    _task = task;

    return self;
}

- (void)loadView {
    [super loadView];
    CGFloat height = [[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height;
	_consoleOutputView = [[UITextView alloc] initWithFrame:CGRectMake(0,0, self.view.frame.size.width, self.view.frame.size.height - height)];
    _consoleOutputView.editable = false;
    [self.view addSubview:_consoleOutputView];

    NSPipe *pipe = [[NSPipe alloc] init];
    [_task setStandardOutput:pipe];

    NSFileHandle *output = [pipe fileHandleForReading];
    [output waitForDataInBackgroundAndNotify];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedData:) name:NSFileHandleDataAvailableNotification object:output];

    if (_refresh) {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(dismissConsole)];
        UINavigationItem *navItem = self.navigationItem;

        // NSTask *cpTask = [[NSTask alloc] init];
        // [cpTask setLaunchPath:@"/Applications/AUPM.app/supersling"];
        // NSArray *cpArgs = [[NSArray alloc] initWithObjects: @"cp", @"-fR", @"/var/lib/apt/lists", @"/var/mobile/Library/Caches/com.xtm3x.aupm/", nil];
        // [cpTask setArguments:cpArgs];
        //
        // [cpTask launch];
        // [cpTask waitUntilExit];

        _task.terminationHandler = ^(NSTask *task){
            dispatch_async(dispatch_get_main_queue(), ^{
                HBLogInfo(@"Refreshing");
                AUPMDatabaseManager *databaseManager = [[AUPMDatabaseManager alloc] initWithDatabaseFilename:@"aupmpackagedb.sql"];
                [databaseManager updateDatabaseWithDifferences:^(BOOL success) {
                    HBLogInfo(@"Database refresh complete");
                    dispatch_async(dispatch_get_main_queue(), ^{
                        navItem.rightBarButtonItem = doneButton;
                    });
                }];
            });
        };
    }
    else {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(dismissConsole)];
        UINavigationItem *navItem = self.navigationItem;
        _task.terminationHandler = ^(NSTask *task){
            dispatch_async(dispatch_get_main_queue(), ^{
                navItem.rightBarButtonItem = doneButton;
            });
        };
    }

    [_task launch];
}

- (void)dismissConsole {
    [self dismissViewControllerAnimated:true completion:nil];
}

- (void)receivedData:(NSNotification *)notif {
    NSFileHandle *fh = [notif object];
    NSData *data = [fh availableData];

    if (data.length > 0) {
        [fh waitForDataInBackgroundAndNotify];
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [_consoleOutputView.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:str]];

        if (_consoleOutputView.text.length > 0 ) {
            NSRange bottom = NSMakeRange(_consoleOutputView.text.length -1, 1);
            [_consoleOutputView scrollRangeToVisible:bottom];
        }
    }
}

@end
