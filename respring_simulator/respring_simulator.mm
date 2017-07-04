int main(int argc, const char *argv[]) {
    printf("respring_simulator (C) 2016 Karen Tsai (angelXwind)\n");
    printf("Injecting appropriate dynamic libraries from /opt/simject...\n");
    system("xcrun simctl spawn booted launchctl setenv DYLD_INSERT_LIBRARIES /opt/simject/simject.dylib");
    printf("Respringing...\n");
    system("xcrun simctl spawn booted launchctl stop com.apple.SpringBoard");
    return 0;
}
