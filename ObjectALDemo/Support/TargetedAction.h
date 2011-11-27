//
//  TargetedAction.h
//  MouseMadness
//
//  Created by Karl Stenerud on 09-12-24.
//

#import "cocos2d.h"

/** Overrides the target of an action so that it always runs on the target
 * specified at action creation rather than the one specified by runAction.
 */
@interface TargetedAction : CCActionInterval <NSCopying>
{
	id forcedTarget;
	CCFiniteTimeAction* action;
}
/** This is the target that the action will be forced to run with */
@property(readwrite,retain) id forcedTarget;

/** Create an action with the specified action and forced target */
+ (id) actionWithTarget:(id) target action:(CCFiniteTimeAction*) action;

/** Init an action with the specified action and forced target */
- (id) initWithTarget:(id) target action:(CCFiniteTimeAction*) action;

@end
