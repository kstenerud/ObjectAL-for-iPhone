//
//  Button.m
//
//  Created by Karl Stenerud on 10-01-21.
//

#import "Button.h"


#pragma mark Button

@implementation Button

#pragma mark Object Management

+ (id) buttonWithTouchablePortion:(CCNode*) node target:(id) target selector:(SEL) selector
{
	return [[[self alloc] initWithTouchablePortion:node target:target selector:selector] autorelease];
}

- (id) initWithTouchablePortion:(CCNode*) node target:(id) targetIn selector:(SEL) selectorIn;
{
	if(nil != (self = [super init]))
	{
		self.touchablePortion = node;
		
		node.anchorPoint = ccp(0.5f, 0.5f);
		node.position = ccp(node.contentSize.width*0.5f, node.contentSize.height*0.5f);
		
		touchPriority = 0;
		targetedTouches = YES;
		swallowTouches = YES;
		isTouchEnabled = YES;
		scaleOnPush = YES;
		
		target = targetIn;
		selector = selectorIn;
		
		self.isRelativeAnchorPoint = YES;
		self.anchorPoint = ccp(0.5f, 0.5f);
	}
	return self;
}

#pragma mark Event Handlers

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	if([self touch:touch hitsNode:touchablePortion])
	{
		touchInProgress = YES;
		buttonWasDown = YES;
		[self onButtonDown];
		return YES;
	}
	return NO;
}

-(void) ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{	
	if(touchInProgress)
	{
		if([self touch:touch hitsNode:touchablePortion])
		{
			if(!buttonWasDown)
			{
				[self onButtonDown];
			}
		}
		else
		{
			if(buttonWasDown)
			{
				[self onButtonUp];
			}
		}
	}
}

-(void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{	
	if(buttonWasDown)
	{
		[self onButtonUp];
	}
	if(touchInProgress && [self touch:touch hitsNode:touchablePortion])
	{
		touchInProgress = NO;
		[self onButtonPressed];
	}
}

-(void) ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
	if(buttonWasDown)
	{
		[self onButtonUp];
	}
	touchInProgress = NO;
}

- (void) onButtonDown
{
	if(scaleOnPush)
	{
		[touchablePortion stopAllActions];
		[touchablePortion runAction:[CCScaleTo actionWithDuration:0.05f scale:1.2f]];
	}
	buttonWasDown = YES;
}

- (void) onButtonUp
{
	if(scaleOnPush)
	{
		[touchablePortion stopAllActions];
		[touchablePortion runAction:[CCScaleTo actionWithDuration:0.01f scale:1.0f]];
	}
	buttonWasDown = NO;
}

- (void) onButtonPressed
{
	[target performSelector:selector withObject:self];
}

#pragma mark Properties

- (GLubyte) opacity
{
	for(CCNode* child in self.children)
	{
		if([child conformsToProtocol:@protocol(CCRGBAProtocol)])
		{
			return ((id<CCRGBAProtocol>)child).opacity;
		}
	}
	return 255;
}

- (void) setOpacity:(GLubyte) value
{
	for(CCNode* child in self.children)
	{
		if([child conformsToProtocol:@protocol(CCRGBAProtocol)])
		{
			[((id<CCRGBAProtocol>)child) setOpacity:value];
		}
	}
}

- (ccColor3B) color
{
	for(CCNode* child in self.children)
	{
		if([child conformsToProtocol:@protocol(CCRGBAProtocol)])
		{
			return ((id<CCRGBAProtocol>)child).color;
		}
	}
	return ccWHITE;
}

- (void) setColor:(ccColor3B) value
{
	for(CCNode* child in self.children)
	{
		if([child conformsToProtocol:@protocol(CCRGBAProtocol)])
		{
			[((id<CCRGBAProtocol>)child) setColor:value];
		}
	}
}

@synthesize scaleOnPush;
@synthesize touchablePortion;

- (void) setTouchablePortion:(CCNode *) value
{
	if(nil != touchablePortion)
	{
		[self removeChild:touchablePortion cleanup:YES];
	}
	touchablePortion = value;
	[self addChild:touchablePortion];
	self.contentSize = touchablePortion.contentSize;
	touchablePortion.anchorPoint = ccp(0,0);
	touchablePortion.position = ccp(0,0);
}

@end
