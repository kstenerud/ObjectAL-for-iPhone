//
//  VUMeter.h
//  ObjectAL
//
//  Created by Karl Stenerud.
//

#import "cocos2d.h"


@interface VUMeter : CCNode
{
	CCSprite* needle;
	double db;
	double smoothing;
	double multiplier;
	double runningAverage;
}
@property(readwrite,assign) double db;
@property(readwrite,assign) double smoothing;
@property(readwrite,assign) double multiplier;

@property(readonly) double runningAverage;

+ (VUMeter*) meter;

@end
