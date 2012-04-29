//
//  GoogleDocs.m
//  GoogleDocs
//
//  Created by Tom Saxton on 12/19/08.
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

#import "GoogleDocs.h"
#import "GDataDocs.h"
#import "IdleLoop.h"

// URL to get Auth token
// "https://www.google.com/accounts/ClientLogin?Email=your_email&Passwd=your_password&service=xapi&source=Company-Product-Version"
// more info: http://code.google.com/apis/accounts/docs/AuthForInstalledApps.html

// REVIEW: Customize this string to identify your application.
static NSString *s_strUserAgent = @"com.idleloop.Sample_GoogleDocs_App";

#ifdef DEBUG
void DumpEntryArray(NSArray *aentry);
#endif

static NSString *s_strRecursionError = @"Internal Error: recursion not allowed";
NSError *NSErrorWithMessage(NSString *strMessage, NSInteger code);

enum
{
	gopNil,
	gopVerifyAccount,
	gopUploadFile,
	gopDownloadFile,
	gopRetitleFiles,
	gopDeleteFiles,
	gopEnsureDir
};

@interface GoogleDocs ()

@property (nonatomic, retain) GDataFeedDocList *feedDocList;
@property (nonatomic, retain) NSError *errorDocListFetch;
@property (nonatomic, retain) GDataServiceTicket *ticketDocListFetch;
@property (nonatomic, retain) GDataServiceTicket *ticketUpload;

@property (nonatomic, assign) NSInteger gop;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSArray *adirPath;
@property (nonatomic, assign) NSInteger idirPath;
@property (nonatomic, retain) NSString *titleNew;
@property (nonatomic, retain) NSURL *urlFolderFeed;

@property (nonatomic, retain) NSData *dataToUpload;

@property (nonatomic, assign) BOOL fCanCreateDir;
@property (nonatomic, assign) BOOL fDidCreateDir;

@property (nonatomic, assign) BOOL fReplaceExisting;

@property (nonatomic, retain) NSArray *aentryRetitle;
@property (nonatomic, assign) NSInteger ientryRetitle;

@property (nonatomic, assign) NSInteger cfileKeep;
@property (nonatomic, retain) NSArray *aentryDelete;
@property (nonatomic, assign) NSInteger ientryDelete;

@property (nonatomic, retain) NSArray *adirPathCache;
@property (nonatomic, retain) NSURL *urlFolderFeedCache;
@property (nonatomic, assign) BOOL fUsedCache;

- (GDataServiceGoogleDocs *)serviceDocs:(NSString *)username password:(NSString *)password;
- (void)fetchDocListForFeed:(NSURL *)urlFeed title:(NSString *)title username:(NSString *)username password:(NSString *)password;

- (void)downloadEntry:(GDataEntryDocBase *)entry;
- (BOOL)fGetMIMEType:(NSString **)mimeType andEntryClass:(Class *)class forExtension:(NSString *)extension;

- (void)setDirArrary:(id)dirStringOrArray;
- (void)sendFailureNotice:(NSString *)strErrorMessage code:(NSInteger)code;
- (void)retitleNextFile;
- (void)deleteNextFile;
- (BOOL)fRetryCachedQuery;
- (void)endOperation;

@end

@interface GDataEntryDocBase (IdleLoop)

- (NSComparisonResult)compareEntriesByUpdatedDate:(GDataEntryDocBase *)docOther;

@end

@implementation GoogleDocs

@synthesize username = m_username,
            password = m_password,
			feedDocList = m_feedDocList,
			errorDocListFetch = m_errorDocListFetch,
			ticketDocListFetch = m_ticketDocListFetch,
			ticketUpload = m_ticketUpload,
			dataToUpload = m_dataToUpload,
			title = m_title,
			adirPath = m_adirPath,
			idirPath = m_idirPath,
			titleNew = m_titleNew,
			fReplaceExisting = m_fReplaceExisting,
			gop = m_gop,
			urlFolderFeed = m_urlFolderFeed,
			aentryRetitle = m_aentryRetitle,
			ientryRetitle = m_ientryRetitle,
			cfileKeep = m_cfileKeep,
			aentryDelete = m_aentryDelete,
			ientryDelete = m_ientryDelete,
			adirPathCache = m_adirPathCache,
			urlFolderFeedCache = m_urlFolderFeedCache,
			fUsedCache = m_fUsedCache,
			fCanCreateDir = m_fCanCreateDir,
			fDidCreateDir = m_fDidCreateDir
			;

// Create a GoogleDocs object initialized with username, password and an owner object to receive
// operation result callbacks for upload/download operations via the GoogleDocsController protocol.
- (id)initWithUsername:(NSString *)username password:(NSString *)password owner:(NSObject <GoogleDocsController> *)owner
{
	if (self = [super init])
	{
		m_owner = owner;

		self.gop = gopNil;
		self.username = username;
		self.password = password;
	}
	
	return self;
}

