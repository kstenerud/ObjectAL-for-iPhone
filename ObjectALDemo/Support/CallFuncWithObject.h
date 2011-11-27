//
//  CallFuncWithObject.h
//  ObjectAL
//
//  Created by Karl Stenerud.
//

#import "cocos2d.h"


@interface CallFuncWithObject : CCCallFunc
{
	id object;
	id object2;
	bool twoObjects;
}

+ (id) actionWithTarget:(id)target
			   selector:(SEL)selector
				 object:(id) object;

+ (id) actionWithTarget:(id)target
			   selector:(SEL)selector
				 object:(id) object
				 object:(id) object2;

- (id) initWithTarget:(id)target
			 selector:(SEL)selector
			   object:(id) object;

- (id) initWithTarget:(id)target
			 selector:(SEL)selector
			   object:(id) object
			   object:(id) object2;

@end
