#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>
#include <iostream>
#include <string>
#include <array>
#include <regex>

using namespace std;

void printUsage() {
    printf("\nUsage:\n");
    printf("\nRespring the latest booted device:\n\n");
    printf("\trespring_simulator\n");
    printf("\nRespring the booted device with matching type and version:\n\n");
    printf("\trespring_simulator -d \"iPhone 5\" -v 8.1\n");
    printf("\t(Will respring iPhone 5 simulator running iOS 8.1)\n");
    printf("\nRespring the booted device with matching UDID:\n\n");
    printf("\trespring_simulator -i 5AA1C45D-DB69-4C52-A75B-E9BE9C7E7770\n");
    printf("\t(Will respring simulator with UDID 5AA1C45D-DB69-4C52-A75B-E9BE9C7E7770)\n");
    printf("\nRespring any booted simulator:\n\n");
    printf("\trespring_simulator all\n");
    printf("\n");
}

string exec(const char *cmd) {
    array<char, 128> buffer;
    string result;
    shared_ptr<FILE> pipe(popen(cmd, "r"), pclose);
    if (pipe) {
        while (!feof(pipe.get())) {
            if (fgets(buffer.data(), 128, pipe.get()) != NULL)
                result += buffer.data();
        }
    }
    return result;
}

void injectHeader() {
    printf("respring_simulator (C) 2016 Karen Tsai (angelXwind)\n");
    printf("Injecting appropriate dynamic libraries from /opt/simject...\n");
}

void inject(const char *udid, const char *device, BOOL _exit) {
    if (device) {
        printf("Respringing %s (%s) ...\n", udid, device);
    } else {
        printf("Respringing %s ...\n", !strcmp(udid, "booted") ? "a booted device" : udid);
    }
    pid_t pid = fork();
    if (pid == 0) {
        system([[NSString stringWithFormat:@"xcrun simctl spawn %s launchctl setenv DYLD_INSERT_LIBRARIES /opt/simject/simject.dylib", udid] UTF8String]);
        system([[NSString stringWithFormat:@"xcrun simctl spawn %s launchctl setenv __XPC_DYLD_INSERT_LIBRARIES /opt/simject/simject.dylib", udid] UTF8String]);
        system([[NSString stringWithFormat:@"xcrun simctl spawn %s launchctl stop com.apple.backboardd", udid] UTF8String]);
        exit(EXIT_SUCCESS);
    } else {
        if (_exit)
            exit(EXIT_SUCCESS);
    }
}

void injectUDIDs(const char *udid, BOOL all) {
    string bootedDevices = exec("xcrun simctl list devices | grep -E Booted | sed \"s/^[ \\t]*//\"");
    if (!bootedDevices.length()) {
        printf("Error: No such booted devices\n");
        exit(EXIT_FAILURE);
    }
    regex p("(.+) \\(([A-Z0-9\\-]+)\\) \\(Booted\\)");
    smatch m;
    BOOL foundAny = NO;
    injectHeader();
    while (regex_search(bootedDevices, m, p)) {
        const char *bootedUDID = strdup(m[2].str().c_str());
        if (all || (udid && !strcmp(bootedUDID, udid))) {
            const char *bootedDevice = strdup(m[1].str().c_str());
            inject(bootedUDID, bootedDevice, NO);
            foundAny = YES;
        }
        bootedDevices = m.suffix().str();
    }
    if (!foundAny)
        printf("Error: None of booted devices with UDID(s) specified is found\n");
    exit(foundAny ? EXIT_SUCCESS : EXIT_FAILURE);
}

NSString *XcodePath() {
    char buffer[128];
    size_t len = readlink("/var/db/xcode_select_link", buffer, 128);
    return len ? [NSString stringWithUTF8String:buffer] : nil;
}

