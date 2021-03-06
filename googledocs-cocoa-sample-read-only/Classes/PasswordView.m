//
//  PasswordView.m
//  GoogleDocs
//
//  Created by Tom Saxton on 12/23/08.
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

#import "PasswordView.h"


@implementation PasswordView

@synthesize textfieldUsername = m_textfieldUsername,
            textfieldPassword = m_textfieldPassword,
			labelStatus = m_labelStatus,
			labelErrorMsg = m_labelErrorMsg,
			spinner = m_spinner
			;

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
	{
        // Initialization code
    }
    return self;
}


- (void)drawRect:(CGRect)rect
{
    // Drawing code
}


- (void)dealloc
{
    [super dealloc];
}


@end
