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
- (void)openURL:(NSString *) string;
@end

@implementation SocketTestViewController

#pragma mark -
#pragma mark View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	socket = [[AsyncSocket alloc] initWithDelegate:self];
	[self connect];
    
    SocketTestViewController *viewController = [[SocketTestViewController alloc] init];
}

- (void) connectToShubble {
    socket = [[AsyncSocket alloc] initWithDelegate:self];
	[self connect];
}

#pragma mark -

- (void)connect {
	[socket connectToHost:@"codebanana.com" onPort:50007 error:nil];
}

- (void)sendHTTPRequest {
	NSString *string =   [[NSString alloc] initWithString:@"welcome\r\n"];
	NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
	[string release];
	
	NSLog(@"Sending HTTP Request.");
	[socket writeData:data withTimeout:-1 tag:1];
}

- (void)openShubbleRequest {
    NSString *string =   [[NSString alloc] initWithString:@"open_shubble\r\n"];
	NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
	[string release];
	
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
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"www.google.com"]];
    
    NSLog(@"should be opening url");
    //openURL(string);
    
	[string release];
	
	[self readWithTag:3];
        
}

- (void) openURL:(NSString *) string {
    // Be careful to always URL encode things like spaces and other symbols that aren't URL friendly
    // Shouldn't need this, Shubble server returns the direct url
    //string =  [string stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
    
    // An the final magic ... openURL!
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:string]];

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
	[super dealloc];
}

@end
