//
//  CCNode+ContentSize.h
//  ObjectAL
//
//  Created by Karl Stenerud on 10-09-19.
//

#import "cocos2d.h"

@interface CCNode (ContentSize)

- (void) setContentSizeFromChildren;

- (CGSize) minimalDimensionsForChildren;

@end
