//
//  HardwareDemo.h
//  ObjectAL
//
//  Created by Karl Stenerud on 10-10-15.
//

#import "cocos2d.h"
#import "LampButton.h"
#import "VUMeter.h"


/**
 * Demonstrates monitoring the hardware volume, mute button, and audio route.
 * Also demonstrates channel power monitoring with AudioTracks.
 */
@interface HardwareDemo : CCLayerColor
{
	CCLabelTTF* routeLabel;
	CCLabelTTF* volumeLabel;
	LampButton* muteLabel;
	
	VUMeter* leftMeter;
	VUMeter* rightMeter;
	
	float volume;
	NSString* route;
	bool muted;
}

@end