- (void)dealloc
{
	self.username = nil;
	self.password = nil;

	[self endOperation];

	self.adirPathCache = nil;
	self.urlFolderFeedCache = nil;

	[super dealloc];
}

#pragma mark Public Interface

// use this method to verify a username/password pair
- (void)verifyAccountUsername:(NSString *)username password:(NSString *)password
{
	if (self.gop == gopNil)
	{
		// since we may be changing accounts, toss out the folder feed cache
		self.adirPathCache = nil;
		self.urlFolderFeedCache = nil;
		
		self.gop = gopVerifyAccount;
		[self fetchDocListForFeed:nil title:nil username:username password:password];
	}
	else
	{
		Assert(NO);
		[m_owner googleDocsAccountVerifyComplete:self valid:NO error:NSErrorWithMessage(s_strRecursionError, gecResursion)];
	}
}

// This method begins the process to upload a file. It first sets up some state,
// then fires off the request for a GDataFeedDocList. When that completes, the
// completition callback method will fire off the upload. If there's already a
// document with the same title and replaceExisting is YES, it will get replaced
// with the new data; otherwise a new document will be created with the same title.
//
// The owner object is informed of progress during the upload and given
// a success or failure indication at completion via the GoogleDocsController
// protocol.
- (void)beginUploadData:(NSData *)dataUpload withTitle:(NSString *)title inFolder:(id)dirStringOrArray replaceExisting:(BOOL)fReplaceExisting;
{
	if (self.gop == gopNil)
	{
		self.fCanCreateDir = YES;
		self.dataToUpload = dataUpload;
		self.fReplaceExisting = fReplaceExisting;
		[self setDirArrary:dirStringOrArray];

		self.gop = gopUploadFile;
		[self fetchDocListForFeed:nil title:title username:self.username password:self.password];
	}
	else
	{
		Assert(NO);
		[m_owner googleDocsUploadComplete:self error:NSErrorWithMessage(s_strRecursionError, gecResursion)];
	}
}

// This method begins the process to upload a file. It first sets up some state,
// then fires off the request for a GDataFeedDocList. When that completes, the
// completition callback method will do the download.
//
// The owner object is informed of progress during the download and given
// a success or failure indication at completion via the GoogleDocsController
// protocol.
- (void)beginDownloadTitle:(NSString *)title inFolder:(id)dirStringOrArray;
{
	if (self.gop == gopNil)
	{
		self.fCanCreateDir = NO;
		[self setDirArrary:dirStringOrArray];

		self.gop = gopDownloadFile;
		[self fetchDocListForFeed:nil title:title username:self.username password:self.password];
	}
	else
	{
		Assert(NO);
		[m_owner googleDocsDownloadComplete:self data:nil error:NSErrorWithMessage(s_strRecursionError, gecResursion)];
	}
}

- (void)beginFileRetitleFrom:(NSString *)titleOld toTitle:(NSString *)titleNew inFolder:(id)dirStringOrArray
{
	if (self.gop == gopNil)
	{
		self.titleNew = titleNew;
		self.fCanCreateDir = NO;
		[self setDirArrary:dirStringOrArray];

		self.gop = gopRetitleFiles;
		[self fetchDocListForFeed:nil title:titleOld username:self.username password:self.password];
	}
	else
	{
		Assert(NO);
		[m_owner googleDocsRetitleComplete:self success:NO count:0 error:NSErrorWithMessage(s_strRecursionError, gecResursion)];
	}
}

- (void)beginFileDeleteTitle:(NSString *)title inFolder:(id)dirStringOrArray keepingNewest:(NSInteger)cfileKeep
{
	if (self.gop == gopNil)
	{
		self.title = title;
		self.cfileKeep = cfileKeep;
		[self setDirArrary:dirStringOrArray];

		self.gop = gopDeleteFiles;
		[self fetchDocListForFeed:nil title:title username:self.username password:self.password];
	}
	else
	{
		Assert(NO);
		[m_owner googleDocsDeleteComplete:self success:NO count:0 error:NSErrorWithMessage(s_strRecursionError, gecResursion)];
	}
}

- (void)beginFolderCheck:(id)dirStringOrArray createIfNeeded:(BOOL)fCreate
{
	if (self.gop == gopNil)
	{
		self.fCanCreateDir = fCreate;
		[self setDirArrary:dirStringOrArray];

		self.gop = gopEnsureDir;
		[self fetchDocListForFeed:nil title:nil username:self.username password:self.password];
	}
	else
	{
		Assert(NO);
		[m_owner googleDocsCheckFolderComplete:self exists:NO wasCreated:NO error:NSErrorWithMessage(s_strRecursionError, gecResursion)];
	}
}

