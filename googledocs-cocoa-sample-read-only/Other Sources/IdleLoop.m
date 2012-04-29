//
//  IdleLoop.m
//  GoogleDocs
//
//  Created by Tom Saxton on 12/7/08.
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

#import "IdleLoop.h"

#include <memory.h>

#pragma mark String Utilities

BOOL FEmptyOrNilString(NSString *str)
{
	return str == nil || [str isEqual:@""];
}

@implementation NSData (IdleLoop)

// REVIEW: Customize this string to tell the user what they are looking at.
//
// NOTE: if using this to upload to a Google Docs account,
// don't include a <title> tag otherwise the title you set on the
// GDataEntryDocBase will be ignored.
//
// NOTE: the last non-whitespace in the prefix has to be "<pre>", and
// the first non-whitespace in the suffix has to be </pre>.
//
static const char s_szPrefix[] =
	"<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">\n"
	"<html>\n"
	"\n"
	"<head>\n"
#if 0 // see note above
	"<title>Your Custom App Data</title>\n"
#endif
	"</head>\n"
	"\n"
	"<body>\n"
	"\n"
	"<p>\n"
	"Your Custom App data is not currently user-editable.\n"
	"</p>\n"
	"<pre>\n"
	;
static const char s_szSuffix[] =
	"\n"
	"</pre>\n"
	"\n"
	"</body>\n"
	"</html>\n"
	;

// arrays used to encode to hex and decode from hex
static const char s_achHex[] = "0123456789ABCDEF";
static UInt8 s_mp_ch_val[256];

#define _FAsciiToDecTableValid() (s_mp_ch_val['1'] == 1)

static void _InitAsciiToDecTable()
{
	memset(s_mp_ch_val, 0xFF, sizeof(s_mp_ch_val));

	char ch;

	for (ch = '0'; ch <= '9'; ++ch)
		s_mp_ch_val[ch] = ch - '0';
	for (ch = 'a'; ch <= 'f'; ++ch)
		s_mp_ch_val[ch] = ch - 'a' + 10;
	for (ch = 'A'; ch <= 'F'; ++ch)
		s_mp_ch_val[ch] = ch - 'A' + 10;
}

- (NSData *)dataEncodeToHtml
{
	const int cbLineLength = 32;
	// allocate buffer for the full output data
	NSInteger cbSrc = [self length];
	NSInteger cbBuffer = sizeof(s_szPrefix) + sizeof(s_szSuffix) - 2 + 2 * cbSrc + cbSrc/cbLineLength;
	UInt8 *pabBuffer = malloc(cbBuffer);
	
	// get ready to start blasting in data
	UInt8 *pbDst = pabBuffer;
	
	// blast in the prefix
	memcpy(pbDst, s_szPrefix, sizeof(s_szPrefix)-1);
	pbDst += sizeof(s_szPrefix)-1;
	
	// blast the source data into the next chunk of the output buffer
	const UInt8 *pbSrc = [self bytes];
	const UInt8 *pbSrcLim = pbSrc + cbSrc;

	DebugLog(@"encoding %d bytes", cbSrc);

	// perform the conversion
	int cbLine = 0;
	while (pbSrc < pbSrcLim)
	{
		UInt8 b = *pbSrc++;
		*pbDst++ = s_achHex[((b & 0xF0) >> 4)];
		*pbDst++ = s_achHex[(b & 0xF)];
		if (++cbLine >= cbLineLength)
		{
			*pbDst++ = '\n';
			cbLine = 0;
		}
	}

#ifdef DEBUG
	int cbHex = pbDst - &pabBuffer[sizeof(s_szPrefix)-1];
	int cbExpect = 2*cbSrc + cbSrc/cbLineLength;
	DebugLog(@"cbSrc = %d, cbHex = %d, cbExpect = %d", cbSrc, cbHex, cbExpect);
	Assert(cbHex == cbExpect);
#endif
	
	// verify our clever in-place conversion ended where we expected
	Assert(pbDst == &pabBuffer[cbBuffer - (sizeof(s_szSuffix) - 1)]);
	
	// blast in the suffix
	memcpy(pbDst, s_szSuffix, sizeof(s_szSuffix)-1);
	pbDst += sizeof(s_szSuffix)-1;
	
	// verify we ended at the end of the output buffer
	Assert(pbDst == &pabBuffer[cbBuffer]);
	DebugLog(@"encoded size: %d bytes", pbDst - pabBuffer);

	// create the output data object
	NSData *dataEncoded = [NSData dataWithBytes:pabBuffer length:cbBuffer];
	
	// free the output buffer
	free(pabBuffer);

	return dataEncoded;
}

- (NSData *)dataDecodeFromHtml
{
	// initialize the table that maps ASCII values to decimal values
	if (!_FAsciiToDecTableValid())
		_InitAsciiToDecTable();

	// allocate our buffer for in-place conversion
	NSInteger cbSrc = [self length];
	UInt8 *pabBuffer = malloc(cbSrc);

	// get the input data
	[self getBytes:pabBuffer length:cbSrc];

	// scan for the start of our content
	UInt8 *pbSrc = pabBuffer;
	UInt8 *pbSrcLim = &pabBuffer[cbSrc];
	UInt8 bPrev = 0;
	BOOL fHavePrefix = NO;
	while (pbSrc < pbSrcLim && !fHavePrefix)
	{
		UInt8 bCur = tolower(*pbSrc++);
		switch (bPrev)
		{
		case 0:
			if (bCur != '<')
				bCur = 0;
			break;
		case '<':
			if (bCur != 'p')
				bCur = 0;
			break;
		case 'p':
			if (bCur != 'r')
				bCur = 0;
			break;
		case 'r':
			if (bCur != 'e')
				bCur = 0;
			break;
		case 'e':
			if (bCur == '>')
				fHavePrefix = YES;
			else
				bCur = 0;
			break;
		}
		bPrev = bCur;
	}
	
	// prepare for error return
	NSData *dataDecoded = nil;
	
	if (pbSrc < pbSrcLim)
	{	
		// convert hex doublettes to bytes
		UInt8 *pbDst = pabBuffer;
		while (pbSrc < pbSrcLim-1)
		{
			UInt8 b1 = *pbSrc++;
			if (b1 == '<')
				break;
			if (b1 <= ' ')
				continue;
			b1 = s_mp_ch_val[b1];
			if (b1 == 0xFF)
			{
				DebugLog(@"Invalid byte encountered in data stream");
				goto LReturn;
			}

			UInt8 b2 = s_mp_ch_val[*pbSrc++];
			if (b2 == 0xFF)
			{
				DebugLog(@"Invalid byte encountered in data stream");
				goto LReturn;
			}
			
			*pbDst++ = (b1 << 4) + b2;
		}
		
		
		NSUInteger cbData = pbDst - pabBuffer;
		DebugLog(@"decoded %d bytes", cbData);
		dataDecoded = [NSData dataWithBytes:pabBuffer length:cbData];
	}

LReturn:
	free(pabBuffer);
	return dataDecoded;
}

@end
