//
//  RNG.m
//
//  Created by Karl Stenerud on 10-02-15.
//

#import "RNG.h"

SYNTHESIZE_SINGLETON_FOR_CLASS_PROTOTYPE(RNG);


@implementation RNG

SYNTHESIZE_SINGLETON_FOR_CLASS(RNG);

- (id) init
{
	return [self initWithSeed:(unsigned int)time(NULL)];
}

- (id) initWithSeed:(unsigned int) seedValueIn
{
	if(nil != (self = [super init]))
	{
		self.seedValue = seedValueIn;
	}
	return self;
}

@synthesize seedValue;

- (void) setSeedValue:(unsigned int) value
{
	seedValue = value;
	srand(seedValue);
}

- (unsigned int) randomUnsignedInt
{
	return (unsigned int)rand();
}

- (double) randomProbability
{
	return rand() / 2147483647.0;
}

- (int) randomNumberFrom: (int) minValue to: (int) maxValue
{
	double probability = rand() / 2147483648.0;
	double range = maxValue - minValue + 1;
	return (int)(range * probability + minValue);
}

- (int) randomNumberFrom: (int) minValue to: (int) maxValue except:(int) exceptValue
{
	if(minValue == maxValue)
	{
		return minValue;
	}
	int result;
	while(exceptValue == (result = [self randomNumberFrom:minValue to:maxValue]))
	{
	}
	return result;
}

- (bool) randomBool
{
	return rand() & 1;
}

@end
