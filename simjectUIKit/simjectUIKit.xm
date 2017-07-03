#import "../simjectCore.h"
#import <dlfcn.h>

NSArray *simjectGenerateDylibListForUIKit() {
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
        // Don't inject simject or simjectUIKit
        if ([plist isEqualToString:@"simject.plist"] || [plist isEqualToString:@"simjectUIKit.plist"]) {
            continue;
        }
        // We want to deal with absolute paths, so append the filename to dylibDir
        NSString *plistPath = [dylibDir stringByAppendingPathComponent:plist];
        NSDictionary *filter = [NSDictionary dictionaryWithContentsOfFile:plistPath];
        for (NSString *bundle in filter[@"Filter"][@"Bundles"]) {
            // If supported iOS versions are specified, we check it first
            NSArray *supportedVersions = filter[@"CoreFoundationVersion"];
            if (supportedVersions && (supportedVersions.count == 1 || supportedVersions.count == 2)) {
                if (supportedVersions.count == 1 && [supportedVersions[0] doubleValue] > kCFCoreFoundationVersionNumber) {
                    continue; // doesn't meet lower bound
                }
                if (supportedVersions.count == 2) {
                    if ([supportedVersions[0] doubleValue] > kCFCoreFoundationVersionNumber || [supportedVersions[1] doubleValue] < kCFCoreFoundationVersionNumber) {
                        continue; // outside bounds
                    }
                }
            }
            // Now check if this bundle is loaded in this application or not
            if (!CFBundleGetBundleWithIdentifier((CFStringRef)bundle)) {
                // Skip because this application doesn't load it
                continue;
            }
            // Finally, this dylib can be loaded in this application
            [dylibsToInject addObject:[[plistPath stringByDeletingPathExtension] stringByAppendingString:@".dylib"]];
        }

        for (NSString *clazz in filter[@"Filter"][@"Classes"]) {
            // Also check if this class is loaded in this application or not
            if (!NSClassFromString(clazz)) {
                // This class couldn't be loaded, skip
                continue;
            }
            // It's ok to add this dylib at this point
            [dylibsToInject addObject:[[plistPath stringByDeletingPathExtension] stringByAppendingString:@".dylib"]];
        }
    }
    return dylibsToInject;
}

%ctor {
    // Inject any dylibs meant to be run for this application
    for (NSString *dylib in simjectGenerateDylibListForUIKit()) {
        dlopen([dylib UTF8String], RTLD_LAZY | RTLD_GLOBAL);
    }
}
