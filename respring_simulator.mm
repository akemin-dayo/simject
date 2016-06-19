#import "simjectCore.h"

int main(int argc, const char * argv[]) {
	printf("respring_simulator (C) 2016 Karen Tsai (angelXwind)\n");
	printf("Injecting appropriate dynamic libraries from /opt/simject...\n");
	NSString *envVars;
	system([[NSString stringWithFormat:@"xcrun simctl spawn booted launchctl debug system/com.apple.SpringBoard%@", (envVars = simjectGenerateDILEnvVar(simjectGenerateDylibList(nil))) ? [NSString stringWithFormat:@" --environment DYLD_INSERT_LIBRARIES=%@", envVars] : nil] UTF8String]);
	printf("Respringing...\n");
	system("xcrun simctl spawn booted launchctl stop com.apple.SpringBoard");
	return 0;
}