#pragma mark Mapping to MIME Types

// This is a utility method (taken directly from Google's sample code) that maps
// a file extension to the appropriate MIME type and GDataEntryStandardDoc subclass.
//
// Add your own document types to the table as needed.
- (BOOL)fGetMIMEType:(NSString **)mimeType andEntryClass:(Class *)class forExtension:(NSString *)extension
{  
	// Mac OS X's UTI database doesn't know MIME types for .doc and .xls
	// so GDataEntryBase's MIMETypeForFileAtPath method isn't helpful here

	struct MapEntry {
		NSString *extension;
		NSString *mimeType;
		NSString *className;
	};

	static struct MapEntry sMap[] =
	{
		{ @"csv", @"text/csv", @"GDataEntryStandardDoc" },
		{ @"doc", @"application/msword", @"GDataEntryStandardDoc" },
		{ @"ods", @"application/vnd.oasis.opendocument.spreadsheet", @"GDataEntrySpreadsheetDoc" },
		{ @"odt", @"application/vnd.oasis.opendocument.text", @"GDataEntryStandardDoc" },
		{ @"pps", @"application/vnd.ms-powerpoint", @"GDataEntryPresentationDoc" },
		{ @"ppt", @"application/vnd.ms-powerpoint", @"GDataEntryPresentationDoc" },
		{ @"rtf", @"application/rtf", @"GDataEntryStandardDoc" },
		{ @"sxw", @"application/vnd.sun.xml.writer", @"GDataEntryStandardDoc" },
		{ @"txt", @"text/plain", @"GDataEntryStandardDoc" },
		{ @"xls", @"application/vnd.ms-excel", @"GDataEntrySpreadsheetDoc" },
		{ @"jpg", @"image/jpeg", @"GDataEntryStandardDoc" },
		{ @"jpeg", @"image/jpeg", @"GDataEntryStandardDoc" },
		{ @"png", @"image/png", @"GDataEntryStandardDoc" },
		{ @"bmp", @"image/bmp", @"GDataEntryStandardDoc" },
		{ @"gif", @"image/gif", @"GDataEntryStandardDoc" },
		{ @"html", @"text/html", @"GDataEntryStandardDoc" },
		{ @"htm", @"text/html", @"GDataEntryStandardDoc" },
		{ @"tsv", @"text/tab-separated-values", @"GDataEntryStandardDoc" },
		{ @"tab", @"text/tab-separated-values", @"GDataEntryStandardDoc" },

		{ nil, nil, nil }
	};

	NSString *lowerExtn = [extension lowercaseString];

	for (int idx = 0; sMap[idx].extension != nil; idx++)
	{
		if ([lowerExtn isEqual:sMap[idx].extension])
		{
			if (mimeType != nil)
				*mimeType = sMap[idx].mimeType;
			if (class != nil)
				*class = NSClassFromString(sMap[idx].className);
			return YES;
		}
	}

	if (mimeType != nil)
		*mimeType = nil;
	if (class != nil)
		*class = nil;
	return NO;
}

#pragma mark GDataSeviceGoogleDocs

// Create a GDataServiceGoogleDocs object initialized with a UserAgent string for your
// application and the username/password of the account you want to use.
- (GDataServiceGoogleDocs *)serviceDocs:(NSString *)username password:(NSString *)password
{  
	static GDataServiceGoogleDocs* service = nil;

	if (service == nil)
	{
		service = [[GDataServiceGoogleDocs alloc] init];

		[service setUserAgent:s_strUserAgent];
		[service setShouldCacheDatedData:YES];
		[service setServiceShouldFollowNextLinks:YES];
	}

	// update the username/password each time the service is requested

	if (username != nil && [username length] && password != nil && [password length])
	{
		[service setUserCredentialsWithUsername:username password:password];
	}
	else
	{
		[service setUserCredentialsWithUsername:nil password:nil];
	}

	return service;
}

#pragma mark Fetching the Docs List Feed

