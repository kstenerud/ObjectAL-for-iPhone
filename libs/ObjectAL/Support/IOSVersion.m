//
//  IOSVersion.m
//  ObjectiveGems
//
//  Created by Karl Stenerud on 10-11-07.
//

#import "IOSVersion.h"
#import <UIKit/UIKit.h>


@implementation IOSVersion

SYNTHESIZE_SINGLETON_FOR_CLASS(IOSVersion);

- (id) init
{
	if(nil != (self = [super init]))
	{
		NSString* versionStr = [[UIDevice currentDevice] systemVersion];
		unichar ch = [versionStr characterAtIndex:0];
		if(ch < '0' || ch > '9' || [versionStr characterAtIndex:1] != '.')
		{
			NSLog(@"Error: %s: Cannot parse iOS version string [%@]", __PRETTY_FUNCTION__, versionStr);
		}
		
		version = (float)(ch - '0');
		
		float multiplier = 0.1f;
		unsigned int vLength = [versionStr length];
		for(unsigned int i = 2; i < vLength; i++)
		{
			unichar ch = [versionStr characterAtIndex:i];
			if(ch >= '0' && ch <= '9')
			{
				version += (ch - '0') * multiplier;
				multiplier /= 10;
			}
			else if('.' != ch)
			{
				break;
			}
		}
	}
	return self;
}

@synthesize version;

@end
