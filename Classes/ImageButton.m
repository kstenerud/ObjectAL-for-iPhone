//
//  ImageButton.m
//
//  Created by Karl Stenerud on 10-05-29.
//

#import "ImageButton.h"


#pragma mark ImageButton

@implementation ImageButton

#pragma mark Object Management

+ (id) buttonWithImageFile:(NSString*) filename target:(id) target selector:(SEL) selector
{
	return [[[self alloc] initWithImageFile:filename target:target selector:selector] autorelease];
}

- (id) initWithImageFile:(NSString*) filename target:(id) targetIn selector:(SEL) selectorIn
{
	CCSprite* sprite = [CCSprite spriteWithFile:filename];
	return [super initWithTouchablePortion:sprite target:targetIn selector:selectorIn];
}

@end
