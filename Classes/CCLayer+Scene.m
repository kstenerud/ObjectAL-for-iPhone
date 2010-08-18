//
//  CCLayer+Scene.m
//  ObjectAL
//
//  Created by Karl Stenerud on 10-08-17.
//

#import "CCLayer+Scene.h"


@implementation CCLayer (Scene)

+(id) scene
{
	CCScene *scene = [CCScene node];
	[scene addChild: [self node]];
	return scene;
}

@end
