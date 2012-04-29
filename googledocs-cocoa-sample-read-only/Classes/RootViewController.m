//
//  RootViewController.m
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

#import "RootViewController.h"
#import "RootView.h"
#import "GoogleDocsAppDelegate.h"
#import "IdleLoop.h"
#import "UploadViewController.h"

enum // Google Docs state values
{
	gstateNil,
	gstateSendingFile,
	gstateReceivingFile,
	gstateRetitleFiles,
	gstateDeleteFiles,
	gstateEnsureFolder,
	gstateVerifyAccount
};

// REVIEW: hardcoded folder name and file title for sample app
static NSString *s_strFileTitle = @"Google Docs Sample App Data.html";
static NSString *s_strFileBackupTitle = @"Google Docs Sample App Data Backup.html";

@interface RootViewController ()

@property (nonatomic, retain) GoogleDocs *googledocs;
@property (nonatomic, retain) NSArray *adirPath;

- (void)doFolderCheckCanCreate:(BOOL)fCreate;
- (void)updateControlState;
- (void)endGoogleOp:(BOOL)fSuccess error:(NSError *)error;
- (void)closePasswordView;

- (GoogleDocs *)getGoogleDocsUsername:(NSString *)username password:(NSString *)password;

@end


@implementation RootViewController

@synthesize username = m_username,
            password = m_password,
			googledocs = m_googledocs,
			strStatus = m_strStatus,
			adirPath = m_adirPath
			;

- (void)awakeFromNib
{
	self.title = @"Google Docs";

	m_gstate = gstateNil;
	m_passwordviewcontroller = nil;
	m_fViewLoaded = NO;
	
	self.adirPath = [NSArray arrayWithObjects: @"Google Docs Sample App", @"Backup Data", nil];
	
	self.strStatus = @"";
}

- (void)dealloc
{
    [super dealloc];
}

#pragma mark Actions

- (IBAction)login:(id)sender
{
	m_passwordviewcontroller = [[PasswordViewController alloc] initWithNibName:@"PasswordView" bundle:nil delegate:self];
	m_passwordviewcontroller.username = self.username;
	m_passwordviewcontroller.password = self.password;

	[self.navigationController pushViewController:m_passwordviewcontroller animated:YES];
}

- (IBAction)upload:(id)sender
{
	if (m_gstate == gstateNil)
	{
		UIViewController *controllerNew = [[UploadViewController alloc] initWithNibName:@"UploadView" bundle:nil owner:self];
		[self.navigationController pushViewController:controllerNew animated:YES];
		[controllerNew release];
	}
}

- (IBAction)download:(id)sender
{
	if (m_gstate == gstateNil)
	{
		if ([self getGoogleDocsUsername:self.username password:self.password])
		{
			[self.googledocs beginDownloadTitle:s_strFileTitle inFolder:self.adirPath];
			m_gstate = gstateReceivingFile;
			
			[self updateControlState];
		}
	}
}

- (IBAction)rename:(id)sender
{
	if (m_gstate == gstateNil)
	{
		if ([self getGoogleDocsUsername:self.username password:self.password])
		{
			m_gstate = gstateRetitleFiles;
			[self.googledocs beginFileRetitleFrom:s_strFileTitle toTitle:s_strFileBackupTitle inFolder:self.adirPath];

			[self updateControlState];
		}
	}
}

- (IBAction)deleteFiles:(id)sender
{
	if (m_gstate == gstateNil)
	{
		if ([self getGoogleDocsUsername:self.username password:self.password])
		{
			m_gstate = gstateDeleteFiles;
			[self.googledocs beginFileDeleteTitle:s_strFileTitle inFolder:self.adirPath keepingNewest:0];

			[self updateControlState];
		}
	}
}

- (IBAction)checkFolder:(id)sender;
{
	[self doFolderCheckCanCreate:NO];
}

- (IBAction)ensureFolder:(id)sender
{
	[self doFolderCheckCanCreate:YES];
}

- (void)doFolderCheckCanCreate:(BOOL)fCreate
{
	if (m_gstate == gstateNil)
	{
		if ([self getGoogleDocsUsername:self.username password:self.password])
		{
			m_gstate = gstateEnsureFolder;
			[self.googledocs beginFolderCheck:self.adirPath createIfNeeded:fCreate];

			[self updateControlState];
		}
	}
}

