//
//  OALAudioActions.h
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
#import "ALTypes.h"


#pragma mark OALGainAction

/**
 * A function-based action that modifies the target's gain.
 * The target's gain poperty is assumed to be a float, accepting values
 * from 0.0 (no sound) to 1.0 (max gain).
 */
@interface OALGainAction: OALFunctionAction
{
}

@end


#pragma mark -
#pragma mark OALPitchAction

/**
 * A function-based action that modifies the target's pitch.
 * The target's pitch property is assumed to be a float, with
 * 1.0 representing normal pitch, and lower values giving lower pitch.
 */
@interface OALPitchAction: OALFunctionAction
{
}

@end


#pragma mark -
#pragma mark OALPanAction

/**
 * A function-based action that modifies the target's pan.
 * The target's pan property is assumed to be a float, accepting values
 * from -1.0 (max left) to 1.0 (max right).
 */
@interface OALPanAction: OALFunctionAction
{
}

@end


#pragma mark -
#pragma mark OALPlaceAction

/**
 * Places the target at the specified position.
 */
@interface OALPlaceAction : OALAction
{
	ALPoint position;
}


#pragma mark Properties

/** The position where the target will be placed. */
@property(readwrite,assign,nonatomic) ALPoint position;


#pragma mark Object Management

/** Create an action with the specified position.
 *
 * @param position The position to place the target at.
 * @return A new action.
 */
+ (id) actionWithPosition:(ALPoint) position;

/** Initialize an action with the specified position.
 *
 * @param position The position to place the target at.
 * @return The initialized action.
 */
- (id) initWithPosition:(ALPoint) position;

@end


#pragma mark -
#pragma mark OALMoveToAction

/**
 * Moves the target from its current position to the specified
 * position over time in 3D space.
 */
@interface OALMoveToAction : OALAction
{
	float unitsPerSecond;
	
	/** The point this move is starting at. */
	ALPoint startPoint;
	ALPoint position;
	
	/** The distance being moved. */
	ALPoint delta;
}

#pragma mark Properties

/** The position to move the target to. */
@property(readwrite,assign,nonatomic) ALPoint position;

/** The speed at which to move the target.
 * If this is 0, the target will be moved at the speed determined by duration.
 */
@property(readwrite,assign,nonatomic) float unitsPerSecond;


#pragma mark Object Management

/** Create a new action.
 *
 * @param duration The duration of the move.
 * @param position The position to move to.
 * @return A new action.
 */
+ (id) actionWithDuration:(float) duration position:(ALPoint) position;

/** Create a new action.
 *
 * @param unitsPerSecond The rate of movement.
 * @param position The position to move to.
 * @return A new action.
 */
+ (id) actionWithUnitsPerSecond:(float) unitsPerSecond position:(ALPoint) position;

/** Initialize an action.
 *
 * @param duration The duration of the move.
 * @param position The position to move to.
 * @return The initialized action.
 */
- (id) initWithDuration:(float) duration position:(ALPoint) position;

/** Initialize an action.
 *
 * @param unitsPerSecond The rate of movement.
 * @param position The position to move to.
 * @return The initialized action.
 */
- (id) initWithUnitsPerSecond:(float) unitsPerSecond position:(ALPoint) position;

@end


#pragma mark -
#pragma mark OALMoveByAction

/**
 * Moves the target from its current position by the specified
 * delta over time in 3D space.
 */
@interface OALMoveByAction : OALAction
{
	float unitsPerSecond;
	
	/** The point this move is starting at. */
	ALPoint startPoint;
	ALPoint delta;
}

#pragma mark Properties

/** The amount to move the target by. */
@property(readwrite,assign,nonatomic) ALPoint delta;

/** The speed at which to move the target.
 * If this is 0, the target will be moved at the speed determined by duration.
 */
@property(readwrite,assign,nonatomic) float unitsPerSecond;

/** Create a new action.
 *
 * @param duration The duration of the move.
 * @param delta The amount to move by.
 * @return A new action.
 */
+ (id) actionWithDuration:(float) duration delta:(ALPoint) delta;

/** Create a new action.
 *
 * @param unitsPerSecond The rate of movement.
 * @param delta The amount to move by.
 * @return A new action.
 */
+ (id) actionWithUnitsPerSecond:(float) unitsPerSecond delta:(ALPoint) delta;

/** Initialize an action.
 *
 * @param duration The duration of the move.
 * @param delta The amount to move by.
 * @return The initialized action.
 */
- (id) initWithDuration:(float) duration delta:(ALPoint) delta;

/** Initialize an action.
 *
 * @param unitsPerSecond The rate of movement.
 * @param delta The amount to move by.
 * @return The initialized action.
 */
- (id) initWithUnitsPerSecond:(float) unitsPerSecond delta:(ALPoint) delta;

@end
