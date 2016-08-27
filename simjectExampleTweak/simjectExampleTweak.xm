#import <UIKit/UIKit.h>

%hook SpringBoard
-(void) applicationDidFinishLaunching:(id)arg {
	%orig(arg);
	UIAlertView *lookWhatWorks = [[UIAlertView alloc] initWithTitle:@"simject Example Tweak"
		message:@"It works! (ﾉ´ヮ´)ﾉ*:･ﾟ✧"
		delegate:self
		cancelButtonTitle:@"OK"
		otherButtonTitles:nil];
	[lookWhatWorks show];
}
%end
