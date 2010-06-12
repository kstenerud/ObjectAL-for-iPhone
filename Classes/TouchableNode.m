//
//  TouchableNode.m
//
//  Created by Karl Stenerud on 10-01-21.
//

#import "TouchableNode.h"

@interface TouchableNode (Private)

- (void) unregisterWithTouchDispatcher;

@end

@implementation TouchableNode

@synthesize isTouchesEnabled;
@synthesize touchPriority;
@synthesize targetedTouches;
@synthesize swallowTouches;

- (void) dealloc
{
	[self unregisterWithTouchDispatcher];
	
	[super dealloc];
}

-(void) registerWithTouchDispatcher
{
	[self unregisterWithTouchDispatcher];

	if(targetedTouches)
	{
		[[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:touchPriority swallowsTouches:swallowTouches];
	}
	else 
	{
		[[CCTouchDispatcher sharedDispatcher] addStandardDelegate:self priority:touchPriority];
	}
	registeredWithDispatcher = YES;
}

- (void) unregisterWithTouchDispatcher
{
	if(registeredWithDispatcher)
	{
		[[CCTouchDispatcher sharedDispatcher] removeDelegate:self];
		registeredWithDispatcher = NO;
	}
}

- (void) setTargetedTouches:(BOOL) value
{
	if(targetedTouches != value)
	{
		targetedTouches = value;
		
		if(isRunning_ && isTouchesEnabled)
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
		
		if(isRunning_ && isTouchesEnabled)
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
		if(isRunning_ && isTouchesEnabled)
		{
			[self registerWithTouchDispatcher];
		}
	}
}

-(void) setIsTouchesEnabled:(BOOL)enabled
{
	if( isTouchesEnabled != enabled )
	{
		isTouchesEnabled = enabled;
		if( isRunning_ )
		{
			if( isTouchesEnabled )
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
	self.isTouchesEnabled = NO;
}

#pragma mark TouchableNode - Callbacks
-(void) onEnter
{
	// register 'parent' nodes first
	// since events are propagated in reverse order
	if (isTouchesEnabled)
	{
		[self registerWithTouchDispatcher];
	}
	
	// then iterate over all the children
	[super onEnter];
}

-(void) onExit
{
	if(isTouchesEnabled)
	{
		[self unregisterWithTouchDispatcher];
	}
	
	[super onExit];
}

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	NSAssert(NO, @"TouchableNode#ccTouchBegan override me");
	return YES;
}

- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	NSAssert(NO, @"TouchableNode#ccTouchesBegan override me");
}

- (BOOL) touchHitsSelf:(UITouch*) touch
{
	return [self touch:touch hitsNode:self];
}

- (BOOL) touch:(UITouch*) touch hitsNode:(CCNode*) node
{
	CGRect r = CGRectMake(0, 0, node.contentSize.width, node.contentSize.height);
	CGPoint local = [node convertTouchToNodeSpace:touch];
	
	return CGRectContainsPoint(r, local);
}

@end
