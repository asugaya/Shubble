//
//  RootViewController.h
//  GoogleDocs
//
//  Created by Tom Saxton on 2/12/09.
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

#import "PasswordViewController.h"
#import "GoogleDocs.h"

@interface RootViewController : UIViewController <PasswordDelegate, GoogleDocsController>
{
	NSString *m_username;
	NSString *m_password;
	
	NSArray *m_adirPath; // array of directory names defining a path to our files
	
	NSInteger m_gstate;
	BOOL m_fViewLoaded;
	NSString *m_strStatus;

	GoogleDocs *m_googledocs;
	PasswordViewController *m_passwordviewcontroller;
}

@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *password;
@property (nonatomic, retain) NSString *strStatus;

- (IBAction)login:(id)sender;
- (IBAction)upload:(id)sender;
- (IBAction)download:(id)sender;
- (IBAction)rename:(id)sender;
- (IBAction)deleteFiles:(id)sender;
- (IBAction)checkFolder:(id)sender;
- (IBAction)ensureFolder:(id)sender;

- (void)uploadString:(NSString *)string;

@end
