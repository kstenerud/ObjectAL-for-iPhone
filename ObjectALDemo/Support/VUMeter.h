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
@property(nonatomic,readwrite,assign) double db;
@property(nonatomic,readwrite,assign) double smoothing;
@property(nonatomic,readwrite,assign) double multiplier;

@property(nonatomic,readonly,assign) double runningAverage;

+ (VUMeter*) meter;

@end
