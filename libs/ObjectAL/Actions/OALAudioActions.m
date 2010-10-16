//
//  OALAudioActions.m
//  ObjectAL
//
//  Created by Karl Stenerud on 10-10-10.
//
// Copyright 2010 Karl Stenerud
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// Note: You are NOT required to make the license available from within your
// iOS application. Including it in your project is sufficient.
//
// Attribution is not required, but appreciated :)
//

#import "OALAudioActions.h"


#pragma mark OAL_GainProtocol

/** (INTERNAL USE) Protocol to keep the compiler happy. */
@protocol OAL_GainProtocol

/** The gain (volume), represented as a float from 0.0 to 1.0. */
@property(readwrite) float gain;

@end


#pragma mark -
#pragma mark OALGainAction

@implementation OALGainAction


#pragma mark Utility

+ (id<OALFunction,NSObject>) defaultFunction
{
	return [OALSCurveFunction function];
}


#pragma mark Functions

- (void) prepareWithTarget:(id) targetIn
{
	NSAssert([targetIn respondsToSelector:@selector(gain)]
			 && [targetIn respondsToSelector:@selector(setGain:)],
			 @"Target does not respond to selectors [gain] and [setGain:]");
	
	// NAN is a special marker value instructing us to use the current value from the target.
	if(isnan(startValue))
	{
		startValue = [(id<OAL_GainProtocol>)targetIn gain];
	}
	
	[super prepareWithTarget:targetIn];
}

- (void) updateCompletion:(float) proportionComplete
{
	[(id<OAL_GainProtocol>)target setGain:lowValue
	 + [realFunction valueForInput:proportionComplete] * delta];
}

@end


#pragma mark -
#pragma mark OAL_PitchProtocol

/** (INTERNAL USE) Protocol to keep the compiler happy. */
@protocol OAL_PitchProtocol

/** The pitch, represented as a float with 1.0 representing normal pitch. */
@property(readwrite) float pitch;

@end


#pragma mark -
#pragma mark OALPitchAction

@implementation OALPitchAction


#pragma mark Utility

+ (id<OALFunction,NSObject>) defaultFunction
{
	return [OALLinearFunction function];
}


#pragma mark Functions

- (void) prepareWithTarget:(id) targetIn
{	
	NSAssert([targetIn respondsToSelector:@selector(pitch)]
			 && [targetIn respondsToSelector:@selector(setPitch:)],
			 @"Target does not respond to selectors [pitch] and [setPitch:]");
	
	// NAN is a special marker value instructing us to use the current value from the target.
	if(isnan(startValue))
	{
		startValue = [(id<OAL_PitchProtocol>)targetIn pitch];
	}
	
	[super prepareWithTarget:targetIn];
}

- (void) updateCompletion:(float) proportionComplete
{
	[(id<OAL_PitchProtocol>)target setPitch:startValue
	 + [realFunction valueForInput:proportionComplete] * delta];
}

@end


#pragma mark -
#pragma mark OAL_PanProtocol

/** (INTERNAL USE) Protocol to keep the compiler happy. */
@protocol OAL_PanProtocol

/** The pan, represented as a float from -1.0 to 1.0. */
@property(readwrite) float pan;

@end


#pragma mark -
#pragma mark OALPanAction

@implementation OALPanAction


#pragma mark Utility

+ (id<OALFunction,NSObject>) defaultFunction
{
	return [OALLinearFunction function];
}


#pragma mark Functions

- (void) prepareWithTarget:(id) targetIn
{	
	NSAssert([targetIn respondsToSelector:@selector(pan)]
			 && [targetIn respondsToSelector:@selector(setPan:)],
			 @"Target does not respond to selectors [pan] and [setPan:]");
	
	// NAN is a special marker value instructing us to use the current value from the target.
	if(isnan(startValue))
	{
		startValue = [(id<OAL_PanProtocol>)targetIn pan];
	}
	
	[super prepareWithTarget:targetIn];
}

- (void) updateCompletion:(float) proportionComplete
{
	[(id<OAL_PanProtocol>)target setPan:startValue
	 + [realFunction valueForInput:proportionComplete] * delta];
}

@end


#pragma mark -
#pragma mark OAL_PositionProtocol

/** (INTERNAL USE) Protocol to keep the compiler happy. */
@protocol OAL_PositionProtocol

/** The position in 3D space. */
@property(readwrite,assign) ALPoint position;

@end


#pragma mark -
#pragma mark OALPlaceAction

@implementation OALPlaceAction


#pragma mark Object Management

+ (id) actionWithPosition:(ALPoint) position
{
	return [[(OALPlaceAction*)[self alloc] initWithPosition:position] autorelease];
}

- (id) initWithPosition:(ALPoint) positionIn
{
	if(nil != (self = [super init]))
	{
		position = positionIn;
	}
	return self;
}


#pragma mark Properties

@synthesize position;


#pragma mark Functions

