//
//  Button.m
//
//  Created by Karl Stenerud on 10-01-21.
//

#import "Button.h"

@interface Button ()

@property(nonatomic, readwrite, assign) BOOL touchInProgress;
@property(nonatomic, readwrite, assign) BOOL buttonWasDown;
@property(nonatomic, readwrite, assign) id target;
@property(nonatomic, readwrite, assign) SEL selector;

@end

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
		
		self.touchPriority = 0;
		self.targetedTouches = YES;
		self.swallowTouches = YES;
		self.isTouchEnabled = YES;
		self.scaleOnPush = YES;
		
		self.target = targetIn;
		self.selector = selectorIn;
		
		self.ignoreAnchorPointForPosition = NO;
		self.anchorPoint = ccp(0.5f, 0.5f);

        __block Button* blockSelf = self;

        self.onTouchStart = ^BOOL (CGPoint pos)
        {
            if(!blockSelf.touchInProgress && [blockSelf point:pos hitsNode:blockSelf.touchablePortion])
            {
                blockSelf.touchInProgress = YES;
                blockSelf.buttonWasDown = YES;
                [blockSelf onButtonDown];
                return YES;
            }
            return NO;
        };

        self.onTouchMove =  ^BOOL (CGPoint pos)
        {
            if(blockSelf.touchInProgress)
            {
                if([blockSelf point:pos hitsNode:blockSelf.touchablePortion])
                {
                    if(!blockSelf.buttonWasDown)
                    {
                        [blockSelf onButtonDown];
                    }
                }
                else
                {
                    if(blockSelf.buttonWasDown)
                    {
                        [blockSelf onButtonUp];
                    }
                }
                return YES;
            }
            return NO;
        };

        self.onTouchEnd =  ^BOOL (CGPoint pos)
        {
            if(blockSelf.buttonWasDown)
            {
                [blockSelf onButtonUp];
            }
            if(blockSelf.touchInProgress && [blockSelf point:pos hitsNode:blockSelf.touchablePortion])
            {
                blockSelf.touchInProgress = NO;
                [blockSelf onButtonPressed];
            }
            return NO;
        };

        self.onTouchCancel =  ^BOOL (CGPoint pos)
        {
            if(blockSelf.buttonWasDown)
            {
                [blockSelf onButtonUp];
            }
            blockSelf.touchInProgress = NO;
            return NO;
        };
	}
	return self;
}

- (void) onButtonDown
{
	if(self.scaleOnPush)
	{
		[self.touchablePortion stopAllActions];
		[self.touchablePortion runAction:[CCScaleTo actionWithDuration:0.05f scale:1.2f]];
	}
	self.buttonWasDown = YES;
}

- (void) onButtonUp
{
	if(self.scaleOnPush)
	{
		[self.touchablePortion stopAllActions];
		[self.touchablePortion runAction:[CCScaleTo actionWithDuration:0.01f scale:1.0f]];
	}
	self.buttonWasDown = NO;
}

- (void) onButtonPressed
{
	[self.target performSelector:self.selector withObject:self];
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

- (void) setTouchablePortion:(CCNode *) value
{
	if(nil != _touchablePortion)
	{
		[self removeChild:_touchablePortion cleanup:YES];
	}
	_touchablePortion = value;
	[self addChild:_touchablePortion];
	self.contentSize = _touchablePortion.contentSize;
	_touchablePortion.anchorPoint = ccp(0.5,0.5);
	_touchablePortion.position = ccp(self.contentSize.width/2, self.contentSize.height/2);
}

@end
