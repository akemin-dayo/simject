#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>
#include <sys/wait.h>
#include <iostream>
#include <string>
#include <array>
#include <regex>

using namespace std;

BOOL iOS7 = NO;

void globalHeader() {
	printf("respring_simulator (C) 2016-2018 Karen/あけみ (angelXwind)\n");
}

void printUsage() {
	globalHeader();
	printf("\nUsage: respring_simulator [options]\n");
	printf("Example: respring_simulator -d \"iPhone 5\" -v 8.1\n");
	printf("\nAvailable options:\n");
	printf("\t-h    Shows this usage dialog\n");
	printf("\t-d    Specifies a device type\n");
	printf("\t-v    Specifies an iOS version\n");
	printf("\t-i    Specifies a UUID corresponding to a specific iOS Simulator\n");
	printf("\t-l    Enables iOS 7 compatibility mode (simject will not work with the iOS 7 runtime without this)\n");
	printf("\tall   Resprings all booted iOS Simulators\n");
	printf("\nExample usages:\n");
	printf("\tRespring a booted device matching the specified device type and iOS version\n");
	printf("\t\trespring_simulator -d \"iPhone 5\" -v 8.1\n");
	printf("\tRespring a booted device with the specified UUID\n");
	printf("\t\trespring_simulator -i 5AA1C45D-DB69-4C52-A75B-E9BE9C7E7770\n");
	printf("\tRespring all booted iOS Simulators\n");
	printf("\t\trespring_simulator all\n");
	printf("\tRespring an iOS Simulator using the iOS 7 runtime (Xcode <= 6.2)\n");
	printf("\t\trespring_simulator -l\n");
}

void safe_system(const char *cmd) {
	int status = system(cmd);
	if (WEXITSTATUS(status) != EXIT_SUCCESS) {
		printf("Error executing command, exiting.\n");
		exit(EXIT_FAILURE);
	}
}

string exec(const char *cmd) {
	array<char, 128> buffer;
	string result;
	shared_ptr<FILE> pipe(popen(cmd, "r"), pclose);
	if (pipe) {
		while (!feof(pipe.get())) {
			if (fgets(buffer.data(), 128, pipe.get()) != NULL) {
				result += buffer.data();
			}
		}
	}
	return result;
}

void injectHeader() {
	globalHeader();
	printf("Injecting appropriate dynamic libraries from /opt/simject...\n");
}

void inject(const char *uuid, const char *device, BOOL _exit) {
	if (uuid == NULL) {
		printf("ERROR: UUID is null, cannot continue.\n");
		exit(EXIT_FAILURE);
	}
	if (device) {
		printf("Respringing %s (%s) ...\n", uuid, device);
	} else {
		printf("Respringing %s ...\n", !strcmp(uuid, "booted") ? "a booted device" : uuid);
	}
	if (fork() == 0) {
		if (iOS7) {
			if (!strcmp(uuid, "booted")) {
				string suuid = exec("xcrun simctl list devices | grep -E Booted | grep -oE \"\\([A-Z0-9\\-]+\\)\" | sed \"s/[()]//g\"");
				if (!suuid.empty()) {
					suuid.erase(suuid.length() - 1);
				}
				uuid = strdup(suuid.c_str());
			}
			safe_system([[NSString stringWithFormat:@"plutil -replace bootstrap.child.DYLD_INSERT_LIBRARIES -string /opt/simject/simject.dylib %@/Library/Developer/CoreSimulator/Devices/%@/data/var/run/launchd_bootstrap.plist -s", NSHomeDirectory(), @(uuid)] UTF8String]);
			safe_system("killall launchd_sim");
		} else {
			safe_system([[NSString stringWithFormat:@"xcrun simctl spawn %s launchctl setenv DYLD_INSERT_LIBRARIES /opt/simject/simject.dylib", uuid] UTF8String]);
			safe_system([[NSString stringWithFormat:@"xcrun simctl spawn %s launchctl setenv __XPC_DYLD_INSERT_LIBRARIES /opt/simject/simject.dylib", uuid] UTF8String]);
			safe_system([[NSString stringWithFormat:@"xcrun simctl spawn %s launchctl setenv CG_CONTEXT_SHOW_BACKTRACE 1", uuid] UTF8String]);
			safe_system([[NSString stringWithFormat:@"xcrun simctl spawn %s launchctl stop com.apple.backboardd", uuid] UTF8String]);
		}
		exit(EXIT_SUCCESS);
	} else {
		if (_exit) {
			exit(EXIT_SUCCESS);
		}
	}
}

void injectUUIDs(const char *uuid, BOOL all) {
	string bootedDevices = exec("xcrun simctl list devices | grep -E Booted | sed \"s/^[ \\t]*//\"");
	if (!bootedDevices.length()) {
		printf("Error: No booted iOS Simulators were found.\n");
		exit(EXIT_FAILURE);
	}
	regex p("(.+) \\(([A-Z0-9\\-]+)\\) \\(Booted\\)");
	smatch m;
	BOOL foundAny = NO;
	injectHeader();
	while (regex_search(bootedDevices, m, p)) {
		const char *bootedUUID = strdup(m[2].str().c_str());
		if (all || (uuid && !strcmp(bootedUUID, uuid))) {
			const char *bootedDevice = strdup(m[1].str().c_str());
			inject(bootedUUID, bootedDevice, NO);
			foundAny = YES;
		}
		bootedDevices = m.suffix().str();
	}
	if (!foundAny) {
		printf("Error: No booted iOS Simulators with an UUID matching the specified UUID was found.\n");
	}
	exit(foundAny ? EXIT_SUCCESS : EXIT_FAILURE);
}

