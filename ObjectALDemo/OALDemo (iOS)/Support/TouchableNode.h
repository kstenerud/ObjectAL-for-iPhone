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
@interface TouchableNode : CCNode
#ifdef __CC_PLATFORM_IOS
    <CCTouchOneByOneDelegate, CCTouchAllAtOnceDelegate>
#elif defined(__CC_PLATFORM_MAC)
    <CCKeyboardEventDelegate, CCMouseEventDelegate, CCTouchEventDelegate>
#endif
/** Priority position in which this node will be handled (lower = sooner) */
@property(nonatomic,readwrite,assign) int touchPriority;

@property(nonatomic,readwrite,assign) BOOL targetedTouches;
@property(nonatomic,readwrite,assign) BOOL swallowTouches;

@property(nonatomic,readwrite,assign) BOOL isTouchEnabled;

#ifdef __CC_PLATFORM_IOS
- (BOOL) touchHitsSelf:(UITouch*) touch;
- (BOOL) touch:(UITouch*) touch hitsNode:(CCNode*) node;
#elif defined(__CC_PLATFORM_MAC)
- (BOOL) eventHitsSelf:(NSEvent *)event;
- (BOOL) event:(NSEvent *)event hitsNode:(CCNode*) node;
#endif

- (BOOL) pointHitsSelf:(CGPoint) point;
- (BOOL) point:(CGPoint) point hitsNode:(CCNode*) node;

@end

#if defined(__CC_PLATFORM_MAC)
@interface CCNode (ConvertEventToNodeSpace)

- (CGPoint) convertEventToNodeSpace:(NSEvent *)event;

@end
#endif


typedef BOOL (^TouchEvent)(CGPoint location);

@interface SingleTouchableNode : TouchableNode

@property(nonatomic, readwrite, copy) TouchEvent onTouchStart;
@property(nonatomic, readwrite, copy) TouchEvent onTouchMove;
@property(nonatomic, readwrite, copy) TouchEvent onTouchEnd;
@property(nonatomic, readwrite, copy) TouchEvent onTouchCancel;

@end
