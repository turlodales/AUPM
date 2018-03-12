#import <WebKit/WebKit.h>

@interface AUPMPackageViewController : UIViewController <WKNavigationDelegate>
- (id)initWithPackage:(AUPMPackage *)package;
@end
