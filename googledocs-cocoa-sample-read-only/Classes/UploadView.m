//
//  UploadView.m
//  GoogleDocs
//
//  Created by Tom Saxton on 2/13/09.
//  Copyright (c) 2008-2009 Idle Loop Software Design, LLC.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "UploadView.h"

@interface UploadView ()

- (void)initControls;

@end

@implementation UploadView

@synthesize textfield = m_textfield;

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
	{
        // Initialization code
		[self initControls];
    }
    return self;
}

- (void)awakeFromNib
{
	[self initControls];
}

- (void)initControls
{
	NSDate *date = [NSDate date];
	NSDateFormatter *dateformatter = [[NSDateFormatter alloc] init];
	[dateformatter setDateFormat:@"MM/dd/yyyy HH:mm:ss z"];
	
	m_textfield.text = [dateformatter stringFromDate:date];
	[dateformatter release];
}

- (void)dealloc
{
    [super dealloc];
}


@end
