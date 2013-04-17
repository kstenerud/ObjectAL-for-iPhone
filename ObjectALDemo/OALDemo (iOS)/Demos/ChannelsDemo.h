//
//  ChannelsDemo.h
//  ObjectAL
//
//  Created by Karl Stenerud on 10-05-30.
//

#import "cocos2d.h"
#import <ObjectAL/ObjectAL.h>

/**
 * Demonstrates the use of channels, and audio tracks.
 *
 * A channel reserves audio sources and by default does not allow playback interruption.
 * In creating a channel, you can ensure exclusive access to that channel's sources, which is
 * useful when you absolutely must have a source (or multiple sources) available that won't
 * get interrupted and taken by another sound play request.
 *
 * The iPhone can handle up to 32 sources.  You can slice them up any way you like.
 *
 * When creating a channel, the number of sources you specify determines the number of
 * sounds that can be played simultaneously.
 * There are 4 buttons in the demo, each corresponding to a 1, 2, 3, and 8 source channel.
 * Try tapping a button as fast as possible to see how the channel deals with it.
 */
@interface ChannelsDemo : CCLayerColor
{
	ALChannelSource* oneSourceChannel;
	ALChannelSource* twoSourceChannel;
	ALChannelSource* threeSourceChannel;
	ALChannelSource* eightSourceChannel;
	ALBuffer* buffer;
}

@end
