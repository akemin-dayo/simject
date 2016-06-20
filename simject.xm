#import "simjectCore.h"

%hook SBApplicationInfo
-(NSDictionary *) environmentVariables {
	return simjectEnvironmentVariables(%orig(), self);
}
%end