// begin retrieving the list of the user's docs
- (void)fetchDocListForFeed:(NSURL *)urlFeed title:(NSString *)title username:(NSString *)username password:(NSString *)password
{
	self.title = title;

	self.feedDocList = nil;
	self.errorDocListFetch = nil;
	self.ticketDocListFetch = nil;

	GDataServiceGoogleDocs *service = [self serviceDocs:username password:password];
	DebugLog(@"user = %@, authToken = %@", service.username, [service authToken]);

	// if we're starting to traverse a directory path, check to see if we have already cached
	// the feed for the destination folder
	self.fUsedCache = NO;
	if (urlFeed == nil)
	{
		if (self.adirPath != nil && self.adirPathCache != nil && self.gop != gopEnsureDir)
		{
			NSInteger cstrPath = [self.adirPath count];
			if (cstrPath == [self.adirPathCache count])
			{
				int istr;
				for (istr = 0; istr < cstrPath; ++istr)
					if (![[self.adirPath objectAtIndex:istr] isEqual:[self.adirPathCache objectAtIndex:istr]])
						break;
				if (istr == cstrPath)
				{
					// the requested path matches the cached path,
					// use the cached feed URL, but make a note of
					// it so we can retry if the cached value is out of date
					DebugLog(@"Using cached feed for directory path.");
					urlFeed = self.urlFolderFeedCache;
					self.idirPath = cstrPath;
					self.fUsedCache = YES;
				}
			}
		}
		if (urlFeed == nil)
			urlFeed = [NSURL URLWithString:kGDataGoogleDocsDefaultPrivateFullFeed];
	}
	self.urlFolderFeed = urlFeed;
	DebugLog(@"urlFeed = %@", urlFeed);
	
	BOOL fGetDir = self.adirPath != nil && self.idirPath < [self.adirPath count];

	// Fetching a feed gives us 25 responses by default.  We need to use
	// the feed's "next" link to get any more responses.  If we want more than 25
	// at a time, instead of calling fetchDocsFeedWithURL, we can create a
	// GDataQueryDocs object, as shown here.
	GDataQueryDocs *query = [GDataQueryDocs documentQueryWithFeedURL:urlFeed];
	
	// Set the number of files we want to 1 unless we're doing one of the operations
	// that cares about getting all of the files.
	if (self.gop == gopRetitleFiles || self.gop == gopDeleteFiles)
	{
		[query setMaxResults:1000];
		[service setServiceShouldFollowNextLinks:YES];
	}
	else
	{
		[query setMaxResults:1];
		[service setServiceShouldFollowNextLinks:NO];
	}

	[query setShouldShowFolders:fGetDir];
	NSString *titleSearch = fGetDir ? [self.adirPath objectAtIndex:self.idirPath] : title;
	if (titleSearch != nil)
	{
		[query setTitleQuery:titleSearch];
		[query setIsTitleQueryExact:YES];
	}
    
	self.ticketDocListFetch = [service fetchDocsQuery:query
								delegate:self
								didFinishSelector:@selector(docListListFetchTicket:finishedWithFeed:)
								didFailSelector:@selector(docListListFetchTicket:failedWithError:)];
}

//
// docList list fetch callbacks
//

