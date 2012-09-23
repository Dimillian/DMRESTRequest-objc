//
//  MSRESTRequest.m
//  MySeeen
//
//  Created by Thomas Ricouard on 29/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DMRESTRequest.h"
#import "NSString+TotalEscaping.h"

#define FILE_EXT @"json"
#define API_URL @"http://exemple.com"

@implementation DMRESTRequest
@synthesize delegate;
@synthesize HTTPHeaderFields = _HTTPHeaderFields; 
@synthesize sendJSON = _sendJSON; 
@synthesize timeout; 


-(id)initWithMethod:(NSString *)method  
          ressource:(NSString *)ressource 
         parameters:(NSDictionary *)parameters 
shouldEscapeParameters:(BOOL)escape
{
    self = [super init]; 
    if (self) {
        _method = method; 
        _ressource = ressource; 
        _parameters = parameters; 
        _shouldEscape = escape; 
        _HTTPHeaderFields = nil; 
        _sendJSON = NO; 
        timeout = 60; 
    }
    return self; 
}


-(NSMutableURLRequest *)constructRequest
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setTimeoutInterval:timeout]; 
    if ([_method isEqualToString:@"GET"]) { 
        [request setURL:[NSURL URLWithString:
                         [NSString stringWithFormat:API_URL@"/%@.%@?%@", _ressource, FILE_EXT, [self constructParametersString]]]];
    }
    else {
        [request setURL:[NSURL URLWithString:[NSString stringWithFormat:API_URL@"/%@.%@", _ressource, FILE_EXT]]];
        [request setHTTPMethod:_method];
        if (!_sendJSON) {
            NSData *data = [[self constructParametersString]dataUsingEncoding:NSUTF8StringEncoding 
                                                         allowLossyConversion:YES];
            NSString *length = [NSString stringWithFormat:@"%d", [data length]];
            [request setValue:length forHTTPHeaderField:@"Content-Length"];
            [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
            [request setHTTPBody:data];
        }
        else {
            NSString *length = [NSString stringWithFormat:@"%d", [self parametersToJSON].length]; 
            [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            [request setValue:length forHTTPHeaderField:@"Content-Length"];
            [request setHTTPBody:[self parametersToJSON]]; 
        }
        
    }
    
    if (self.HTTPHeaderFields) {
        [request setAllHTTPHeaderFields:self.HTTPHeaderFields]; 
    }
    return request; 
}

-(NSString *)constructParametersString
{
    NSString  *parametersString = [[NSString alloc]init];
    if (_parameters) {
        NSEnumerator *enumerator = [_parameters keyEnumerator];
        //Sure you can prefer the block enumerator...
        for(NSString *aKey in enumerator){
            NSString *value = [_parameters valueForKey:aKey]; 
            if (_shouldEscape) {
                if ([value isKindOfClass:[NSString class]]) {
                    NSString *escapedParameter = [value stringByEscapingForURLWithString:value]; 
                    parametersString = [parametersString stringByAppendingFormat:@"%@=%@&", aKey, escapedParameter]; 
                }
                else {
                    parametersString = [parametersString stringByAppendingFormat:@"%@=%@&", aKey, value]; 
                }
            }
            else {  
                parametersString = [parametersString stringByAppendingFormat:@"%@=%@&", aKey, value]; 
            }
        }
        parametersString = [parametersString stringByReplacingOccurrencesOfString:@"%3D" withString:@"="];
        if ([parametersString length] > 0) {
            parametersString = [parametersString substringToIndex:[parametersString length] - 1];
        }
    } 
    else {
        parametersString = @""; 
    }
    return parametersString; 
}

-(NSData *)parametersToJSON
{
    NSError *error = nil; 
    
    return [NSJSONSerialization dataWithJSONObject:_parameters 
                                           options:NSJSONWritingPrettyPrinted 
                                             error:&error]; 
}

-(void)executeRequest
{   
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES; 
    _connection = [[NSURLConnection alloc] initWithRequest:[self constructRequest] delegate:self];
    if (_connection) {
        _responseData = [[NSMutableData alloc] init];
        [delegate requestDidStart]; 
    }
    
}

-(void)executeBlockRequest:(void (^)(NSURLResponse *, NSData *, NSError *))handler
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES; 
    [NSURLConnection sendAsynchronousRequest:[self constructRequest] 
                                       queue:[NSOperationQueue currentQueue] 
                           completionHandler:^(NSURLResponse *res, NSData *data, NSError *error){
                               [UIApplication sharedApplication].networkActivityIndicatorVisible = NO; 
                               handler(res, data, error); 
                           }]; 
}

-(void)cancelRequest
{
    [_connection cancel]; 
    _connection = nil; 
    _responseData = nil; 
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO; 
}


#pragma mark - NSURLConnection Delegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	[_responseData setLength:0];
    
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    NSInteger responseStatusCode = [httpResponse statusCode];
    if ([delegate respondsToSelector:@selector(requestDidRespondWithHTTPStatus:)]) {
        [delegate requestDidRespondWithHTTPStatus:responseStatusCode]; 
    }
    
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[_responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	if ([error code] == -1009) {
        if ([delegate respondsToSelector:@selector(requestDidFailBecauseNoActiveConnection)]) {
            [delegate requestDidFailBecauseNoActiveConnection];   
        }
    }
    [delegate requestDidFailWithError:error]; 
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO; 
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	
    if ([delegate respondsToSelector:@selector(requestDidFinishWithData:)]) {
        [delegate requestDidFinishWithData:_responseData];   
    }
    
    NSJSONSerialization *json = [NSJSONSerialization JSONObjectWithData:_responseData 
                                                                options:NSJSONReadingAllowFragments 
                                                                  error:nil];
    
    [delegate requestDidFinishWithJSON:json];  
    
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults]; 
    //Bonus: Show response on iOS in an alert if setting key is ON ! Cool for debugging a server right from you app.
    if ([userDefault boolForKey:@"DEBUGMESSAGE"]) {
        NSString *responseString = [[NSString alloc]initWithData:_responseData encoding:NSUTF8StringEncoding]; 
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"DEBUG" message:responseString delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil]; 
        [alertView show];    
    }
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO; 
    
}


#pragma mark - HTTP auth


-(id)initForhHTTPAuthWithUser:(NSString *)user password:(NSString *)password authEndPoint:(NSString *)endPoint
{
    self = [super init]; 
    if (self) {
        _user = user; 
        _password = password; 
        _authEndPoint = endPoint; 
    }
    
    return self; 
}

-(void)executeHTTPAuthRequest{
    
    _alreadyTried = NO; 
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:_authEndPoint]];
    _connection = [[NSURLConnection alloc]initWithRequest:urlRequest delegate:self]; 
    if (_connection) {
        _responseData = [[NSMutableData alloc] init];
        [delegate requestDidStart]; 
    }
}

-(void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if (_user && _password && !_alreadyTried) {
        NSURLCredential *credential = [[NSURLCredential alloc]initWithUser:_user 
                                                                  password:_password 
                                                               persistence:NSURLCredentialPersistenceForSession];
        
        [[challenge sender]useCredential:credential forAuthenticationChallenge:challenge]; 
        _alreadyTried = YES; 
    }
    else {
        [[challenge sender]cancelAuthenticationChallenge:challenge]; 
        [self.delegate requestCredentialIncorrectForHTTPAuth]; 
    }    
}

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection
{
    return NO; 
}



@end