//
//  ALBuffer.m
//  ObjectAL
//
//  Created by Karl Stenerud on 15/12/09.
//
// Copyright 2009 Karl Stenerud
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// Note: You are NOT required to make the license available from within your
// iPhone application. Including it in your project is sufficient.
//
// Attribution is not required, but appreciated :)
//

#import "ALBuffer.h"
#import "ALWrapper.h"
#import "OpenALManager.h"


@implementation ALBuffer


#pragma mark Object Management

+ (id) bufferWithName:(NSString*) name data:(void*) data size:(ALsizei) size format:(ALenum) format frequency:(ALsizei) frequency
{
	return [[[self alloc] initWithName:name data:data size:size format:format frequency:frequency] autorelease];
}

- (id) initWithName:(NSString*) nameIn data:(void*) data size:(ALsizei) size format:(ALenum) formatIn frequency:(ALsizei) frequency
{
	if(nil != (self = [super init]))
	{
		self.name = nameIn;
		bufferId = [ALWrapper genBuffer];
		device = [[OpenALManager sharedInstance].currentContext.device retain];
		bufferData = data;
		format = formatIn;

		[ALWrapper bufferDataStatic:bufferId format:format data:bufferData size:size frequency:frequency];
	}
	return self;
}

- (void) dealloc
{
	[ALWrapper deleteBuffer:bufferId];
	[device release];
	[name release];
	free(bufferData);

	[super dealloc];
}


#pragma mark Properties

- (ALuint) bits
{
	return [ALWrapper getBufferi:bufferId parameter:AL_BITS];	
}

@synthesize bufferId;

- (ALuint) channels
{
	return [ALWrapper getBufferi:bufferId parameter:AL_CHANNELS];	
}

@synthesize device;

@synthesize format;

- (ALuint) frequency
{
	return [ALWrapper getBufferi:bufferId parameter:AL_FREQUENCY];	
}

@synthesize name;

- (ALuint) size
{
	return [ALWrapper getBufferi:bufferId parameter:AL_SIZE];	
}

@end
