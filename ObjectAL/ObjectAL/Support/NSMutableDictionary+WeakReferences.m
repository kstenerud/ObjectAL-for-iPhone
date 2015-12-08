//
//  NSMutableDictionary+WeakReferences.m
//
//  Created by Karl Stenerud on 12-09-06.
//

#import "NSMutableDictionary+WeakReferences.h"


@implementation NSMutableDictionary (WeakReferences)

+ (NSMutableDictionary*) newMutableDictionaryUsingWeakReferencesWithCapacity:(NSUInteger) capacity
{
	CFDictionaryValueCallBacks callbacks = {0, NULL, NULL, CFCopyDescription, CFEqual};
    return (__bridge_transfer id)CFDictionaryCreateMutable(NULL,
                                                            (CFIndex)capacity,
                                                            &kCFTypeDictionaryKeyCallBacks,
                                                            &callbacks);
}

+ (NSMutableDictionary*) newMutableDictionaryUsingWeakReferences
{
	return [self newMutableDictionaryUsingWeakReferencesWithCapacity:0];
}

+ (NSMutableDictionary*) mutableDictionaryUsingWeakReferencesWithCapacity:(NSUInteger) capacity
{
    return [self newMutableDictionaryUsingWeakReferencesWithCapacity:capacity];
}

+ (NSMutableDictionary*) mutableDictionaryUsingWeakReferences
{
	return [self mutableDictionaryUsingWeakReferencesWithCapacity:0];
}

@end

#define FIX_CATEGORY_BUG(name) @interface FIX_CATEGORY_BUG_##name : NSObject @end @implementation FIX_CATEGORY_BUG_##name @end


FIX_CATEGORY_BUG(NSMutableDictionary_WeakReferences);
