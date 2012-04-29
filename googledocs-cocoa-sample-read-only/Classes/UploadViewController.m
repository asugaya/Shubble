//
//  UploadViewController.m
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

#import "UploadViewController.h"
#import "RootViewController.h"
#import "UploadView.h"

@implementation UploadViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil owner:(RootViewController *)owner
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
	{
        // Custom initialization
		m_owner = owner;
    }
    return self;
}

- (IBAction)doUpload:(id)sender
{
	UploadView *uploadview = (UploadView *)self.view;
	if (uploadview != nil)
	{
		[m_owner uploadString:uploadview.textfield.text];
	}
}

- (void)didReceiveMemoryWarning
{
	// Releases the view if it doesn't have a superview
    [super didReceiveMemoryWarning];

    // Release anything that's not essential, such as cached data
}


- (void)dealloc
{
    [super dealloc];
}


@end
