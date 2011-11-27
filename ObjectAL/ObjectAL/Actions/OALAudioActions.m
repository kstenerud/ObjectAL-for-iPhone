//
//  OALAudioActions.m
//  ObjectAL
//
//  Created by Karl Stenerud on 10-10-10.
//
//  Copyright (c) 2009 Karl Stenerud. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall remain in place
// in this source code.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
// Attribution is not required, but appreciated :)
//

#import "OALAudioActions.h"
#import "ObjectALMacros.h"


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
	return arcsafe_autorelease([(OALPlaceAction*)[self alloc] initWithPosition:position]);
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
	return arcsafe_autorelease([(OALMoveToAction*)[self alloc] initWithDuration:duration position:position]);
}

+ (id) actionWithUnitsPerSecond:(float) unitsPerSecond position:(ALPoint) position
{
	return arcsafe_autorelease([[self alloc] initWithUnitsPerSecond:unitsPerSecond position:position]);
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
	return arcsafe_autorelease([[self alloc] initWithDuration:duration delta:delta]);
}

+ (id) actionWithUnitsPerSecond:(float) unitsPerSecond delta:(ALPoint) delta
{
	return arcsafe_autorelease([[self alloc] initWithUnitsPerSecond:unitsPerSecond delta:delta]);
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
