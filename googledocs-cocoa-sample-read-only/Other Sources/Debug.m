//
//  Debug.m
//  GoogleDocs
//
//  Created by Tom Saxton on 6/30/08.
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

#ifdef DEBUG

@interface AssertHandler : NSObject <UIAlertViewDelegate>
{
@private
	BOOL m_fInAssert;
}

- (id)init;
- (void)showAlert:(NSString *)strMsg;

@end

static AssertHandler *s_asserthandler = nil;

int AssertProc(const char pszCondition[], const char pszFunction[], const char pszFile[], long line)
{
	NSString *str = [NSString stringWithFormat:@"Assert failed %s %s(%d): %s", pszFunction, pszFile, line, pszCondition];
	NSLog(@"%@", str);
	
	if (s_asserthandler == nil)
		s_asserthandler = [[AssertHandler alloc] init];
	[s_asserthandler showAlert:str];
	return 0;
}

@implementation AssertHandler

- (id)init
{
	if (self = [super init])
	{
		m_fInAssert = NO;
	}
	return self;
}

- (void)showAlert:(NSString *)strMsg
{
	if (m_fInAssert)
		return;

	UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Assert Failed" message:strMsg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alertView show];
	[alertView release];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	m_fInAssert = NO;

	NSLog(@"assert alert dismissed with button index %d", buttonIndex);
}

@end

#endif