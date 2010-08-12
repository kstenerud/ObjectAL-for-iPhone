//
//  RNG.h
//
//  Created by Karl Stenerud on 10-02-15.
//

#import "SynthesizeSingleton.h"

/** Random number generator interface */
@interface RNG : NSObject
{
	unsigned int seedValue;
}
/** The current seed value being used */
@property(nonatomic,readwrite,assign) unsigned int seedValue;

SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(RNG);

/** Initialize with the specified seed value.
 * This must ONLY be called BEFORE accessing sharedInstance.
 */
- (id) initWithSeed:(unsigned int) seed;

/** Returns a random unsigned int from 0 to 0xffffffff */
- (unsigned int) randomUnsignedInt;

/** Returns a random probability value from 0.0 to 1.0 */
- (double) randomProbability;

/** Returns a random integer from minValue to maxValue */
- (int) randomNumberFrom: (int) minValue to: (int) maxValue;

/** Returns a random integer from minValue to maxValue, but does not return exceptValue */
- (int) randomNumberFrom: (int) minValue to: (int) maxValue except:(int) exceptValue;

/** Randomly returns YES or NO */
- (bool) randomBool;

@end
