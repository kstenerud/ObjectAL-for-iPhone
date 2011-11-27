//
//  SingleSourceDemo.h
//  ObjectAL
//
//  Created by Karl Stenerud on 10-05-29.
//

#import "cocos2d.h"
#import "ObjectAL.h"

/**
 * Demo of a single sound source.
 * The planet emits sound, and the space ship is the listener.
 * Touch the screen to move the space ship.
 */
@interface SingleSourceDemo : CCLayer
{
	CCSprite* rocketShip;
	CCSprite* planet;
	ALSource* source;
	ALBuffer* buffer;
}

@end