// finished docList list successfully
- (void)docListListFetchTicket:(GDataServiceTicket *)ticket
              finishedWithFeed:(GDataFeedDocList *)object
{
	self.feedDocList = object;
	self.errorDocListFetch = nil;
	self.ticketDocListFetch = nil;

#ifdef DEBUG
	for (GDataEntryBase *entry in [object entries])
	{
		DebugLog(@"%@", entry);
		DebugLog(@"title: %@, updated date: %@",
			[[entry title] stringValue],
			[[entry updatedDate] RFC3339String]
			);
	}
#endif

	BOOL fGetDir = self.adirPath != nil && self.idirPath < [self.adirPath count];
	if (fGetDir)
	{
		BOOL fDirExists = [[self.feedDocList entries] count] > 0;
		DebugLog(@"folder '%@' %@.", [self.adirPath objectAtIndex:self.idirPath], fDirExists ? @"exists" : @"does not exist");
		
		if (fDirExists)
		{
			GDataEntryDocBase *entryFolder = [[self.feedDocList entries] objectAtIndex:0];

			self.urlFolderFeed = nil;
			NSString *folderFeedURI = [[entryFolder content] sourceURI];
			if (folderFeedURI != nil)
				self.urlFolderFeed = [NSURL URLWithString:folderFeedURI];
			
			if (self.urlFolderFeed != nil)
			{
				if (++self.idirPath == [self.adirPath count])
				{
					DebugLog(@"Caching the feed for the requested directory path.");
					self.adirPathCache = self.adirPath;
					self.urlFolderFeedCache = self.urlFolderFeed;
				}
				[self fetchDocListForFeed:self.urlFolderFeed title:self.title username:self.username password:self.password];
			}
			else
			{
				[self sendFailureNotice:@"Unexpected error reading folder." code:gecMissingFolderFeed];
			}
		}
		else if (self.fCanCreateDir)
		{
			GDataServiceGoogleDocs *serviceDocs = [self serviceDocs:self.username password:self.password];

			GDataEntryFolderDoc *entryNew = [[GDataEntryFolderDoc alloc] init];
			[entryNew setTitleWithString:[self.adirPath objectAtIndex:self.idirPath]];
			NSURL *urlPost = [[self.feedDocList postLink] URL];

			self.ticketUpload = [serviceDocs fetchDocEntryByInsertingEntry:entryNew
											forFeedURL:urlPost
											delegate:self
											didFinishSelector:@selector(uploadFileTicket:finishedWithEntry:)
											didFailSelector:@selector(uploadFileTicket:failedWithError:)];
		}
		else
		{
			if (self.gop == gopEnsureDir)
			{
				[self endOperation];
				[m_owner googleDocsCheckFolderComplete:self exists:NO wasCreated:NO error:nil];
			}
			else
			{
				[self sendFailureNotice:@"Folder not found." code:gecFolderNotFound];
			}
		}
		return;
	}

	switch (self.gop)
	{
	case gopUploadFile:
		{
			// The client requested an upload operation. Now we have the info we need to
			// do the upload.
			GDataServiceGoogleDocs *serviceDocs = [self serviceDocs:self.username password:self.password];
			NSString *typeMime = nil;
			Class classEntry = nil;

			// Get the MIME type and the GDataEntryStandardDoc subclass from the file name's extension.
			// Return a failure with an error message if the file extension isn't recognized.
			NSString *strExtension = [self.title pathExtension];
			if (![self fGetMIMEType:&typeMime andEntryClass:&classEntry forExtension:strExtension])
			{
				[self sendFailureNotice:[NSString stringWithFormat:@"Unknown file extension: %@", self.title] code:gecUnknownFileExtension];
				return;
			}

			// If the client has asked to replace any existing file of the same title, and there
			// is a matching document, we replace it with the new data.
			if (self.fReplaceExisting && [[self.feedDocList entries] count] != 0)
			{
				GDataEntryDocBase *entryUpdate = [[self.feedDocList entries] objectAtIndex:0];
				[entryUpdate setUploadData:self.dataToUpload];
				[entryUpdate setUploadMIMEType:typeMime];

				NSURL *urlEdit = [[entryUpdate editLink] URL];
				DebugLog(@"urlEdit = %@", urlEdit);

				self.ticketUpload = [serviceDocs fetchDocEntryByUpdatingEntry:entryUpdate
												forEntryURL:urlEdit
												delegate:self
												didFinishSelector:@selector(uploadFileTicket:finishedWithEntry:)
												didFailSelector:@selector(uploadFileTicket:failedWithError:)];
				return;
			}
			else
			{
				// Insert a new document with the client's data.
				GDataEntryDocBase *entryNew = [classEntry documentEntry];

				[entryNew setTitleWithString:self.title];
				[entryNew setUploadData:self.dataToUpload];
				[entryNew setUploadMIMEType:typeMime];
				[entryNew setUploadSlug:self.title];

				NSURL *urlPost = [[self.feedDocList postLink] URL];
				DebugLog(@"urlPost = %@", urlPost);

				self.ticketUpload = [serviceDocs fetchDocEntryByInsertingEntry:entryNew
												forFeedURL:urlPost
												delegate:self
												didFinishSelector:@selector(uploadFileTicket:finishedWithEntry:)
												didFailSelector:@selector(uploadFileTicket:failedWithError:)];
				return;
			}
		}
		break;
	
	case gopDownloadFile:
		// If the client asked for a download, and there's matching document download it.
		// If there are multiple matching documents, we just download the first one listed.
		// If there is no matching document, tell the client the upload failed.
		if ([[self.feedDocList entries] count] > 0)
		{
			[self downloadEntry:[[self.feedDocList entries] objectAtIndex:0]];
			return;
		}
		else
		{
			[self endOperation];
			[m_owner googleDocsDownloadComplete:self data:nil error:nil];
		}
		break;

	case gopRetitleFiles:
		{
			self.aentryRetitle = [NSArray arrayWithArray:[self.feedDocList entries]];
			self.ientryRetitle = 0;
			[self retitleNextFile];
			return;
		}
		break;
	
	case gopDeleteFiles:
		{
			int centry = [[self.feedDocList entries] count];
			if (centry <= self.cfileKeep)
			{
				self.aentryDelete = nil;
			}
			else if (self.cfileKeep == 0)
			{
				self.aentryDelete = [NSArray arrayWithArray:[self.feedDocList entries]];
			}
			else
			{
#ifdef DEBUG
				DumpEntryArray([self.feedDocList entries]);
#endif

				Assert(self.cfileKeep > 0 && centry > self.cfileKeep);
				NSMutableArray *aentryT = [NSMutableArray arrayWithArray:[self.feedDocList entries]];
				[aentryT sortUsingSelector:@selector(compareEntriesByUpdatedDate:)];
				[aentryT removeObjectsInRange:NSMakeRange(0, self.cfileKeep)];
				
				self.aentryDelete = aentryT;
			}

#ifdef DEBUG
			DumpEntryArray(self.aentryDelete);
#endif
			self.ientryDelete = 0;
			[self deleteNextFile];
			return;
		}
		break;
	
	case gopEnsureDir:
		[self endOperation];
		[m_owner googleDocsCheckFolderComplete:self exists:YES wasCreated:self.fDidCreateDir error:nil];
		break;
	
	case gopVerifyAccount:
		[self endOperation];
		[m_owner googleDocsAccountVerifyComplete:self valid:YES error:nil];
		break;

	default:
		[self endOperation];
		Assert(NO);
		break;
	}

	Assert(self.gop == gopNil);
}

