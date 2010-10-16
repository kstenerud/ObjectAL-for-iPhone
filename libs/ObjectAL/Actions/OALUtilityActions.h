//
//  OALUtilityActions.h
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

#import "OALAction.h"


#pragma mark OALTargetedAction

/**
 * Ignores whatever target it was invoked upon and applies the specified action
 * on the target specified at creation time.
 */
@interface OALTargetedAction: OALAction
{
	id forcedTarget;
	
	/** The action that will be run on the target. */
	OALAction* action;
}

/** The target which this action will actually be invoked upon. */
@property(readwrite,assign,nonatomic) id forcedTarget;

/** Create an action.
 *
 * @param target The target to run the action upon.
 * @param action The action to run.
 * @return A new action.
 */
+ (id) actionWithTarget:(id) target action:(OALAction*) action;

/** Initialize an action.
 *
 * @param target The target to run the action upon.
 * @param action The action to run.
 * @return The initialized action.
 */
- (id) initWithTarget:(id) target action:(OALAction*) action;

@end


#if !OBJECTAL_USE_COCOS2D_ACTIONS

#pragma mark -
#pragma mark OALSequentialActions

/**
 * A set of actions that get run in sequence.
 */
@interface OALSequentialActions: OALAction
{
	NSMutableArray* actions;
	
	/** The durations of the actions. */
	NSMutableArray* pDurations;

	/** The index of the action currently being processed. */
	uint actionIndex;
	
	/** The last completeness proportion value acted upon. */
	float pLastComplete;

	/** The current action being processed. */
	OALAction* currentAction;
	
	/** The proportional duration of the current action. */
	float pCurrentActionDuration;
	
	/** The proportional completeness of the current action. */
	float pCurrentActionComplete;
}


#pragma mark Properties

/** The actions which will be run. */
@property(readwrite,retain,nonatomic) NSMutableArray* actions;


#pragma mark Object Management

/** Create an action.
 *
 * @param actions The comma separated list of actions.
 * @param NS_REQUIRES_NIL_TERMINATION List of actions must be terminated by a nil.
 * @return A new set of sequential actions.
 */
+ (id) actions:(OALAction*) actions, ... NS_REQUIRES_NIL_TERMINATION;

/** Create an action.
 *
 * @param actions The actions to run.
 * @return A new set of sequential actions.
 */
+ (id) actionsFromArray:(NSArray*) actions;

/** Initialize an action.
 *
 * @param actions The actions to run.
 * @return The initialized set of sequential actions.
 */
- (id) initWithActions:(NSArray*) actions;

@end


#pragma mark -
#pragma mark OALConcurrentActions

/**
 * A set of actions that get run concurrently.
 */
@interface OALConcurrentActions: OALAction
{
	NSMutableArray* actions;
	
	/** The durations of the actions. */
	NSMutableArray* pDurations;

	/** A list of actions that have duration > 0. */
	NSMutableArray* actionsWithDuration;
}


#pragma mark Properties

/** The actions which will be run. */
@property(readwrite,retain,nonatomic) NSMutableArray* actions;


#pragma mark Object Management

/** Create an action.
 *
 * @param actions The comma separated list of actions.
 * @param NS_REQUIRES_NIL_TERMINATION List of actions must be terminated by a nil.
 * @return A new set of concurrent actions.
 */
+ (id) actions:(OALAction*) actions, ... NS_REQUIRES_NIL_TERMINATION;

/** Create an action.
 *
 * @param actions The actions to run.
 * @return A new set of concurrent actions.
 */
+ (id) actionsFromArray:(NSArray*) actions;

/** Initialize an action.
 *
 * @param actions The actions to run.
 * @return The initialized set of concurrent actions.
 */
- (id) initWithActions:(NSArray*) actions;

@end

#else /* !OBJECTAL_USE_COCOS2D_ACTIONS */

COCOS2D_SUBCLASS_HEADER(OALSequentialActions,CCSequence);


COCOS2D_SUBCLASS_HEADER(OALConcurrentActions,CCSpawn);

#endif /* !OBJECTAL_USE_COCOS2D_ACTIONS */


#pragma mark -
#pragma mark OALCallAction

/**
 * Calls a selector on a target.
 * This action will ignore whatever target it is run against,
 * and will invoke the selector on the target specified at creation
 * time.
 */
@interface OALCallAction: OALAction
{
	/** The target to call the selector on. */
	id callTarget;
	
	/** The selector to invoke */
	SEL selector;
	
	/** The number of parameters which will be passed to the selector. */
	int numObjects;
	
	/** The first object to pass to the selector, if any. */
	id object1;
	
	/** The second object to pass to the selector, if any. */
	id object2;
}

/** Create an action.
 *
 * @param callTarget The target to call.
 * @param selector The selector to invoke.
 * @return A new action.
 */
+ (id) actionWithCallTarget:(id) callTarget
				   selector:(SEL) selector;

/** Create an action.
 *
 * @param callTarget The target to call.
 * @param selector The selector to invoke.
 * @param object The object to pass to the selector.
 * @return A new action.
 */
+ (id) actionWithCallTarget:(id) callTarget
				   selector:(SEL) selector
				 withObject:(id) object;

/** Create an action.
 *
 * @param callTarget The target to call.
 * @param selector The selector to invoke.
 * @param firstObject The first object to pass to the selector.
 * @param secondObject The second object to pass to the selector.
 * @return A new action.
 */
+ (id) actionWithCallTarget:(id) callTarget
				   selector:(SEL) selector
				 withObject:(id) firstObject
				 withObject:(id) secondObject;

/** Initialize an action.
 *
 * @param callTarget The target to call.
 * @param selector The selector to invoke.
 * @return The initialized action.
 */
- (id) initWithCallTarget:(id) callTarget
				 selector:(SEL) selector;

/** Initialize an action.
 *
 * @param callTarget The target to call.
 * @param selector The selector to invoke.
 * @param object The object to pass to the selector.
 * @return Initialize an action.
 */
- (id) initWithCallTarget:(id) callTarget
				 selector:(SEL) selector
			   withObject:(id) object;

/** Initialize an action.
 *
 * @param callTarget The target to call.
 * @param selector The selector to invoke.
 * @param firstObject The first object to pass to the selector.
 * @param secondObject The second object to pass to the selector.
 * @return The initialized action.
 */
- (id) initWithCallTarget:(id) callTarget
				 selector:(SEL) selector
			   withObject:(id) firstObject
			   withObject:(id) secondObject;

@end
