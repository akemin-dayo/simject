#import "simjectCore.h"

NSString *simjectGenerateDILEnvVar(NSArray *dylibArray) {
	// Create our NSString that will later become our DYLD_INSERT_LIBRARIES environment variable
	NSMutableString *dylibs = [NSMutableString string];
	// Loop through the array as long as the array exists and contains a non-zero amount of indices
	if (dylibArray && [dylibArray count] > 0) {
		for (NSString *name in dylibArray) {
			// Append each dylib path to our string, then append the : delimiter
			[dylibs appendString:[NSString stringWithFormat:@"%@:", name]];
		}
		// Delete the last, extraneous : delimiter that the above code will create
		[dylibs deleteCharactersInRange:NSMakeRange([dylibs length] - 1, 1)];
	}
	return dylibs;
}

NSArray *simjectGenerateDylibList(SBApplicationInfo *appInfo) {
	// Store the selected app's CFBundleID in an NSString just for easy access
	// If appInfo is nil, then set bundleIdentifier to com.apple.springboard
	// Why? Because that means this function's probably being called by respring_simulator, which is targeting SpringBoard
	NSString *bundleIdentifier = (appInfo) ? [appInfo bundleIdentifier] : @"com.apple.springboard";
	// Create an empty mutable array that will contain a list of dylib paths to be injected into the target process
	NSMutableArray *dylibsToInject = [NSMutableArray array];
	// Create an array containing all the filenames in dylibDir (/opt/simjectCore)
	NSArray *dylibDirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dylibDir error:nil];
	// Loop through the entirety of dylibDir
	for (NSString *plist in dylibDirContents) {
		// We'll want to deal with absolute paths, so append the filename to dylibDir
		plist = [dylibDir stringByAppendingString:[NSString stringWithFormat:@"/%@", plist]];
		// Now, we're only interested in the file if it's a plist
		if ([[plist pathExtension] compare:@"plist" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
			for (NSString *entry in [NSDictionary dictionaryWithContentsOfFile:plist][@"Filter"][@"Bundles"]) {
				// Now, check if the selected app's bundle ID matches anything in the plist
				// Also check if any of the bundle IDs in the plist start with com.apple.*
				if ([entry isEqualToString:bundleIdentifier] || [entry hasPrefix:@"com.apple."]) {
					// If either of those conditions are met, inject the dylib
					// Why inject com.apple.*? If a dylib is targeting that, it's likely a framework or (com.apple.UIKit, etc.)
					// An improvement can be made here by checking if the bundle ID is an installed system app or not...
					// Such a check could be possible by using the MobileInstallationLookup function from the MobileInstallationInstall private framework
					// I had considered doing that, but for the sake of releasing this in a timely manner, chose not to
					[dylibsToInject addObject:[[plist stringByDeletingPathExtension] stringByAppendingString:@".dylib"]];
				}
			}
		}
	}
	return dylibsToInject;
}

NSDictionary *simjectEnvironmentVariables(NSDictionary *origVars, SBApplicationInfo *appInfo) {
	// Create a mutable dictionary containing the original environment variables
	NSMutableDictionary *envVars = (origVars) ? [origVars mutableCopy] : [NSMutableDictionary dictionary];
	// Add/replace DYLD_INSERT_LIBRARIES with our own from simjectGenerateDILEnvVar()
	envVars[@"DYLD_INSERT_LIBRARIES"] = simjectGenerateDILEnvVar(simjectGenerateDylibList(appInfo));
	return envVars;
}