// failed
- (void)docListListFetchTicket:(GDataServiceTicket *)ticket
               failedWithError:(NSError *)error
{
	self.feedDocList = nil;
	self.errorDocListFetch = error;
	self.ticketDocListFetch = nil;
	
	if ([self fRetryCachedQuery])
		return;

	NSInteger gop = self.gop;
	[self endOperation];
	switch (gop)
	{
	case gopUploadFile:
		[m_owner googleDocsUploadComplete:self error:error];
		break;
	
	case gopDownloadFile:
		[m_owner googleDocsDownloadComplete:self data:nil error:error];
		break;
	
	case gopRetitleFiles:
		[m_owner googleDocsRetitleComplete:self success:NO count:self.ientryRetitle error:error];
		break;
	
	case gopDeleteFiles:
		[m_owner googleDocsDeleteComplete:self success:NO count:self.ientryDelete error:error];
		break;
	
	case gopEnsureDir:
		[m_owner googleDocsCheckFolderComplete:self exists:NO wasCreated:NO error:error];
		break;
	
	case gopVerifyAccount:
		[m_owner googleDocsAccountVerifyComplete:self valid:NO error:error];
		break;

	default:
		Assert(NO);
		break;
	}
}

#pragma mark Upload Internals

// progress callback
- (void)inputStream:(GDataProgressMonitorInputStream *)stream 
   hasDeliveredByteCount:(unsigned long long)cbRead 
   ofTotalByteCount:(unsigned long long)cbTotal
{
	DebugLog(@"transfer progress: %d of %d", (int)cbRead, (int)cbTotal);
	[m_owner googleDocsUploadProgress:self read:cbRead of:cbTotal];
}

// upload finished successfully
- (void)uploadFileTicket:(GDataServiceTicket *)ticket
     finishedWithEntry:(GDataEntryDocBase *)entry
{
	DebugLog(@"upload successful: title = %@ URL = %@", [[entry title] stringValue], [NSURL URLWithString:[[entry content] sourceURI]]);

	self.ticketUpload = nil;

	BOOL fGetDir = self.adirPath != nil && self.idirPath < [self.adirPath count];
	if (fGetDir)
	{
		self.fDidCreateDir = YES;

		self.urlFolderFeed = nil;
		NSString *folderFeedURI = [[entry content] sourceURI];
		if (folderFeedURI != nil)
			self.urlFolderFeed = [NSURL URLWithString:folderFeedURI];
		
		if (self.urlFolderFeed != nil)
		{
			if (++self.idirPath == [self.adirPath count])
			{
				DebugLog(@"Caching the feed for the requested directory path.");
				self.adirPathCache = self.adirPath;
				self.urlFolderFeedCache = self.urlFolderFeed;
			}
			[self fetchDocListForFeed:self.urlFolderFeed title:self.title username:self.username password:self.password];
			return;
		}
		else
		{
			[self sendFailureNotice:@"Unexpected error creating folder." code:gecNewFolderCreationError];
			return;
		}
	}
	else
	{
		switch (self.gop)
		{
		case gopUploadFile:
			[self endOperation];
			[m_owner googleDocsUploadComplete:self error:nil];
			break;
		
		case gopRetitleFiles:
			++self.ientryRetitle;
			[self retitleNextFile];
			return; // retitleNextFile file will end the operation when appropriate
		
		case gopDeleteFiles:
			++self.ientryDelete;
			[self deleteNextFile];
			return; // deleteNextFile file will end the operation when appropriate

		default:
			DebugLog(@"gop = %d", self.gop);
			Assert(NO);
			break;
		}
	}

	[self endOperation];
} 

// upload failed
- (void)uploadFileTicket:(GDataServiceTicket *)ticket
       failedWithError:(NSError *)error
{
	DebugLog(@"transfer failed");

	self.ticketUpload = nil;

	if ([self fRetryCachedQuery])
		return;

	NSInteger gop = self.gop;
	[self endOperation];
	switch (gop)
	{
	case gopUploadFile:
		[m_owner googleDocsUploadComplete:self error:error];
		break;

	case gopEnsureDir:
		[m_owner googleDocsCheckFolderComplete:self exists:NO wasCreated:NO error:error];
		break;
	
	case gopRetitleFiles:
		[m_owner googleDocsRetitleComplete:self success:NO count:self.ientryRetitle error:error];
		break;
	
	case gopDeleteFiles:
		[m_owner googleDocsDeleteComplete:self success:NO count:self.ientryDelete error:error];
		break;
	
	default:
		Assert(NO);
		break;
	}
}

