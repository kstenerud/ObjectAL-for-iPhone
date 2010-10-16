//
//  HardwareDemo.h
//  ObjectAL
//
//  Created by Karl Stenerud on 10-10-15.
//

#import "cocos2d.h"


/**
 * Demonstrates monitoring the hardware volume, mute button, and audio route.
 */
@interface HardwareDemo : CCColorLayer
{
	CCLabel* routeLabel;
	CCLabel* muteLabel;
	CCLabel* volumeLabel;
	
	float volume;
	NSString* route;
	bool muted;
}

@end
