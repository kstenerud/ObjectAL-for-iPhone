//
//  IOSVersion.h
//  ObjectiveGems
//
//  Created by Karl Stenerud on 10-11-07.
//

#import <Foundation/Foundation.h>
#import "SynthesizeSingleton.h"


@interface IOSVersion : NSObject
{
	float version;
}
@property(readonly) float version;

SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(IOSVersion);

@end
