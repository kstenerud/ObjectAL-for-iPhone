//
//  TwoSourceDemo.h
//  ObjectAL
//
//  Created by Karl Stenerud on 10-05-29.
//

#import "cocos2d.h"
#import "ObjectAL.h"

/**
 * Demo of two sound sources.
 * The planets emit sound, and the space ship is the listener.
 * Touch the screen to move the space ship.
 */
@interface TwoSourceDemo : CCLayer
{
	CCSprite* rocketShip;
	CCSprite* leftPlanet;
	CCSprite* rightPlanet;
	ALSource* leftSource;
	ALSource* rightSource;
	ALBuffer* leftBuffer;
	ALBuffer* rightBuffer;
}

@end
