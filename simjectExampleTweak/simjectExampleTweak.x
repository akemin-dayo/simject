#import <SpringBoard/SpringBoard.h>

%hook SpringBoard
-(void) applicationDidFinishLaunching:(id)arg {
	%orig(arg);
	if (@available(iOS 8.0, *)) {
		UIAlertController *lookWhatWorks = [UIAlertController alertControllerWithTitle:@"simject Example Tweak"
			message:@"It works! (ﾉ´ヮ´)ﾉ*:･ﾟ✧"
			preferredStyle:UIAlertControllerStyleAlert];
		UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
		[lookWhatWorks addAction:ok];
		[self.keyWindow.rootViewController presentViewController:lookWhatWorks animated:YES completion:nil];
	} else {
		UIAlertView *lookWhatWorks = [[UIAlertView alloc] initWithTitle:@"simject Example Tweak"
			message:@"It works! (ﾉ´ヮ´)ﾉ*:･ﾟ✧"
			delegate:self
			cancelButtonTitle:@"OK"
			otherButtonTitles:nil];
		[lookWhatWorks show];
	}
}
%end