- (void)uploadString:(NSString *)string
{
	// send the encoded file
	if (m_gstate == gstateNil)
	{
		if ([self getGoogleDocsUsername:self.username password:self.password])
		{
			// create an XML representation of our data
			NSData *dataRaw = [NSKeyedArchiver archivedDataWithRootObject:string];

			// encode it as a blob of ASCII hex in an html file
			NSData *dataHtml = [dataRaw dataEncodeToHtml];
			[self.googledocs beginUploadData:dataHtml withTitle:s_strFileTitle inFolder:self.adirPath replaceExisting:YES];

			// upload the encoded file
			m_gstate = gstateSendingFile;		
			[self updateControlState];
		}
	}

	// pop the UploadView
	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark UI Helpers

- (void)updateControlState
{
	if (m_fViewLoaded)
	{
		RootView *rootview = (RootView *)self.view;

		BOOL fEnableButtons = NO;
		BOOL fSpin = YES;
		NSString *strStatus = nil;
		
		switch (m_gstate)
		{
		case gstateNil:
			fEnableButtons = !FEmptyOrNilString(m_username);
			fSpin = NO;
			break;
		
		case gstateSendingFile:
			strStatus = @"uploading...";
			break;
		
		case gstateReceivingFile:
			strStatus = @"downloading...";
			break;
		
		case gstateRetitleFiles:
			strStatus = @"renaming...";
			break;
		
		case gstateDeleteFiles:
			strStatus = @"deleting...";
			break;
		
		case gstateEnsureFolder:
			strStatus = @"checking folder...";
			break;
		}
		
		if (strStatus != nil)
			self.strStatus = strStatus;

		rootview.labelStatus.text = self.strStatus;

		rootview.buttonLogin.enabled = m_gstate == gstateNil;
		rootview.buttonUpload.enabled = fEnableButtons;
		rootview.buttonDownload.enabled = fEnableButtons;
		rootview.buttonRename.enabled = fEnableButtons;
		rootview.buttonDelete.enabled = fEnableButtons;
		rootview.buttonCheckFolder.enabled = fEnableButtons;
		rootview.buttonEnsureFolder.enabled = fEnableButtons;
		
		rootview.spinner.hidden = !fSpin;
		if (fSpin)
			[rootview.spinner startAnimating];
		else
			[rootview.spinner stopAnimating];
	}
}

- (void)closePasswordView
{
	[self.navigationController popViewControllerAnimated:YES];
	[m_passwordviewcontroller release];
	m_passwordviewcontroller = nil;
}

- (void)endGoogleOp:(BOOL)fSuccess error:(NSError *)error
{
	NSString *strOp = @"Operation";

	switch (m_gstate)
	{
	case gstateVerifyAccount:
		strOp = @"Account verification";
		break;

	case gstateSendingFile:
		strOp = @"Upload";
		break;
	
	case gstateReceivingFile:
		strOp = @"Download";
		break;
	
	case gstateRetitleFiles:
		strOp = @"Rename";
		break;
	
	case gstateDeleteFiles:
		strOp = @"Delete";
		break;
	
	case gstateEnsureFolder:
		strOp = @"Folder check";
		break;
	}
	
	self.strStatus = [NSString stringWithFormat:@"%@ %@.", strOp, fSuccess ? @"succeeded" : @"failed"];
	
	// we may not always have an error record for a failure, but if the operation
	// was successful, then we should not have an error record
	Assert(!fSuccess || error == nil);

	// if there was a failure and an error record, append the error code to the end of the string
	// NOTE: in a real app, we'd also want to show the error's description string
	if (!fSuccess && error != nil)
		self.strStatus = [NSString stringWithFormat:@"%@ (%d)", self.strStatus, error.code];
}

#pragma mark GoogleDocsController

- (void)googleDocsAccountVerifyComplete:(GoogleDocs *)googledocs valid:(BOOL)fValid error:(NSError *)error
{
	m_passwordviewcontroller.isAccountVerified = fValid;
	[m_passwordviewcontroller setError:error];
	
	[self endGoogleOp:fValid error:error];
	
	m_gstate = gstateNil;
	[self updateControlState];
}

- (void)googleDocsUploadProgress:(GoogleDocs *)googledocs read:(unsigned long long)cbRead of:(unsigned long long)cbTotal
{
	DebugLog(@"GoogleDocs: uploaded %d of %d", (int)cbRead, (int)cbTotal);
	Assert(m_gstate == gstateSendingFile);
}

- (void)googleDocsUploadComplete:(GoogleDocs *)googledocs error:(NSError *)error
{
	DebugLog(@"GoogleDocs: upload complete: %@", error == nil ? @"success" : error);
	Assert(m_gstate == gstateSendingFile);

	[self endGoogleOp:error == nil error:error];

	m_gstate = gstateNil;
	[self updateControlState];
}

- (void)googleDocsDownloadProgress:(GoogleDocs *)googledocs read:(unsigned long long)cbReadSoFar
{
	DebugLog(@"GoogleDocs: downloaded %d bytes", (int)cbReadSoFar);
	Assert(m_gstate == gstateReceivingFile);
}

- (void)googleDocsDownloadComplete:(GoogleDocs *)googledocs data:(NSData *)data error:(NSError *)errorDownload
{
	DebugLog(@"GoogleDocs: download complete: %@", data != nil ? @"success" : (errorDownload == nil ? @"file not found" : errorDownload));

	Assert(m_gstate == gstateReceivingFile);

	[self endGoogleOp:data != nil error:errorDownload];

	if (data != nil)
	{
#ifdef DEBUG // in the debug version, write the raw data to a file so you can look at it if something goes wrong
		NSError *errorWrite = nil;
		if (![data writeToFile:[GoogleDocsAppDelegate getDocumentPath:@"result.html"] options:0 error:&errorWrite])
			DebugLog(@"Failed to write out raw download file contents: %@", errorWrite);
#endif

		// extract the original XML from the HTML-encoded data
		NSData *dataXML = [data dataDecodeFromHtml];
		
		if (dataXML == nil)
		{
			self.strStatus = @"Could not decode downloaded file.";
		}
		else
		{
			// unarchive the string and use it to set the status string
			NSString *strResult = [NSKeyedUnarchiver unarchiveObjectWithData:dataXML];
			if (strResult != nil)
				self.strStatus = [NSString stringWithFormat:@"received: %@", strResult];
			else
				self.strStatus = @"Could not load decoded file";
		}
	}

	m_gstate = gstateNil;
	[self updateControlState];
}

- (void)googleDocsRetitleComplete:(GoogleDocs *)googledocs success:(BOOL)fSuccess count:(NSInteger)count error:(NSError *)error
{
	DebugLog(@"GoogleDocs: retitle files complete : %@ (%d renamed)", error == nil ? @"success" : error, count);
	[self endGoogleOp:error == nil error:error];

	self.strStatus = [NSString stringWithFormat:@"%@ %d renamed.", self.strStatus, count];

	m_gstate = gstateNil;
	[self updateControlState];
}

- (void)googleDocsDeleteComplete:(GoogleDocs *)googledocs success:(BOOL)fSuccess count:(NSInteger)count error:(NSError *)error
{
	DebugLog(@"GoogleDocs: delete files complete : %@ (%d deleted)", error == nil ? @"success" : error, count);
	[self endGoogleOp:error == nil error:error];

	self.strStatus = [NSString stringWithFormat:@"%@ %d deleted.", self.strStatus, count];

	m_gstate = gstateNil;
	[self updateControlState];
}

- (void)googleDocsCheckFolderComplete:(GoogleDocs *)googledocs exists:(BOOL)fExists wasCreated:(BOOL)fCreated error:(NSError *)error;
{
	DebugLog(@"GoogleDocs: check folder complete: %@", error == nil ? [NSString stringWithFormat:@"folder %@", fExists ? (fCreated ? @"created" : @"exists") : @"does not exist"] : error);
	Assert(m_gstate == gstateEnsureFolder);

	[self endGoogleOp:error == nil error:error];
	
	if (error == nil)
		self.strStatus = [NSString stringWithFormat:@"%@ Folder %@.", self.strStatus, fExists ? (fCreated ? @"created" : @"exists") : @"does not exist"];

	m_gstate = gstateNil;
	[self updateControlState];
}

#pragma mark GoogleDocs Helpers

- (GoogleDocs *)getGoogleDocsUsername:(NSString *)username password:(NSString *)password
{
	if (self.googledocs != nil)
	{
		self.googledocs.username = username;
		self.googledocs.password = password;
	}
	else
	{
		self.googledocs = [[GoogleDocs alloc] initWithUsername:username password:password owner:self];
	}
	return self.googledocs;
}

#pragma mark PasswordController

- (void)verifyAccount:(PasswordViewController *)passwordviewcontroller username:(NSString *)username password:(NSString *)password
{
	if (FEmptyOrNilString(username))
	{
		self.username = nil;
		self.password = nil;

		[self updateControlState];
	}
	else
	{
		if (m_gstate != gstateNil)
			return;

		if ([self getGoogleDocsUsername:username password:password] != nil)
		{
			m_gstate = gstateVerifyAccount;
			m_passwordviewcontroller = passwordviewcontroller;
			[self.googledocs verifyAccountUsername:username password:password];
		}
	}
}

- (void)setAccount:(PasswordViewController *)passwordviewcontroller username:(NSString *)username password:(NSString *)password
{
	self.username = username;
	self.password = password;
	
	[self updateControlState];
	[self closePasswordView];
}

- (void)cancelSetPassword:(PasswordViewController *)passwordviewcontroller
{
	[self closePasswordView];
}

#pragma mark UIViewController methods

- (void)viewDidLoad
{
	m_fViewLoaded = YES;

	RootView *rootview = (RootView *)self.view;
	
	UIColor *colorDisabled = [UIColor grayColor];
	[rootview.buttonLogin setTitleColor:colorDisabled forState:UIControlStateDisabled];
	[rootview.buttonUpload setTitleColor:colorDisabled forState:UIControlStateDisabled];
	[rootview.buttonDownload setTitleColor:colorDisabled forState:UIControlStateDisabled];
	[rootview.buttonRename setTitleColor:colorDisabled forState:UIControlStateDisabled];
	[rootview.buttonDelete setTitleColor:colorDisabled forState:UIControlStateDisabled];
	[rootview.buttonCheckFolder setTitleColor:colorDisabled forState:UIControlStateDisabled];
	[rootview.buttonEnsureFolder setTitleColor:colorDisabled forState:UIControlStateDisabled];

	[self updateControlState];
}

- (void)didReceiveMemoryWarning
{
	// Releases the view if it doesn't have a superview
    [super didReceiveMemoryWarning];
	m_fViewLoaded = NO;

    // Release anything that's not essential, such as cached data
}



@end

