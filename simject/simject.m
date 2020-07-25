#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <os/log.h>

#define dylibDir DYLIB_DIR

static NSArray *blackListForFLEX;

NSArray *simjectGenerateDylibList() {
	NSString *processName = [[NSProcessInfo processInfo] processName];
	// launchctl, you are a special case
	if ([processName isEqualToString:@"launchctl"]) {
		return nil;
	}
	// Create an array containing all the filenames in dylibDir (/opt/simject)
	NSError *e = nil;
	NSArray *dylibDirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dylibDir error:&e];
	if (e) {
		return nil;
	}
	// Read current bundle identifier
	NSString *bundleIdentifier = NSBundle.mainBundle.bundleIdentifier;
	// We're only interested in the plist files
	NSArray *plists = [dylibDirContents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF ENDSWITH %@", @"plist"]];
	// Create an empty mutable array that will contain a list of dylib paths to be injected into the target process
	NSMutableArray *dylibsToInject = [NSMutableArray array];
	// Loop through the list of plists
	for (NSString *plist in plists) {
		// Don't inject simject itself
		if ([plist isEqualToString:@"simject.plist"]) {
			continue;
		}
		// Check if the current dylib is FLEXible and if the current process is in the blacklist
		if (bundleIdentifier && [[plist uppercaseString] rangeOfString:@"FLEX" options:NSLiteralSearch].location != NSNotFound && [blackListForFLEX containsObject:bundleIdentifier]) {
			continue;
		}
		// We'll want to deal with absolute paths, so append the filename to dylibDir
		NSString *plistPath = [dylibDir stringByAppendingPathComponent:plist];
		NSDictionary *filter = [NSDictionary dictionaryWithContentsOfFile:plistPath];
		// This boolean indicates whether or not the dylib has already been injected
		BOOL isInjected = NO;
		// If supported iOS versions are specified within the plist, we check those first
		NSArray *supportedVersions = filter[@"CoreFoundationVersion"];
		if (supportedVersions) {
			if (supportedVersions.count != 1 && supportedVersions.count != 2) {
				continue; // Supported versions are in the wrong format, we should skip
			}
			if (supportedVersions.count == 1 && [supportedVersions[0] doubleValue] > kCFCoreFoundationVersionNumber) {
				continue; // Doesn't meet lower bound
			}
			if (supportedVersions.count == 2 && ([supportedVersions[0] doubleValue] > kCFCoreFoundationVersionNumber || [supportedVersions[1] doubleValue] <= kCFCoreFoundationVersionNumber)) {
				continue; // Outside bounds
			}
		}
		// Get the name of the dylib
		NSString *dylibName = [[plistPath stringByDeletingPathExtension] stringByAppendingString:@".dylib"];
		// Decide whether or not to load the dylib based on the Bundles values
		for (NSString *entry in filter[@"Filter"][@"Bundles"]) {
			// Check to see whether or not this bundle is actually loaded in this application or not
			if (!CFBundleGetBundleWithIdentifier((CFStringRef)entry)) {
				// If not, skip it
				continue;
			}
			[dylibsToInject addObject:dylibName];
			isInjected = YES;
			break;
		}
		if (!isInjected) {
			// Decide whether or not to load the dylib based on the Executables values
			for (NSString *process in filter[@"Filter"][@"Executables"]) {
				if ([process isEqualToString:processName]) {
					[dylibsToInject addObject:dylibName];
					isInjected = YES;
					break;
				}
			}
		}
		if (!isInjected) {
			// Decide whether or not to load the dylib based on the Classes values
			for (NSString *clazz in filter[@"Filter"][@"Classes"]) {
				// Also check if this class is loaded in this application or not
				if (!NSClassFromString(clazz)) {
					// This class couldn't be loaded, skip
					continue;
				}
				// It's fine to add this dylib at this point
				[dylibsToInject addObject:dylibName];
				isInjected = YES;
				break;
			}
		}
	}
	return dylibsToInject;
}

static __attribute__((constructor)) void SimjectInit (int argc, char **argv, char **envp) {
	// Since many iOS tweak developers use FLEXible (or some variant of that tweak) to inspect the iOS Simulator...
	// There are some processes that can crash when FLEXible is injected into them, significantly decreasing overall performance.
	// These processes do indeed load UIKit as a library, but they do not actually present a GUI so there is no point in injecting FLEXible into them.
	blackListForFLEX = @[@"com.apple.Search.framework", @"com.apple.accessibility.AccessibilityUIServer", @"com.apple.backboardd"];
	// Inject any dylib meant to be run for this application
	for (NSString *dylib in simjectGenerateDylibList()) {
		BOOL success = dlopen([dylib UTF8String], RTLD_LAZY | RTLD_GLOBAL) != NULL;
		os_log_info(OS_LOG_DEFAULT, "Injecting %s into %s: %d.", [dylib UTF8String], [NSBundle.mainBundle.bundleIdentifier UTF8String], success);
		if (!success) os_log_error(OS_LOG_DEFAULT, "Couldn't inject %s into %s:\n%s.", [dylib UTF8String], [NSBundle.mainBundle.bundleIdentifier UTF8String], dlerror());
	}
}
