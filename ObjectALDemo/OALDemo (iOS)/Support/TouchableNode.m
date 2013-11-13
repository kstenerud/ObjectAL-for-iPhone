//
//  TouchableNode.m
//
//  Created by Karl Stenerud on 10-01-21.
//

#import "TouchableNode.h"

@interface TouchableNode ()

@property(nonatomic,readwrite,assign) BOOL registeredWithDispatcher;

@end

@implementation TouchableNode

@synthesize isTouchEnabled;
@synthesize touchPriority;
@synthesize targetedTouches;
@synthesize swallowTouches;
@synthesize registeredWithDispatcher;

- (void) dealloc
{
	[self unregisterWithTouchDispatcher];
	
	[super dealloc];
}

-(void) registerWithTouchDispatcher
{
	[self unregisterWithTouchDispatcher];
	
#ifdef __CC_PLATFORM_IOS
	if(targetedTouches)
	{
		[[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:touchPriority swallowsTouches:swallowTouches];
	}
	else 
	{
		[[[CCDirector sharedDirector] touchDispatcher] addStandardDelegate:self priority:touchPriority];
	}
#elif defined(__CC_PLATFORM_MAC)
    [[[CCDirector sharedDirector] eventDispatcher] addMouseDelegate:self priority:touchPriority];
#endif
	registeredWithDispatcher = YES;
}

- (void) unregisterWithTouchDispatcher
{
	if(registeredWithDispatcher)
	{
#ifdef __CC_PLATFORM_IOS
		[[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
#elif defined(__CC_PLATFORM_MAC)
        [[[CCDirector sharedDirector] eventDispatcher] removeMouseDelegate:self];
#endif
		registeredWithDispatcher = NO;
	}
}

- (void) setTargetedTouches:(BOOL) value
{
	if(targetedTouches != value)
	{
		targetedTouches = value;
		
		if(_isRunning && isTouchEnabled)
		{
			[self registerWithTouchDispatcher];
		}
	}
}

- (void) setSwallowTouches:(BOOL) value
{
	if(swallowTouches != value)
	{
		swallowTouches = value;
		
		if(_isRunning && isTouchEnabled)
		{
			[self registerWithTouchDispatcher];
		}
	}
}

- (void) setTouchPriority:(int) value
{
	if(touchPriority != value)
	{
		touchPriority = value;
		if(_isRunning && isTouchEnabled)
		{
			[self registerWithTouchDispatcher];
		}
	}
}

-(void) setIsTouchEnabled:(BOOL)enabled
{
	if( isTouchEnabled != enabled )
	{
		isTouchEnabled = enabled;
		if( _isRunning )
		{
			if( isTouchEnabled )
			{
				[self registerWithTouchDispatcher];
			}
			else
			{
				[self unregisterWithTouchDispatcher];
			}
		}
	}
}

- (void)cleanup
{
	self.isTouchEnabled = NO;
}

#pragma mark TouchableNode - Callbacks
-(void) onEnter
{
	// register 'parent' nodes first
	// since events are propagated in reverse order
	if (isTouchEnabled)
	{
		[self registerWithTouchDispatcher];
	}
	
	// then iterate over all the children
	[super onEnter];
}

-(void) onExit
{
	if(isTouchEnabled)
	{
		[self unregisterWithTouchDispatcher];
	}
	
	[super onExit];
}

- (BOOL) pointHitsSelf:(CGPoint) point
{
    return [self point:point hitsNode:self];
}

- (BOOL) point:(CGPoint) point hitsNode:(CCNode*) node
{
	CGRect r = CGRectMake(0, 0, node.contentSize.width, node.contentSize.height);
	return CGRectContainsPoint(r, point);
}

#ifdef __CC_PLATFORM_IOS

-(BOOL) ccTouchBegan:(__unused UITouch *)touch withEvent:(__unused UIEvent *)event
{
	NSAssert(NO, @"TouchableNode#ccTouchBegan override me");
	return YES;
}

- (void)ccTouchesBegan:(__unused NSSet *)touches withEvent:(__unused UIEvent *)event
{
	NSAssert(NO, @"TouchableNode#ccTouchesBegan override me");
}

- (BOOL) touchHitsSelf:(UITouch*) touch
{
	return [self touch:touch hitsNode:self];
}

- (BOOL) touch:(UITouch*) touch hitsNode:(CCNode*) node
{
    return [self point:[node convertTouchToNodeSpace:touch] hitsNode:node];
}

#elif defined(__CC_PLATFORM_MAC)

- (BOOL) eventHitsSelf:(NSEvent *)event
{
	return [self event:event hitsNode:self];
}

- (BOOL) event:(NSEvent *)event hitsNode:(CCNode*) node
{
    return [self point:[node convertEventToNodeSpace:event] hitsNode:node];
}

#endif

@end


#if defined(__CC_PLATFORM_MAC)

@implementation CCNode (ConvertEventToNodeSpace)

- (CGPoint) convertEventToNodeSpace:(NSEvent *)event
{
    return [self convertToNodeSpace:[[CCDirector sharedDirector] convertEventToGL:event]];
}

@end

#endif


@implementation SingleTouchableNode

- (void) dealloc
{
    [_onTouchStart release];
    [_onTouchMove release];
    [_onTouchEnd release];
    [_onTouchCancel release];
    [super dealloc];
}

#ifdef __CC_PLATFORM_IOS

-(void) ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self ccTouchBegan:[touches anyObject] withEvent:event];
}

-(void) ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self ccTouchMoved:[touches anyObject] withEvent:event];
}

-(void) ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self ccTouchEnded:[touches anyObject] withEvent:event];
}

-(void) ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self ccTouchCancelled:[touches anyObject] withEvent:event];
}

-(BOOL) ccTouchBegan:(__unused UITouch *)touch withEvent:(__unused UIEvent *)event
{
    if(self.onTouchStart)
    {
        return self.onTouchStart([self convertTouchToNodeSpace:touch]);
    }
    return NO;
}

-(void) ccTouchMoved:(__unused UITouch *)touch withEvent:(__unused UIEvent *)event
{
    if(self.onTouchMove)
    {
        self.onTouchMove([self convertTouchToNodeSpace:touch]);
    }
}

-(void) ccTouchEnded:(__unused UITouch *)touch withEvent:(__unused UIEvent *)event
{
    if(self.onTouchEnd)
    {
        self.onTouchEnd([self convertTouchToNodeSpace:touch]);
    }
}

-(void) ccTouchCancelled:(__unused UITouch *)touch withEvent:(__unused UIEvent *)event
{
    if(self.onTouchCancel)
    {
        self.onTouchCancel([self convertTouchToNodeSpace:touch]);
    }
}

#elif defined(__CC_PLATFORM_MAC)

-(BOOL) ccMouseDown:(NSEvent *)event
{
    if(self.onTouchStart)
    {
        return self.onTouchStart([self convertEventToNodeSpace:event]);
    }
    return NO;
}

-(BOOL) ccMouseDragged:(NSEvent *)event
{
    if(self.onTouchMove)
    {
        return self.onTouchMove([self convertEventToNodeSpace:event]);
    }
    return NO;
}

-(BOOL) ccMouseUp:(NSEvent *)event
{
    if(self.onTouchEnd)
    {
        return self.onTouchEnd([self convertEventToNodeSpace:event]);
    }
    return NO;
}

#endif

@end
