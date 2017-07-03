#import "../simjectCore.h"

int main(int argc, const char *argv[]) {
    printf("respring_simulator (C) 2016 Karen Tsai (angelXwind)\n");
    printf("Injecting appropriate dynamic libraries from /opt/simject...\n");
    NSString *envVars;
    int result = system("[[ `xcrun simctl spawn booted launchctl version | grep -oE \"\\d\\.\\d\\.\\d\" | grep -oE \"^\\d\"` -le 2 ]]");
    if (result) {
        system([[NSString stringWithFormat:@"xcrun simctl spawn booted launchctl debug system/com.apple.SpringBoard%@", (envVars = simjectGenerateDylibList(nil, nil)) ? [NSString stringWithFormat:@" --environment DYLD_INSERT_LIBRARIES=%@", envVars] : nil] UTF8String]);
    } else {
        printf("Using another method...\n");
        system([[NSString stringWithFormat:@"xcrun simctl spawn booted launchctl setenv%@", (envVars = simjectGenerateDylibList(nil, nil)) ? [NSString stringWithFormat:@" DYLD_INSERT_LIBRARIES \"%@\"", envVars] : nil] UTF8String]);
    }
    printf("Respringing...\n");
    system("xcrun simctl spawn booted launchctl stop com.apple.SpringBoard");
    if (!result) {
        system("xcrun simctl spawn booted launchctl unsetenv DYLD_INSERT_LIBRARIES");
    }
    return 0;
}