#pragma mark DownLoad Internals

- (void)downloadEntry:(GDataEntryDocBase *)entry
{
	NSURL *url = [NSURL URLWithString:[[entry content] sourceURI]];
	if (url)
	{
		// read the document's contents asynchronously from the network
		//
		// since the user has already signed in, the service object
		// has the proper authentication token.  We'll use the service object
		// to generate an NSURLRequest with the auth token in the header, and
		// then fetch that asynchronously.  Without the auth token, the sourceURI
		// would only give us the document if we were already signed into the 
		// user's account with Safari, or if the document was published with
		// public access.
		GDataServiceGoogleDocs *service = [self serviceDocs:self.username password:self.password];
		DebugLog(@"download document \"%@\" from: <%@>", [[entry title] stringValue], url);
		DebugLog(@"user = %@, authToken = %@", service.username, [service authToken]);
		NSURLRequest *request = [service requestForURL:url
												  ETag:nil
                                            httpMethod:nil];

		GDataHTTPFetcher *fetcher = [[GDataHTTPFetcher alloc] initWithRequest:request];
		if (fetcher == nil)
		{
			// don't know why creating the fetch would fail, but just in case...
			[m_owner googleDocsDownloadComplete:self data:nil error:NSErrorWithMessage(@"Attempt to start download failed.", gecFetcherInitFailed)];
		}
		else
		{
			// prevent the fetcher from storing cookies for use by later instantiations
			[fetcher setCookieStorageMethod:kGDataHTTPFetcherCookieStorageMethodFetchHistory];
			
			// set the option data receiver so we can pass download progress to the caller
			[fetcher setReceivedDataSelector:@selector(docFetcher:receivedData:)];

			// start the fetch
			[fetcher beginFetchWithDelegate:self
				didFinishSelector:@selector(docFetcher:finishedWithData:)
				didFailSelector:@selector(docFetcher:failedWithError:)
				];
		}
	}
	else
	{
		// don't know why this failed, but let the caller know the game is over.
		[self endOperation];
		[m_owner googleDocsDownloadComplete:self data:nil error:nil];
	}
}

- (void)docFetcher:(GDataHTTPFetcher *)fetcher receivedData:(NSData *)dataReceivedSoFar
{
	[m_owner googleDocsDownloadProgress:self read:[dataReceivedSoFar length]];
}

- (void)docFetcher:(GDataHTTPFetcher *)fetcher finishedWithData:(NSData *)data
{
	[self endOperation];
	[m_owner googleDocsDownloadComplete:self data:data error:nil];

	[fetcher release];
}

- (void)docFetcher:(GDataHTTPFetcher *)fetcher failedWithError:(NSError *)error
{
	[self endOperation];
	[m_owner googleDocsDownloadComplete:self data:nil error:error];

	[fetcher release];
}

#pragma mark Helper Methods

- (void)setDirArrary:(id)dirStringOrArray
{
	if (dirStringOrArray == nil)
	{
		self.adirPath = nil;
	}
	else if ([dirStringOrArray isKindOfClass:[NSString class]])
	{
		self.adirPath = FEmptyOrNilString(dirStringOrArray) ? nil : [NSArray arrayWithObjects: dirStringOrArray, nil];
	}
	else if ([dirStringOrArray isKindOfClass:[NSArray class]])
	{
		self.adirPath = [NSArray arrayWithArray:dirStringOrArray];
	}
	self.idirPath = 0;
	self.fDidCreateDir = NO;
}

- (void)sendFailureNotice:(NSString *)strErrorMessage code:(NSInteger)code
{
	NSError *error = NSErrorWithMessage(strErrorMessage, code);

	NSInteger gop = self.gop;
	[self endOperation];
	switch (gop)
	{
	case gopVerifyAccount:
		[m_owner googleDocsAccountVerifyComplete:self valid:NO error:error];
		break;

	case gopUploadFile:
		[m_owner googleDocsUploadComplete:self error:error];
		break;

	case gopDownloadFile:
		[m_owner googleDocsDownloadComplete:self data:nil error:error];
		break;

	case gopRetitleFiles:
		[m_owner googleDocsRetitleComplete:self success:NO count:self.ientryRetitle error:error];
		break;
	
	case gopDeleteFiles:
		[m_owner googleDocsDeleteComplete:self success:NO count:self.ientryDelete error:error];
		break;

	case gopEnsureDir:
		[m_owner googleDocsCheckFolderComplete:self exists:NO wasCreated:NO error:error];
		break;
	
	default:
		Assert(NO);
		break;
	}
}

