//
//  AudioTrackDemo.h
//  ObjectAL
//
//  Created by Karl Stenerud on 10-09-19.
//

#import "cocos2d.h"

/**
 * Demonstrates using multiple OALAudioTrack objects.
 *
 * By default, OALAudioSupport grabs the hardware decoder if it's available (useHardwareIfAvailable).
 * When the hardware is available, the first track to play gets the hardware and all others use software.
 */
@interface AudioTrackDemo : CCLayerColor
{
	NSMutableArray* audioTracks;
	NSMutableArray* audioTrackFiles;
	NSMutableArray* buttons;
	NSMutableArray* sliders;
}

@end