void fixLaunchctlIfNecessary(const char *version) {
    NSString *searchPath = @"/Library/Developer/CoreSimulator/Profiles/Runtimes";
    NSString *runtimeRoot = [XcodePath() stringByAppendingPathComponent:@"/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot"];
    BOOL rootIsDirectory;
    if (![[NSFileManager defaultManager] fileExistsAtPath:runtimeRoot isDirectory:&rootIsDirectory] || !rootIsDirectory) {
        if (!version) {
            printf("(Fixing launchctl) Notice: Runtime version is not specified, version 11.0 will be used\n");
            version = "11.0";
        }
        runtimeRoot = [searchPath stringByAppendingPathComponent:[NSString stringWithFormat:@"/iOS %s.simruntime/Contents/Resources/RuntimeRoot", version]];
    }
    NSString *launchctlPath = [runtimeRoot stringByAppendingPathComponent:@"/bin/launchctl"];
    BOOL launchctlIsDirectory;
    if ([[NSFileManager defaultManager] fileExistsAtPath:runtimeRoot isDirectory:&rootIsDirectory] && rootIsDirectory && ![[NSFileManager defaultManager] fileExistsAtPath:launchctlPath isDirectory:&launchctlIsDirectory] && !launchctlIsDirectory) {
        printf("Notice: The %s runtime does not include launchctl, simject will now try to copy from older runtimes\n", version);
        NSError *error = nil;
        NSArray *searchContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:searchPath error:&error];
        if (error) {
            printf("Error: Could not access %s to find available runtimes\n", [searchPath UTF8String]);
            exit(EXIT_FAILURE);
        }
        NSArray *runtimes = [searchContents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(SELF ENDSWITH %@) AND (SELF BEGINSWITH %@)", @"runtime", @"iOS"]];
        if (runtimes.count == 0) {
            printf("Error: No such runtime is found\n");
            exit(EXIT_FAILURE);
        }
        runtimes = [runtimes sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
        BOOL copied = NO;
        for (NSString *runtime in [runtimes reverseObjectEnumerator]) {
            if ([runtime compare:@"iOS 11.0.simruntime" options:NSForcedOrderingSearch | NSNumericSearch] >= NSOrderedSame) {
                printf("Notice: Skipping %s\n", [runtime UTF8String]);
                continue;
            }
            NSString *oldLaunchctlPath = [[searchPath stringByAppendingPathComponent:runtime] stringByAppendingPathComponent:@"/Contents/Resources/RuntimeRoot/bin/launchctl"];
            if ([[NSFileManager defaultManager] fileExistsAtPath:oldLaunchctlPath isDirectory:&launchctlIsDirectory] && !launchctlIsDirectory) {
                printf("Notice: Found launchctl in %s\n", [runtime UTF8String]);
                NSString *binPath = [launchctlPath stringByDeletingLastPathComponent];
                BOOL binExisted, binIsDirectory;
                if (!(binExisted = [[NSFileManager defaultManager] fileExistsAtPath:binPath isDirectory:&binIsDirectory]) || !binIsDirectory) {
                    printf("Notice: Creating /bin folder\n");
                    if (binExisted && !binIsDirectory) {
                        printf("Notice: Improper /bin detected, removing\n");
                        if (![[NSFileManager defaultManager] removeItemAtPath:binPath error:NULL]) {
                            printf("Error: Could not remove /bin\n");
                            exit(EXIT_FAILURE);
                        }
                    }
                    if (![[NSFileManager defaultManager] createDirectoryAtPath:binPath withIntermediateDirectories:NO attributes:nil error:NULL]) {
                        printf("Error: Could not create /bin folder\n");
                        exit(EXIT_FAILURE);
                    }
                }
                if (![[NSFileManager defaultManager] copyItemAtPath:oldLaunchctlPath toPath:launchctlPath error:NULL]) {
                    printf("Error: Could not copy launchctl from %s\n", [runtime UTF8String]);
                    exit(EXIT_FAILURE);
                }
                if ([runtime compare:@"iOS 10.0.simruntime" options:NSForcedOrderingSearch | NSNumericSearch] < NSOrderedSame) {
                    printf("Warning: %s may not be suitable for iOS 11, iOS 10.x runtime is recommended\n", [runtime UTF8String]);
                }
                printf("Notice: launchctl from %s is copied\n", [runtime UTF8String]);
                copied = YES;
                break;
            }
        }
        if (!copied) {
            printf("Error: Could not find any proper launchctl to copy\n");
            exit(EXIT_FAILURE);
        }
    }
}

int main(int argc, char *const argv[]) {
    if (argc == 2) {
        if (!strcmp(argv[1], "all")) {
            fixLaunchctlIfNecessary(NULL);
            injectUDIDs(NULL, YES);
        } else if (!strcmp(argv[1], "help")) {
            printUsage();
            exit(EXIT_SUCCESS);
        }
    }
    int opt;
    char *device = NULL, *version = NULL, *udid = NULL;
    int deviceFlag = 0, versionFlag = 0, udidFlag = 0;
    while ((opt = getopt(argc, argv, "d:v:i:")) != -1) {
        switch (opt) {
            case 'd':
                device = strdup(optarg);
                if (*device == '-') {
                    device = NULL;
                    printf("Error: Device is entered incorrectly\n");
                }
                deviceFlag = 1;
                break;
            case 'v': {
                if (!regex_match(version = strdup(optarg), regex("\\d+\\.\\d+"))) {
                    version = NULL;
                    printf("Error: Version is entered incorrectly\n");
                }
                versionFlag = 1;
                break;
            }
            case 'i':
                if (!regex_match(udid = strdup(optarg), regex("[A-Z0-9\\-]+"))) {
                    udid = NULL;
                    printf("Error: UDID is entered incorrectly\n");
                }
                udidFlag = 1;
                break;
            default:
                printUsage();
                exit(EXIT_FAILURE);
        }
    }
    if (udidFlag || deviceFlag || versionFlag) {
        if ([[[NSBundle bundleWithPath:[XcodePath() stringByAppendingPathComponent:@"/Applications/Simulator.app/"]] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey] doubleValue] < 800.0) {
            printf("Warning: The selected Xcode version does not support multiple simulators, booting this device could cause the old one to stop (if not the same)");
        }
        if (!(udidFlag != (deviceFlag && versionFlag))) {
            printUsage();
            exit(EXIT_FAILURE);
        }
    }
    fixLaunchctlIfNecessary(version);
    if (!udidFlag && !deviceFlag && !versionFlag) {
        injectHeader();
        inject("booted", NULL, YES);
    }
    if (udidFlag) {
        injectUDIDs(udid, NO);
    } else {
        NSString *devicesString = [NSString stringWithUTF8String:exec("xcrun simctl list devices -j").c_str()];
        NSError *error = nil;
        NSDictionary *devices = [NSJSONSerialization JSONObjectWithData:[devicesString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error][@"devices"];
        if (error || devices == nil) {
            printf("Error: Could not list available devices\n");
            exit(EXIT_FAILURE);
        }
        NSArray <NSDictionary *> *runtime = devices[[NSString stringWithFormat:@"iOS %s", version]];
        if (runtime == nil || runtime.count == 0) {
            printf("Error: iOS %s runtime is not installed, or not supported\n", version);
            exit(EXIT_FAILURE);
        }
        for (NSDictionary <NSString *, NSString *> *entry in runtime) {
            const char *state = [entry[@"state"] UTF8String];
            const char *name = [entry[@"name"] UTF8String];
            const char *udid = [entry[@"udid"] UTF8String];
            if (!strcmp(name, device)) {
                if (strcmp(state, "Booted")) {
                    printf("Error: This device (%s, %s) is not yet booted up\n", name, udid);
                    exit(EXIT_FAILURE);
                }
                injectHeader();
                inject(udid, name, YES);
            }
        }
    }
    printf("Error: Could not find any booted device with matching information\n");
    exit(EXIT_FAILURE);
}
