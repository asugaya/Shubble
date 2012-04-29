//
//  PasswordViewController.m
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

#import "PasswordViewController.h"
#import "PasswordView.h"

@interface PasswordViewController ()

@property (nonatomic, retain) NSString *status;

- (IBAction)cancel:(id)sender;
- (IBAction)setAccount:(id)sender;

@end

@implementation PasswordViewController

@dynamic status;
@synthesize username = m_username,
            password = m_password
			;
@dynamic isAccountVerified;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil delegate:(NSObject <PasswordDelegate> *)delegate
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
	{
        // Custom initialization
		self.username = @"";
		self.password = @"";

		m_status = @"";
		m_delegate = delegate;
		
		UIBarButtonItem *buttonT = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel  target:self action:@selector(cancel:)];
		self.navigationItem.leftBarButtonItem = buttonT;
		[buttonT release];

		buttonT = [[UIBarButtonItem alloc] initWithTitle:@"Set" style:UIBarButtonItemStyleBordered  target:self action:@selector(setAccount:)];
		self.navigationItem.rightBarButtonItem = buttonT;
		[buttonT release];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	m_fViewLoaded = YES;
	
	PasswordView *passwordview = (PasswordView *)self.view;
	passwordview.textfieldUsername.text = self.username;
	passwordview.textfieldUsername.delegate = self;
	passwordview.textfieldPassword.text = self.password;
	passwordview.textfieldPassword.delegate = self;
	passwordview.labelStatus.text = m_status;
	passwordview.labelErrorMsg.text = @"";
	passwordview.spinner.hidden = YES;
}

- (void)dealloc
{
    [super dealloc];
}

#pragma mark Actions

- (IBAction)cancel:(id)sender
{
	[m_delegate cancelSetPassword:self];
}

- (IBAction)setAccount:(id)sender
{
	m_status = @"Verifying account…";

	Assert(m_fViewLoaded);
	if (m_fViewLoaded)
	{
		PasswordView *passwordview = (PasswordView *)self.view;
		passwordview.spinner.hidden = NO;
		[passwordview.spinner startAnimating];

		self.username = passwordview.textfieldUsername.text;
		self.password = passwordview.textfieldPassword.text;
		[m_delegate verifyAccount:self username:self.username password:self.password];
	}
}

#pragma mark Properties

- (BOOL)isAccountVerified
{
	return m_fAccountVerified;
}

- (void)setIsAccountVerified:(BOOL)fVerified
{
	m_fAccountVerified = fVerified;
	self.status = [NSString stringWithFormat:@"Account login %@.", m_fAccountVerified ? @"succeeded" : @"failed"];

	if (m_fViewLoaded)
	{
		PasswordView *passwordview = (PasswordView *)self.view;
		[passwordview.spinner stopAnimating];
		passwordview.spinner.hidden = YES;
	}

	if (fVerified)
		[m_delegate setAccount:self username:self.username password:self.password];
}

- (NSString *)status
{
	return m_status;
}

- (void)setStatus:(NSString *)status
{
	if (m_status != status)
		[m_status release];
	m_status = [status retain];

	if (m_fViewLoaded)
	{
		PasswordView *passwordview = (PasswordView *)self.view;
		passwordview.labelStatus.text = m_status;
	}
}

- (void)setError:(NSError *)error
{
	if (m_fViewLoaded)
	{
		PasswordView *passwordview = (PasswordView *)self.view;
		
		passwordview.labelErrorMsg.text = error == nil
			? @""
			: [NSString stringWithFormat:@"%@ (%d)", [error.userInfo objectForKey:@"error"], error.code];
	}
}

#pragma mark UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	if (m_fViewLoaded)
	{
		PasswordView *passwordview = (PasswordView *)self.view;
		
		if (textField == passwordview.textfieldUsername)
			self.username = textField.text;
		else if (textField == passwordview.textfieldPassword)
			self.password = textField.text;
	}
	self.status = @"";
}

#pragma mark UIViewController

- (void)didReceiveMemoryWarning
{
	m_fViewLoaded = NO;

	// Releases the view if it doesn't have a superview
    [super didReceiveMemoryWarning];

    // Release anything that's not essential, such as cached data
}

@end
