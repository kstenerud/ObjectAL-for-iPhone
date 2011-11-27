//
//  PlanetKillerDemo.h
//  ObjectAL
//
//  Created by Karl Stenerud on 10-05-30.
//

#import "cocos2d.h"

/**
 * Pseudo-game to demonstrate OALSimpleAudio.
 */
@interface PlanetKillerDemo : CCLayerColor
{
	CCSprite* ship;
	NSMutableArray* planets;
	NSMutableArray* bullets;
	
	CGRect innerPlanetRect;
	CGRect outerPlanetRect;
	
	float impactDistanceSquared;
}

@end
