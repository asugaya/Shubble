//
//  SocketTestViewController.m
//  SocketTest
//
//  Created by Travis Wyatt on 9/23/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "SocketTestViewController.h"


@interface SocketTestViewController (Private)
- (void)connect;
- (void)sendHTTPRequest;
- (void)readWithTag:(long)tag;
- (void)openShubbleRequest;
@end

@implementation SocketTestViewController

#pragma mark -
#pragma mark View Lifecycle

- (id)initWithTime:(int)time {
	timeBetweenKnocks = time;
    socket = [[AsyncSocket alloc] initWithDelegate:self];
	[self connect];
    
}

- (id)init {
    //    [super viewDidLoad];
    timeBetweenKnocks = 10;
	socket = [[AsyncSocket alloc] initWithDelegate:self];
	[self connect];
}

- (void) connectToShubble {
    socket = [[AsyncSocket alloc] initWithDelegate:self];
	[self connect];
}

#pragma mark -

- (void)connect {
	[socket connectToHost:@"codebanana.com" onPort:50003 error:nil];
}

- (void)openShubbleRequest {
    NSString *string =   [NSString stringWithFormat:@"%d \r\n", timeBetweenKnocks]; 
	NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
	
	NSLog(@"Sending HTTP Request.");
	[socket writeData:data withTimeout:-1 tag:1];
}

- (void)readWithTag:(long)tag {
	// reads response line-by-line
	[socket readDataToData:[AsyncSocket CRLFData] withTimeout:-1 tag:tag];
}

#pragma mark -
#pragma mark AsyncSocket Methods

- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err {
	NSLog(@"Disconnecting. Error: %@", [err localizedDescription]);
}

- (void)onSocketDidDisconnect:(AsyncSocket *)sock {
	NSLog(@"Disconnected.");
	
	[socket setDelegate:nil];
	[socket release];
	socket = nil;
}

- (BOOL)onSocketWillConnect:(AsyncSocket *)sock {
	NSLog(@"onSocketWillConnect:");
	return YES;
}

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
	NSLog(@"Connected To %@:%i.", host, port);
	
	[self readWithTag:2];
	[self openShubbleRequest];
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
	/**
	 * Convert data to a string for logging.
	 *
	 * http://stackoverflow.com/questions/550405/convert-nsdata-bytes-to-nsstring
	 */
	NSString *string = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
	NSLog(@"Received Data (Tag: %i): %@", tag, string);
    
    NSString *trimmedString = [string stringByTrimmingCharactersInSet:
                               [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    
    NSURL *url = [NSURL URLWithString:trimmedString];
    if( ![[UIApplication sharedApplication] openURL:url] )
        NSLog(@"%@%@",@"Failed to open url:",[url description]);

    
    NSLog(@"should be opening url");
    //openURL(string);
    
	[string release];
    
	[self readWithTag:3];
}

- (void)onSocket:(AsyncSocket *)sock didReadPartialDataOfLength:(CFIndex)partialLength tag:(long)tag {
	NSLog(@"onSocket:didReadPartialDataOfLength:%i tag:%i", partialLength, tag);
}

- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag {
	NSLog(@"onSocket:didWriteDataWithTag:%i", tag);
}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
	[socket release];
//	[super dealloc];
}

@end
