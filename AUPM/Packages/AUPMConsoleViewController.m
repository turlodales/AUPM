#import "AUPMConsoleViewController.h"

@implementation AUPMConsoleViewController {
    NSTask *_task;
    UITextView *_consoleOutputView;
}

- (id)initWithTask:(NSTask *)task {
    _task = task;

    return self;
}

- (void)loadView {
    [super loadView];
    _consoleOutputView = [[UITextView alloc] initWithFrame:self.view.frame];
    _consoleOutputView.editable = false;
    [self.view addSubview:_consoleOutputView];

    NSPipe *pipe = [[NSPipe alloc] init];
    [_task setStandardOutput:pipe];

    NSFileHandle *output = [pipe fileHandleForReading];
    [output waitForDataInBackgroundAndNotify];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedData:) name:NSFileHandleDataAvailableNotification object:output];

    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(dismissConsole)];
    UINavigationItem *navItem = self.navigationItem;
    _task.terminationHandler = ^(NSTask *task){
        dispatch_async(dispatch_get_main_queue(), ^{
            navItem.rightBarButtonItem = doneButton;
        });
    };

    [_task launch];
}

- (void)dismissConsole {
    [self dismissViewControllerAnimated:true completion:nil];
}

- (void)receivedData:(NSNotification *)notif {
    NSFileHandle *fh = [notif object];
    NSData *data = [fh availableData];
    HBLogInfo(@"Received Data: %@", data);

    if (data.length > 0) {
        [fh waitForDataInBackgroundAndNotify];
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        HBLogInfo(@"Data String: %@", str);
        [_consoleOutputView.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:str]];

        if (_consoleOutputView.text.length > 0 ) {
            NSRange bottom = NSMakeRange(_consoleOutputView.text.length -1, 1);
            [_consoleOutputView scrollRangeToVisible:bottom];
        }
    }
}

@end
