//
//  OALAction.h
//  ObjectAL
//
//  Created by Karl Stenerud on 10-09-18.
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

#import <Foundation/Foundation.h>
#import "OALFunction.h"
#import "ObjectALConfig.h"


#if OBJECTAL_USE_COCOS2D_ACTIONS

#pragma mark Cocos2d Subclassing

#import "cocos2d.h"

/** Generates common code required to subclass from a cocos2d action
 * while maintaining the functionality of an OALAction.
 */
#define COCOS2D_SUBCLASS_HEADER(CLASS_A,CLASS_B)	\
@interface CLASS_A: CLASS_B	\
{	\
	bool started;	\
}	\
	\
@property(readonly,nonatomic) bool running;	\
- (void) runWithTarget:(id) target;	\
- (void) prepareWithTarget:(id) target;	\
- (void) stopAction;	\
- (void) updateCompletion:(float) proportionComplete;	\
	\
@end



/** Generates common code required to subclass from a cocos2d action
 * while maintaining the functionality of an OALAction.
 */
#define COCOS2D_SUBCLASS(CLASS_A)	\
@implementation CLASS_A	\
	\
- (id) init	\
{	\
	return [self initWithDuration:0];	\
}	\
	\
-(void) startWithTarget:(id) targetIn	\
{	\
	[super startWithTarget:targetIn];	\
	[self prepareWithTarget:targetIn];	\
	started = YES;	\
	[self runWithTarget:targetIn];	\
}	\
	\
- (void) update:(float) proportionComplete	\
{	\
	[super update:proportionComplete];	\
	[self updateCompletion:proportionComplete];	\
}	\
	\
- (bool) running	\
{	\
	return !self.isDone;	\
}	\
	\
- (void) runWithTarget:(id) targetIn	\
{	\
	if(!started)	\
	{	\
		[[CCActionManager sharedManager] addAction:self target:targetIn paused:NO];	\
	}	\
}	\
	\
- (void) stopAction	\
{	\
	[[CCActionManager sharedManager] removeAction:self];	\
}	\

#endif /* OBJECTAL_USE_COCOS2D_ACTIONS */



/* There are two versions of the actions which can be used: ObjectAL and Cocos2d.
 * It's usually more convenient when using Cocos2d to have all actions as part of
 * the Cocos2d action system.  You can set this in ObjectALConfig.h
 */
#if !OBJECTAL_USE_COCOS2D_ACTIONS

#pragma mark -
#pragma mark OALAction (ObjectAL version)

/**
 * Represents an action that can be performed on an object.
 */
@interface OALAction : NSObject
{
    /** The target to perform the action on */
	id target;
	float duration;
	float elapsed;
	bool running;
	
	/** If TRUE, this action is running via OALActionManager. */
	bool runningInManager;
}


#pragma mark Properties

/** The target to perform the action on.  WEAK REFERENCE. */
@property(readonly,nonatomic) id target;

/** The duration of the action, in seconds. */
@property(readonly,nonatomic) float duration;

/** The amount of time that has elapsed for this action, in seconds. */
@property(readwrite,nonatomic) float elapsed;

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

/** Called by runWithTraget to do any final preparations before running.
 * Subclasses must ensure that duration is valid when this method returns.
 *
 * @param target The target to run the action on.
 */
- (void) prepareWithTarget:(id) target;


/** Called by runWithTarget to start the action running.
 */
- (void) startAction;

/** Called by OALActionManager to update this action's progress.
 *
 * @param proportionComplete The proportion of this action's duration that has elapsed.
 */
- (void) updateCompletion:(float) proportionComplete;

/** Stop this action.
 */
- (void) stopAction;

@end


#else /* !OBJECTAL_USE_COCOS2D_ACTIONS */

COCOS2D_SUBCLASS_HEADER(OALAction, CCIntervalAction);

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
	/** The reverse function, if any. When this is not null, the reverse function is used. */
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
 *                   property. If NAN, use the current value from the target.
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
 *                   property. If NAN, use the current value from the target.
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
