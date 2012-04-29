//
//  PasswordViewController.h
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

#import <UIKit/UIKit.h>

@class PasswordViewController;

@protocol PasswordDelegate

- (void)verifyAccount:(PasswordViewController *)passwordviewcontroller username:(NSString *)username password:(NSString *)password;
- (void)setAccount:(PasswordViewController *)passwordviewcontroller username:(NSString *)username password:(NSString *)password;
- (void)cancelSetPassword:(PasswordViewController *)passwordviewcontroller;

@end


@interface PasswordViewController : UIViewController
	<
		UITextFieldDelegate
	>
{
@private
	NSString *m_username;
	NSString *m_password;
	
	BOOL m_fViewLoaded;
	BOOL m_fAccountVerified;
	NSString *m_status;
	NSObject <PasswordDelegate> *m_delegate;
}

@property (nonatomic, assign) BOOL isAccountVerified;
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *password;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil delegate:(NSObject <PasswordDelegate> *)delegate;

- (void)setError:(NSError *)error;

@end
