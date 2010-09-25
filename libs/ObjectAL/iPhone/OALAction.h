//
//  OALAction.h
//  ObjectAL
//
//  Created by Karl Stenerud on 10-09-18.
//
// Copyright 2009 Karl Stenerud
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
// iPhone application. Including it in your project is sufficient.
//
// Attribution is not required, but appreciated :)
//

#import <Foundation/Foundation.h>
#import "OALFunction.h"
#import "ObjectALConfig.h"


/* There are two versions of the actions which can be used: ObjectAL and Cocos2d.
 * It's usually more convenient when using Cocos2d to have all actions as part of
 * the Cocos2d action system.  You can set this in ObjectALConfig.h
 */
#if !OBJECTAL_USE_COCOS2D_ACTIONS

#pragma mark OALAction (ObjectAL version)

/**
 * Represents an action that can be performed on an object.
 */
@interface OALAction : NSObject
{
	uint64_t startTime;
	id target;
	float duration;
	bool running;
}


#pragma mark Properties

/** The target to perform the action on.  WEAK REFERENCE. */
@property(readonly,nonatomic) id target;

/** The time that the action was started, as per mach_absolute_time() */
@property(readonly,nonatomic) uint64_t startTime;

/** The duration of the action, in seconds. */
@property(readonly,nonatomic) float duration;

/** If true, the action is currently running. */
@property(readonly,nonatomic) bool running;


#pragma mark Object Management

/** Initialize an action.
 *
 * @param duration The duration of this action in seconds.
 * @return The initialized action.
 */
- (id) initWithDuration:(float) duration;


#pragma mark Functions

/** Run this action on a target.
 *
 * @param target The target to run the action on.
 */
- (void) runWithTarget:(id) target;

/** Called by OALActionManager to update this action's progress.
 *
 * @param proportionComplete The proportion of this action's duration that has elapsed.
 */
- (void) update:(float) proportionComplete;

/** Stop this action.
 */
- (void) stop;

@end


#else /* !OBJECTAL_USE_COCOS2D_ACTIONS */


#import "cocos2d.h"

#pragma mark -
#pragma mark OALAction (Cocos2d version)

/**
 * OALAction as a subclass of CCIntervalAction.
 *
 * This version of OALAction gets used if you enabled OBJECTAL_USE_COCOS2D_ACTIONS in ObjectALConfig.
 * @see OBJECTAL_USE_COCOS2D_ACTIONS
 */
@interface OALAction: CCIntervalAction
{
	/** If YES, this action has been started. */
	bool started;
}


#pragma mark Properties

/** If YES, this action is currently running. */
@property(readonly,nonatomic) bool running;


#pragma mark Functions

/** Run this action on a target.
 *
 * @param target The target to run the action on.
 */
- (void) runWithTarget:(id) target;

@end

#endif /* !OBJECTAL_USE_COCOS2D_ACTIONS */


#pragma mark -
#pragma mark OALFunctionAction

/**
 * An action that applies a function to the proportionComplete parameter in
 * [update] before applying the result to the target.
 * This allows things like exponential and s-curve functions when applying gain
 * transitions, for example.
 */
@interface OALFunctionAction: OALAction
{
	float startValue;
	float endValue;
	/** The lowest value that will ever be set over the course of this function. */
	float lowValue;
	/** The difference between the lowest and highest value. */
	float delta;
	id<OALFunction,NSObject> function;
	/** The reverse function, if any.  When this is not null, the reverse function is used. */
	OALReverseFunction* reverseFunction;
	/** The basic function that will be applied normally, or reversed. */
	id<OALFunction,NSObject> realFunction;
}


#pragma mark Properties

/** The function that will be applied. */
@property(readwrite,retain,nonatomic) id<OALFunction,NSObject> function;

/** The value that the property in the target will hold at the start of the action. */
@property(readwrite,assign,nonatomic) float startValue;

/** The value that the property in the target will hold at the end of the action. */
@property(readwrite,assign,nonatomic) float endValue;


#pragma mark Object Management

/** Create a new action using the default function.
 * The start value will be the current value of the target this action is applied to.
 *
 * @param duration The duration of this action in seconds.
 * @param endValue The "ending" value that this action will converge upon when setting the target's property.
 * @return A new action.
 */
+ (id) actionWithDuration:(float) duration endValue:(float) endValue;

/** Create a new action.
 * The start value will be the current value of the target this action is applied to.
 *
 * @param duration The duration of this action in seconds.
 * @param endValue The "ending" value that this action will converge upon when setting the target's property.
 * @param function The function to apply in this action's update method.
 * @return A new action.
 */
+ (id) actionWithDuration:(float) duration
				 endValue:(float) endValue
				 function:(id<OALFunction,NSObject>) function;

/** Create a new action.
 *
 * @param duration The duration of this action in seconds.
 * @param startValue The "starting" value that this action will diverge from when setting the target's
 *                   property.
 * @param endValue The "ending" value that this action will converge upon when setting the target's property.
 * @param function The function to apply in this action's update method.
 * @return A new action.
 */
+ (id) actionWithDuration:(float) duration
			   startValue:(float) startValue
				 endValue:(float) endValue
				 function:(id<OALFunction,NSObject>) function;

/** Initialize an action using the default function.
 * The start value will be the current value of the target this action is applied to.
 *
 * @param duration The duration of this action in seconds.
 * @param endValue The "ending" value that this action will converge upon when setting the target's property.
 * @return The initialized action.
 */
- (id) initWithDuration:(float) duration endValue:(float) endValue;

/** Initialize an action.
 * The start value will be the current value of the target this action is applied to.
 *
 * @param duration The duration of this action in seconds.
 * @param endValue The "ending" value that this action will converge upon when setting the target's property.
 * @param function The function to apply in this action's update method.
 * @return The initialized action.
 */
- (id) initWithDuration:(float) duration
			   endValue:(float) endValue
			   function:(id<OALFunction,NSObject>) function;

/** Initialize an action.
 *
 * @param duration The duration of this action in seconds.
 * @param startValue The "starting" value that this action will diverge from when setting the target's
 *                   property.
 * @param endValue The "ending" value that this action will converge upon when setting the target's property.
 * @param function The function to apply in this action's update method.
 * @return The initialized action.
 */
- (id) initWithDuration:(float) duration
			 startValue:(float) startValue
			   endValue:(float) endValue
			   function:(id<OALFunction,NSObject>) function;


#pragma mark Utility

/** Get the function that this action would use by default if none was specified. */
+ (id<OALFunction,NSObject>) defaultFunction;


@end


#pragma mark -
#pragma mark OALGainAction

/**
 * A function-based action that modifies the target's gain.
 * The target's gain is assumed to be a float, accepting values from 0.0 (no sound)
 * to 1.0 (max gain).
 */
@interface OALGainAction: OALFunctionAction
{
}

@end


#pragma mark -
#pragma mark OALPitchAction

/**
 * A function-based action that modifies the target's pitch.
 * The target's pitch is assumed to be a float, with 1.0 representing
 * normal pitch, and lower values giving lower pitch.
 */
@interface OALPitchAction: OALFunctionAction
{
}

@end


#pragma mark -
#pragma mark OALPanAction

/**
 * A function-based action that modifies the target's pan.
 * The target's pan is assumed to be a float, accepting values from -1.0 (max left)
 * to 1.0 (max right).
 */
@interface OALPanAction: OALFunctionAction
{
}

@end
