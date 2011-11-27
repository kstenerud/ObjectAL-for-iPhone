//
//  VolumePitchPanDemo.h
//  ObjectAL
//
//  Created by Karl Stenerud on 10-05-30.
//

#import "cocos2d.h"
#import "ObjectAL.h"

/**
 * Demo of volume, pitch, and pan control.
 * Use the sliders to change volume, pitch, and pan.
 * Note: Pan requires stereo headphones since the iPhone outputs mono to its built-in speaker.
 */
@interface VolumePitchPanDemo : CCLayerColor
{
	ALSource* source;
	ALBuffer* buffer;
}

@end
