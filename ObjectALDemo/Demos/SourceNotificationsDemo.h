//
//  SourceNotificationsDemo.h
//  ObjectAL
//
//  Created by Karl Stenerud on 12-09-06.
//

#import "cocos2d.h"

/**
 * Demonstrates using registerNotification to be informed when a source
 * reaches the end of a buffer, which is useful for chaining together
 * sequential playback across multiple buffers.
 *
 * Also makes use of some advanced features of OALAudioFile for loading
 * portions of an audio file into buffers.
 */
@interface SourceNotificationsDemo : CCLayerColor

@end