NSString *XcodePath() {
	char buffer[128];
	size_t len = readlink("/var/db/xcode_select_link", buffer, 128);
	return len ? [NSString stringWithUTF8String:buffer] : @"/Applications/Xcode.app";
}

double XcodeVersion() {
	NSBundle *simulatorBundle = [NSBundle bundleWithPath:[XcodePath() stringByAppendingPathComponent:@"/Applications/Simulator.app/"]];
	if (simulatorBundle == nil) {
		simulatorBundle = [NSBundle bundleWithPath:[XcodePath() stringByAppendingPathComponent:@"/Applications/iOS Simulator.app/"]];
	}
	return [[simulatorBundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey] doubleValue];
}

int main(int argc, char *const argv[]) {
	double xcodeVersion = 0;
	iOS7 = (xcodeVersion = XcodeVersion()) < 600.0 && xcodeVersion; // Should be around where Xcode 6.2 is (and only on Mavericks)
	if (argc == 2) {
		if (!strcmp(argv[1], "all")) {
			injectUUIDs(NULL, YES);
		} else if (!strcmp(argv[1], "help")) {
			printUsage();
			exit(EXIT_SUCCESS);
		}
	}
	int opt;
	char *device = NULL, *version = NULL, *uuid = NULL;
	int deviceFlag = 0, versionFlag = 0, uuidFlag = 0;
	while ((opt = getopt(argc, argv, "d:v:i:lh")) != -1) {
		switch (opt) {
			case 'd':
				device = strdup(optarg);
				if (*device == '-') {
					device = NULL;
					printf("ERROR: iOS Simulator device parameter was entered incorrectly.\n");
				}
				deviceFlag = 1;
				break;
			case 'v': {
				if (!regex_match(version = strdup(optarg), regex("\\d+\\.\\d+"))) {
					version = NULL;
					printf("ERROR: iOS version was entered incorrectly.\n");
				}
				versionFlag = 1;
				break;
			}
			case 'i':
				if (!regex_match(uuid = strdup(optarg), regex("[A-Z0-9]{8}\\-[A-Z0-9]{4}\\-[A-Z0-9]{4}\\-[A-Z0-9]{4}\\-[A-Z0-9]{12}"))) {
					uuid = NULL;
					printf("ERROR: UUID was entered incorrectly.\n");
				}
				uuidFlag = 1;
				break;
			case 'l':
				iOS7 = YES;
				break;
			case 'h':
				printUsage();
				exit(EXIT_SUCCESS);
			default:
				printUsage();
				exit(EXIT_FAILURE);
		}
	}
	if (uuidFlag || deviceFlag || versionFlag || iOS7) {
		if (xcodeVersion && xcodeVersion < 800.0) {
			printf("WARNING: The selected Xcode version does not support multiple running iOS Simulator instances simultaneously. Booting this device may cause any other existing instances of the iOS Simulator to terminate.\n");
		}
		if (!(uuidFlag != (deviceFlag && versionFlag)) && !iOS7) {
			printUsage();
			exit(EXIT_FAILURE);
		}
	}
	if (!uuidFlag && !deviceFlag && !versionFlag) {
		injectHeader();
		inject("booted", NULL, YES);
	}
	if (uuidFlag) {
		injectUUIDs(uuid, NO);
	} else {
		NSString *devicesString = [NSString stringWithUTF8String:exec("xcrun simctl list devices -j").c_str()];
		NSError *error = nil;
		NSDictionary *devices = [NSJSONSerialization JSONObjectWithData:[devicesString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error][@"devices"];
		if (error || devices == nil) {
			printf("ERROR: Could not list available iOS Simulator devices\n");
			exit(EXIT_FAILURE);
		}
		NSArray *runtime = devices[[NSString stringWithFormat:@"iOS %s", version]];
		if (runtime == nil) {
			version[strlen(version) - 2] = '-';
			runtime = devices[[NSString stringWithFormat:@"com.apple.CoreSimulator.SimRuntime.iOS-%s", version]];
		}
		if (runtime == nil || runtime.count == 0) {
			printf("ERROR: iOS %s runtime is not installed, or not supported by simject\n", version);
			exit(EXIT_FAILURE);
		}
		for (NSDictionary *entry in runtime) {
			const char *state = [entry[@"state"] UTF8String];
			const char *name = [entry[@"name"] UTF8String];
			const char *uuid = [entry[@"udid"] UTF8String];
			if (!strcmp(name, device)) {
				if (strcmp(state, "Booted")) {
					printf("ERROR: This device (%s, %s) has not yet booted up.\n", name, uuid);
					exit(EXIT_FAILURE);
				}
				injectHeader();
				inject(uuid, name, YES);
			}
		}
	}
	printf("ERROR: Could not find any booted iOS Simulator devices with the specified parameters.\n");
	exit(EXIT_FAILURE);
}
