#import "../simject.h"
#import <dlfcn.h>

// Due to the fact that many developers use FLEX (or its variants) to inspect iOS simulator:
// There exist processes that could crash when FLEX is injected and that could decrease performance of simulator alot
// Those processes load UIKit, but they are not actually GUI apps so there's no point loading this kind of tweak
static NSArray *blackListForFLEX = @[@"com.apple.Search.framework", @"com.apple.accessibility.AccessibilityUIServer"];

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
        // Check if a dylib is FLEX and the current process is in blacklist
        if ([[plist uppercaseString] rangeOfString:@"FLEX" options:NSLiteralSearch].location != NSNotFound && [blackListForFLEX containsObject:bundleIdentifier]) {
            continue;
        }
        // We'll want to deal with absolute paths, so append the filename to dylibDir
        NSString *plistPath = [dylibDir stringByAppendingPathComponent:plist];
        NSDictionary *filter = [NSDictionary dictionaryWithContentsOfFile:plistPath];
        // A boolean that indicates if the dylib is already injected
        BOOL isInjected = NO;
        // If supported iOS versions are specified, we check it first
        NSArray *supportedVersions = filter[@"CoreFoundationVersion"];
        if (supportedVersions) {
            if (supportedVersions.count != 1 && supportedVersions.count != 2)
                continue; // Supported versions are in wrong format, we should skip
            if (supportedVersions.count == 1 && [supportedVersions[0] doubleValue] > kCFCoreFoundationVersionNumber) {
                continue; // Doesn't meet lower bound
            }
            if (supportedVersions.count == 2 && ([supportedVersions[0] doubleValue] > kCFCoreFoundationVersionNumber || [supportedVersions[1] doubleValue] < kCFCoreFoundationVersionNumber)) {
                continue; // Outside bounds
            }
        }
        // Decide whether to load the dylib from bundles
        for (NSString *entry in filter[@"Filter"][@"Bundles"]) {
            // Now check if this bundle is loaded in this application or not
            if (!CFBundleGetBundleWithIdentifier((CFStringRef)entry)) {
                // Skip because this application doesn't load it
                continue;
            }
            [dylibsToInject addObject:[[plistPath stringByDeletingPathExtension] stringByAppendingString:@".dylib"]];
            isInjected = YES;
            break;
        }
        if (!isInjected) {
            // Decide whether to load the dylib from executables
            for (NSString *process in filter[@"Filter"][@"Executables"]) {
                if ([process isEqualToString:processName]) {
                    [dylibsToInject addObject:[[plistPath stringByDeletingPathExtension] stringByAppendingString:@".dylib"]];
                    isInjected = YES;
                    break;
                }
            }
        }
        if (!isInjected) {
            // Decide whether to load the dylib from classes
            for (NSString *clazz in filter[@"Filter"][@"Classes"]) {
                // Also check if this class is loaded in this application or not
                if (!NSClassFromString(clazz)) {
                    // This class couldn't be loaded, skip
                    continue;
                }
                // It's ok to add this dylib at this point
                [dylibsToInject addObject:[[plistPath stringByDeletingPathExtension] stringByAppendingString:@".dylib"]];
                isInjected = YES;
                break;
            }
        }
    }
    return dylibsToInject;
}

%ctor {
    // Inject any dylib meant to be run for this application
    for (NSString *dylib in simjectGenerateDylibList()) {
        HBLogDebug(@"Injecting %@ into %@", dylib, NSBundle.mainBundle.bundleIdentifier);
        dlopen([dylib UTF8String], RTLD_LAZY | RTLD_GLOBAL);
    }
}