- (void) prepareWithTarget:(id) targetIn
{	
	NSAssert([targetIn respondsToSelector:@selector(setPosition:)],
			 @"Target does not respond to selector [setPosition:]");
	
	[super prepareWithTarget:targetIn];
}

- (void) updateCompletion:(float) proportionComplete
{
	[super updateCompletion:proportionComplete];
	[(id<OAL_PositionProtocol>)target setPosition:position];
}

@end


#pragma mark -
#pragma mark OALMoveToAction

@implementation OALMoveToAction


#pragma mark Object Management

+ (id) actionWithDuration:(float) duration position:(ALPoint) position
{
	return [[(OALMoveToAction*)[self alloc] initWithDuration:duration position:position] autorelease];
}

+ (id) actionWithUnitsPerSecond:(float) unitsPerSecond position:(ALPoint) position
{
	return [[[self alloc] initWithUnitsPerSecond:unitsPerSecond position:position] autorelease];
}

- (id) initWithDuration:(float) durationIn position:(ALPoint) positionIn
{
	if(nil != (self = [super initWithDuration:durationIn]))
	{
		position = positionIn;
	}
	return self;
}

- (id) initWithUnitsPerSecond:(float) unitsPerSecondIn position:(ALPoint) positionIn
{
	if(nil != (self = [super init]))
	{
		position = positionIn;
		unitsPerSecond = unitsPerSecondIn;
	}
	return self;
}


#pragma mark Properties

@synthesize position;
@synthesize unitsPerSecond;


#pragma mark Functions

- (void) prepareWithTarget:(id) targetIn
{
	NSAssert([targetIn respondsToSelector:@selector(setPosition:)],
			 @"Target does not respond to selector [setPosition:]");
	
	[super prepareWithTarget:targetIn];

	startPoint = [(id<OAL_PositionProtocol>)targetIn position];
	delta = ALPointMake(position.x-startPoint.x, position.y-startPoint.y, position.z - startPoint.z);

	// If unitsPerSecond was set, we use that to calculate duration.  Otherwise just use the current
	// value in duration.
	if(unitsPerSecond > 0)
	{
		duration = sqrtf(delta.x * delta.x + delta.y * delta.y + delta.z * delta.z) / unitsPerSecond;
	}
}

- (void) updateCompletion:(float) proportionComplete
{
	[(id<OAL_PositionProtocol>)target setPosition:
	 ALPointMake(startPoint.x + delta.x*proportionComplete,
				 startPoint.y + delta.y*proportionComplete,
				 startPoint.z + delta.z*proportionComplete)];
}

@end


#pragma mark -
#pragma mark OALMoveByAction

@implementation OALMoveByAction


#pragma mark Object Management

+ (id) actionWithDuration:(float) duration delta:(ALPoint) delta
{
	return [[[self alloc] initWithDuration:duration delta:delta] autorelease];
}

+ (id) actionWithUnitsPerSecond:(float) unitsPerSecond delta:(ALPoint) delta
{
	return [[[self alloc] initWithUnitsPerSecond:unitsPerSecond delta:delta] autorelease];
}

- (id) initWithDuration:(float) durationIn delta:(ALPoint) deltaIn
{
	if(nil != (self = [super initWithDuration:durationIn]))
	{
		delta = deltaIn;
	}
	return self;
}

- (id) initWithUnitsPerSecond:(float) unitsPerSecondIn delta:(ALPoint) deltaIn
{
	if(nil != (self = [super init]))
	{
		delta = deltaIn;
		unitsPerSecond = unitsPerSecondIn;
		if(unitsPerSecond > 0)
		{
			// If unitsPerSecond was set, we use that to calculate duration.  Otherwise just use the current
			// value in duration.
			duration = sqrtf(delta.x * delta.x + delta.y * delta.y + delta.z * delta.z) / unitsPerSecond;
		}
	}
	return self;
}


#pragma mark Properties

@synthesize delta;
@synthesize unitsPerSecond;


#pragma mark Functions

- (void) prepareWithTarget:(id) targetIn
{
	NSAssert([targetIn respondsToSelector:@selector(setPosition:)],
			 @"Target does not respond to selector [setPosition:]");
	
	[super prepareWithTarget:targetIn];

	startPoint = [(id<OAL_PositionProtocol>)targetIn position];
	if(unitsPerSecond > 0)
	{
		// If unitsPerSecond was set, we use that to calculate duration.  Otherwise just use the current
		// value in duration.
		duration = sqrtf(delta.x * delta.x + delta.y * delta.y + delta.z * delta.z) / unitsPerSecond;
	}
}

- (void) updateCompletion:(float) proportionComplete
{
	[(id<OAL_PositionProtocol>)target setPosition:
	 ALPointMake(startPoint.x + delta.x*proportionComplete,
				 startPoint.y + delta.y*proportionComplete,
				 startPoint.z + delta.z*proportionComplete)];
}

@end
