#import "simjectCore.h"

NSString *simjectGenerateDylibList(SBApplicationInfo *appInfo, NSString *originalEnv) {
	// Store the selected app's CFBundleID in an NSString just for easy access
	// If appInfo is nil, then set bundleIdentifier to com.apple.springboard
	// Why? Because that means this function's probably being called by respring_simulator, which is targeting SpringBoard
	NSString *bundleIdentifier = (appInfo) ? [appInfo bundleIdentifier] : @"com.apple.springboard";
	// Create an array containing all the filenames in dylibDir (/opt/simject)
	NSError *e = nil;
	NSArray *dylibDirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dylibDir error:&e];
	if (e) {
		return nil;
	}
	// We're only interested in the plist files
	NSArray *plists = [dylibDirContents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF endswith %@", @"plist"]];
	// Create an empty mutable array that will contain a list of dylib paths to be injected into the target process
	NSMutableArray *dylibsToInject = [NSMutableArray array];
	// Loop through the list of plists
	for (NSString *plist in plists) {
		// We'll want to deal with absolute paths, so append the filename to dylibDir
		NSString *plistPath = [dylibDir stringByAppendingPathComponent:plist];
		NSDictionary *filter = [NSDictionary dictionaryWithContentsOfFile:plistPath];
		for (NSString *entry in filter[@"Filter"][@"Bundles"]) {
			// If supported iOS versions are specified, we check it first
			NSArray *supportedVersions = filter[@"CoreFoundationVersion"];
			if (supportedVersions && (supportedVersions.count == 1 || supportedVersions.count == 2)) {
				if (supportedVersions.count == 1 && [supportedVersions[0] floatValue] > kCFCoreFoundationVersionNumber) {
					continue; // doesn't meet lower bound
				}
				if ([supportedVersions[0] floatValue] > kCFCoreFoundationVersionNumber || [supportedVersions[1] floatValue] < kCFCoreFoundationVersionNumber) {
					continue; // outside bounds
				}
			}
			// Now, check if the selected app's bundle ID matches anything in the plist
			// Also check if any of the bundle IDs in the plist start with com.apple.*
			if ([entry isEqualToString:bundleIdentifier] || [entry hasPrefix:@"com.apple."]) {
				// If either of those conditions are met, inject the dylib
				// Why inject com.apple.*? If a dylib is targeting that, it's likely a framework (com.apple.UIKit, etc.)
				// An improvement can be made here by checking if the bundle ID is an installed system app or not... (-[SBApplicationInfo isSystemApplication])
				// Such a check could be possible by using the MobileInstallationLookup function from the MobileInstallationInstall private framework
				// I had considered doing that, but for the sake of releasing this in a timely manner, chose not to
				[dylibsToInject addObject:[[plistPath stringByDeletingPathExtension] stringByAppendingString:@".dylib"]];
			}
		}
	}
	NSString *ourDylibs = [dylibsToInject componentsJoinedByString:@":"];
	if (originalEnv && originalEnv.length > 0) {
		ourDylibs = [NSString stringWithFormat:@"%@:%@", originalEnv, ourDylibs];
	}
	return ourDylibs;
}

NSDictionary *simjectEnvironmentVariables(NSDictionary *origVars, SBApplicationInfo *appInfo) {
	// Create a mutable dictionary containing the original environment variables
	NSMutableDictionary *envVars = (origVars) ? [origVars mutableCopy] : [NSMutableDictionary dictionary];
	// Add/replace DYLD_INSERT_LIBRARIES with our own
	envVars[@"DYLD_INSERT_LIBRARIES"] = simjectGenerateDylibList(appInfo, envVars[@"DYLD_INSERT_LIBRARIES"]);
	return envVars;
}