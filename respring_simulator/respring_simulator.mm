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
    printf("\nRespring the booted device with matching UUID:\n\n");
    printf("\trespring_simulator -i 5AA1C45D-DB69-4C52-A75B-E9BE9C7E7770\n");
    printf("\t(Will respring simulator with UUID 5AA1C45D-DB69-4C52-A75B-E9BE9C7E7770)\n\n");
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

void inject(const char *device) {
    printf("respring_simulator (C) 2016 Karen Tsai (angelXwind)\n");
    printf("Injecting appropriate dynamic libraries from /opt/simject...\n");
    system([[NSString stringWithFormat:@"xcrun simctl spawn %s launchctl setenv DYLD_INSERT_LIBRARIES /opt/simject/simject.dylib", device] UTF8String]);
    printf("Respringing...\n");
    system([[NSString stringWithFormat:@"xcrun simctl spawn %s launchctl stop com.apple.backboardd", device] UTF8String]);
    exit(EXIT_SUCCESS);
}

int main(int argc, char *const argv[]) {
    int opt;
    char *device = NULL, *version = NULL, *uuid = NULL;
    int deviceFlag = 0, versionFlag = 0, uuidFlag = 0;
    while ((opt = getopt(argc, argv, "d:v:i:")) != -1) {
        switch (opt) {
            case 'd':
                device = strdup(optarg);
                if (*device == '-')
                    device = NULL;
                deviceFlag = 1;
                break;
            case 'v': {
                if (!regex_match(version = strdup(optarg), regex("\\d+\\.\\d+")))
                    version = NULL;
                versionFlag = 1;
                break;
            }
            case 'i':
                if (!regex_match(uuid = strdup(optarg), regex("[A-Z0-9\\-]+")))
                    uuid = NULL;
                uuidFlag = 1;
                break;
            default:
                printUsage();
                exit(EXIT_FAILURE);
        }
    }
    if (uuidFlag || deviceFlag || versionFlag) {
        char buffer[128];
        size_t len = readlink("/var/db/xcode_select_link", buffer, 128);
        if (len && [[[NSBundle bundleWithPath:[NSString stringWithUTF8String:strcat(buffer, "/Applications/Simulator.app/")]] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey] doubleValue] < 800.0) {
            printf("Warning: The selected Xcode version does not support multiple simulators, booting this device could cause the old one to stop (if not the same)");
        }
        if (!(uuidFlag != (deviceFlag && versionFlag))) {
            printUsage();
            exit(EXIT_FAILURE);
        }
    }
    if (!uuidFlag && !deviceFlag && !versionFlag) {
        inject("booted");
    }
    NSDictionary *defaultDevices = [NSDictionary dictionaryWithContentsOfFile:[NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Developer/CoreSimulator/Devices/device_set.plist"]][@"DefaultDevices"];
    if (defaultDevices == nil) {
        printf("Error: Could not open device_set.plist\n");
        exit(EXIT_FAILURE);
    }
    string bootedDevices = exec("xcrun simctl list devices | grep -E Booted | sed \"s/^[ \\t]*//\"");
    if (!bootedDevices.length()) {
        printf("Error: No such booted devices\n");
        exit(EXIT_FAILURE);
    }
    regex p("(.+) \\(([A-Z0-9\\-]+)\\) \\(Booted\\)");
    smatch m;
    if (uuidFlag) {
        while (regex_search(bootedDevices, m, p)) {
            if (strcmp(m[2].str().c_str(), uuid) == 0) {
                inject(uuid);
            }
            bootedDevices = m.suffix().str();
        }
        printf("Error: None of booted devices with UUID %s is found\n", uuid);
        exit(EXIT_FAILURE);
    } else {
        char *realVersion = strdup(version);
        char *replace = strchr(realVersion, '.');
        if (replace)
            *replace = '-';
        NSDictionary *runtime = defaultDevices[[NSString stringWithFormat:@"com.apple.CoreSimulator.SimRuntime.iOS-%s", realVersion]];
        if (runtime == nil || runtime.count == 0) {
            printf("Error: iOS %s SDK is not installed, or not supported\n", version);
            exit(EXIT_FAILURE);
        }
        NSArray *availableUUIDs = [runtime allValues];
        while (regex_search(bootedDevices, m, p)) {
            const char *bootedName = m[1].str().c_str();
            const char *bootedUUID = m[2].str().c_str();
            if ([availableUUIDs containsObject:[NSString stringWithUTF8String:bootedUUID]] && strcmp(bootedName, device) == 0) {
                inject(strdup(bootedUUID));
            }
            bootedDevices = m.suffix().str();
        }
    }
    printf("Error: Could not find any booted device with matching information\n");
    exit(EXIT_FAILURE);
}
