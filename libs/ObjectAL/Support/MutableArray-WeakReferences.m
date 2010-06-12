//
//  MutableArray-WeakReferences.m
//
//  Created by Karl Stenerud on 05/12/09.
//

#import "MutableArray-WeakReferences.h"

@implementation NSMutableArray (WeakReferences)

+ (id) mutableArrayUsingWeakReferencesWithCapacity:(NSUInteger) capacity
{
	CFArrayCallBacks callbacks = {0, NULL, NULL, CFCopyDescription, CFEqual};
	return [(id)(CFArrayCreateMutable(0, capacity, &callbacks)) autorelease];
}

+ (id) mutableArrayUsingWeakReferences
{
	return [self mutableArrayUsingWeakReferencesWithCapacity:0];
}

@end