- (void)retitleNextFile
{
	if (self.aentryRetitle != nil && self.ientryRetitle < [self.aentryRetitle count])
	{
		GDataServiceGoogleDocs *serviceDocs = [self serviceDocs:self.username password:self.password];
		GDataEntryDocBase *entryUpdate = [self.aentryRetitle objectAtIndex:self.ientryRetitle];
		[entryUpdate setTitleWithString:self.titleNew];

		NSURL *urlEdit = [[entryUpdate editLink] URL];
		DebugLog(@"urlEdit = %@", urlEdit);

		self.ticketUpload = [serviceDocs fetchDocEntryByUpdatingEntry:entryUpdate
										forEntryURL:urlEdit
										delegate:self
										didFinishSelector:@selector(uploadFileTicket:finishedWithEntry:)
										didFailSelector:@selector(uploadFileTicket:failedWithError:)];
	}
	else
	{
		// there weren't any (more) files to rename
		[self endOperation];
		[m_owner googleDocsRetitleComplete:self success:YES count:self.ientryRetitle error:nil];
	}
}

- (void)deleteNextFile
{
	if (self.aentryDelete != nil && self.ientryDelete < [self.aentryDelete count])
	{
		GDataServiceGoogleDocs *serviceDocs = [self serviceDocs:self.username password:self.password];
		GDataEntryDocBase *entryDelete = [self.aentryDelete objectAtIndex:self.ientryDelete];
		[entryDelete setTitleWithString:self.titleNew];

		self.ticketUpload = [serviceDocs deleteDocEntry:entryDelete
										delegate:self
										didFinishSelector:@selector(uploadFileTicket:finishedWithEntry:)
										didFailSelector:@selector(uploadFileTicket:failedWithError:)];
	}
	else
	{
		// there weren't any (more) files to rename
		[self endOperation];
		[m_owner googleDocsDeleteComplete:self success:YES count:self.ientryDelete error:nil];
	}
}

- (BOOL)fRetryCachedQuery
{
	if (self.fUsedCache)
	{
		// We used the cache, so stale data may have caused the failure.
		// Clear the cache and retry the operation.
		DebugLog(@"Operation failed. Clear directory path feed cache and try again.");

		self.adirPathCache = nil;
		self.urlFolderFeedCache = nil;
		self.idirPath = 0;
		
		// try again from the beginning
		Assert(self.gop != gopVerifyAccount);
		[self fetchDocListForFeed:nil title:self.title username:self.username password:self.password];
		return YES;
	}

	return NO;
}

- (void)endOperation
{
	self.gop = gopNil;
	self.fUsedCache = NO;
	
	self.dataToUpload = nil;
	self.title = nil;
	self.titleNew = nil;
	self.adirPath = nil;
	self.aentryRetitle = nil;
	self.aentryDelete = nil;
}

@end

@implementation GDataEntryDocBase (IdleLoop)

- (NSComparisonResult)compareEntriesByUpdatedDate:(GDataEntryDocBase *)docOther
{
	NSComparisonResult nscomp = NSOrderedSame;

	NSDateComponents *datecompSelf = [[docOther updatedDate] dateComponents];
	NSDateComponents *datecompOther = [[docOther updatedDate] dateComponents];

	if ([datecompSelf year] != [datecompOther year])
		nscomp = [datecompSelf year] > [datecompOther year] ? NSOrderedAscending : NSOrderedDescending;
	else if ([datecompSelf month] != [datecompOther month])
		nscomp = [datecompSelf month] > [datecompOther month] ? NSOrderedAscending : NSOrderedDescending;
	else if ([datecompSelf day] != [datecompOther day])
		nscomp = [datecompSelf day] > [datecompOther day] ? NSOrderedAscending : NSOrderedDescending;
	else if ([datecompSelf hour] != [datecompOther hour])
		nscomp = [datecompSelf hour] > [datecompOther hour] ? NSOrderedAscending : NSOrderedDescending;
	else if ([datecompSelf minute] != [datecompOther minute])
		nscomp = [datecompSelf minute] > [datecompOther minute] ? NSOrderedAscending : NSOrderedDescending;
	else if ([datecompSelf second] != [datecompOther second])
		nscomp = [datecompSelf second] > [datecompOther second] ? NSOrderedAscending : NSOrderedDescending;

	return nscomp;
}

@end

NSError *NSErrorWithMessage(NSString *strMessage, NSInteger code)
{
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
		strMessage, NSLocalizedFailureReasonErrorKey,
			nil
		];
	return [NSError errorWithDomain:s_strUserAgent code:code userInfo:dict];
}

#ifdef DEBUG
void DumpEntryArray(NSArray *aentry)
{
	if (aentry == nil)
		return;
	
	DebugLog(@"-----");
	for (GDataEntryDocBase *doc in aentry)
		DebugLog(@"%@ %@\n", [doc title], [[doc updatedDate] stringValue]);
}
#endif

