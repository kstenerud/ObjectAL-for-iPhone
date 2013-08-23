//
//  HighSpeedPlaybackDemo.h
//  ObjectALDemo
//
//  Created by Karl Stenerud on 8/22/13.
//  Copyright (c) 2013 Karl Stenerud. All rights reserved.
//

#import "CCLayer.h"

/**
 * Tests playing back buffers at a high rate.
 * Use the sliders to change the rate of fire for the two buffers.
 * Regardless of the rate you set, there are only 28 mono sources available,
 * and in the default configuration they won't be interruptible, so max
 * combined fire rate will be buffer length / 28 plays per second.
 */
@interface HighSpeedPlaybackDemo : CCLayer

@end
