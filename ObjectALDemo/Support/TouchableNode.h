//
//  TouchableNode.h
//
//  Created by Karl Stenerud on 10-01-21.
//

#import "cocos2d.h"

/**
 * A node that can respond to touches.
 * This code was extracted from CCLayer.
 */
@interface TouchableNode : CCNode <CCStandardTouchDelegate, CCTargetedTouchDelegate>
{
	BOOL isTouchEnabled;
	int touchPriority;
	BOOL targetedTouches;
	BOOL swallowTouches;
	BOOL registeredWithDispatcher;
}
/** Priority position in which this node will be handled (lower = sooner) */
@property(nonatomic,readwrite,assign) int touchPriority;

@property(nonatomic,readwrite,assign) BOOL targetedTouches;
@property(nonatomic,readwrite,assign) BOOL swallowTouches;

/** whether or not it will receive Touch events.
 You can enable / disable touch events with this property.
 Only the touches of this node will be affected. This "method" is not propagated to it's children.
 @since v0.8.1
 */
@property(nonatomic,assign) BOOL isTouchEnabled;

- (BOOL) touchHitsSelf:(UITouch*) touch;
- (BOOL) touch:(UITouch*) touch hitsNode:(CCNode*) node;

@end
