#import "AUPMPackageViewController.h"
#import <objc/runtime.h>

@implementation AUPMPackageViewController {
	BOOL _isFinishedLoading;
	WKWebView *_webView;
	AUPMPackage *_package;
	UIProgressView *_progressBar;
	NSTimer *_progressTimer;
}

- (id)initWithPackage:(AUPMPackage *)package {
	_package = package;

	return self;
}

- (void)loadView {
	[super loadView];

	[self.view setBackgroundColor:[UIColor whiteColor]]; //Fixes a weird animation issue when pushing
	_webView = [[WKWebView alloc] initWithFrame:self.view.frame];
    [_webView setNavigationDelegate:self];
	HBLogInfo(@"Depiction URL: %@", [_package depictionURL]);
	HBLogInfo(@"Web View: %@", _webView);
    [_webView loadRequest:[[NSURLRequest alloc] initWithURL:[_package depictionURL]]];
	_webView.allowsBackForwardNavigationGestures = true;
    _progressBar = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 9)];
    [_webView addSubview:_progressBar];
	[self.view addSubview:_webView];

	self.title = [_package packageName];
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    [_progressTimer invalidate];
    _progressBar.hidden = false;
    _progressBar.alpha = 1.0;
    _progressBar.progress = 0;
    _progressBar.trackTintColor = [UIColor clearColor];
    _isFinishedLoading = false;
    _progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.01667 target:self selector:@selector(refreshProgress) userInfo:nil repeats:YES];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    _isFinishedLoading = TRUE;
}

-(void)refreshProgress {
    if (_isFinishedLoading) {
        if (_progressBar.progress >= 1) {
            [UIView animateWithDuration:0.3 delay:0.3 options:0 animations:^{
                _progressBar.alpha = 0.0;
            } completion:^(BOOL finished) {
                [_progressTimer invalidate];
                _progressTimer = nil;
            }];
        }
        else {
            _progressBar.progress += 0.1;
        }
    }
    else {
        if (_progressBar.progress >= _webView.estimatedProgress) {
            _progressBar.progress = _webView.estimatedProgress;
        }
        else {
            _progressBar.progress += 0.005;
        }
    }
}

@end
