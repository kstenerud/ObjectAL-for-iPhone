//
//  FadeDemo.h
//  ObjectAL
//
//  Created by Karl Stenerud on 10-08-17.
//

#import "cocos2d.h"
#import "ObjectAL.h"

@interface FadeDemo : CCColorLayer
{
	ALSource* source;
	
	CCLabel* oalFading;
	CCLabel* bgFading;
}

@end
