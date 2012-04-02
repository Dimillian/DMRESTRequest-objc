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
@synthesize fromLogin = _fromLogin; 

-(id)initWithMethod:(NSString *)method  
          ressource:(NSString *)ressource 
         parameters:(NSArray *)array 
    shouldEscapeParameters:(BOOL)escape
{
    self = [super init]; 
    if (self) {
        _method = method; 
        _ressource = ressource; 
        _parameters = array; 
        _shouldEscape = escape; 
        
        
    }
    return self; 
}

-(NSMutableURLRequest *)constructRequest
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setTimeoutInterval:60]; 
    if ([_method isEqualToString:@"GET"]) {
        [request setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData]; 
        [request setURL:[NSURL URLWithString:
                         [NSString stringWithFormat:API_URL@"/%@.%@?%@", _ressource, FILE_EXT, [self constructParametersString]]]];
    }
    else {
        NSData *getData = [[self constructParametersString]dataUsingEncoding:NSUTF8StringEncoding 
                                                        allowLossyConversion:YES];
        NSString *getLength = [NSString stringWithFormat:@"%d", [getData length]];
        [request setURL:[NSURL URLWithString:[NSString stringWithFormat:API_URL@"/%@.%@", _ressource, FILE_EXT]]];
        [request setHTTPMethod:_method];
        [request setValue:getLength forHTTPHeaderField:@"Content-Length"];
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:getData];
    }
    return request; 
}

-(NSString *)constructParametersString
{
    NSString *parametersString = [[NSString alloc]init];
    if (_parameters) {
        for (NSString *parameter in _parameters) {
            if (_shouldEscape) {
                NSString *escapedParameter = [parameter stringByEscapingForURLWithString:parameter]; 
                parametersString = [parametersString stringByAppendingFormat:@"%@&", escapedParameter]; 
            }
            else {  
                parametersString = [parametersString stringByAppendingFormat:@"%@&", parameter]; 
            }
            
        }
        parametersString = [parametersString substringToIndex:[parametersString length] - 1];
        parametersString = [parametersString stringByReplacingOccurrencesOfString:@"%3D" withString:@"="];   
    } 
    parametersString = @""; 
    return parametersString; 
}

-(void)executeRequest
{    
    [self reset]; 
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES; 
    _connection = [[NSURLConnection alloc] initWithRequest:[self constructRequest] delegate:self];
    if (_connection) {
        _responseData = [[NSMutableData alloc] init];
        [delegate requestDidStart]; 
    }

}

-(void)executeBlockRequest:(void (^)(NSJSONSerialization *, DMJSonError *))handler
{
    [NSURLConnection sendAsynchronousRequest:[self constructRequest] queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *res, NSData *data, NSError *error){
        if (!data) {
            DMJSonError *errorRest = [[DMJSonError alloc]init]; 
            errorRest.code = error.code;
            errorRest.name = error.description; 
            handler(nil, errorRest); 
        }
        else {
            NSJSONSerialization *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];  
            if (error) {
                DMJSonError *errorRest = [[DMJSonError alloc]init]; 
                errorRest.code = error.code;
                errorRest.name = error.description; 
                handler(json, errorRest); 
            }
            else {
                handler(json, nil); 
            }

        }
    }]; 
}

-(void)cancelRequest
{
    [_connection cancel]; 
    _connection = nil; 
    _responseData = nil; 
    _sucessResponse = NO; 
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO; 
}

-(void)reset
{
    _sucessResponse = NO;  
}

#pragma mark - NSURLConnection Delegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	[_responseData setLength:0];
    
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    NSInteger responseStatusCode = [httpResponse statusCode];
    [delegate requestDidRespondWithHTTPStatus:responseStatusCode]; 

}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[_responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	if ([error code] == -1009) {
        [delegate requestDidFailBecauseNoActiveConnection];
    }
    DMJSonError *errorO = [[DMJSonError alloc]init]; 
    errorO.name = @"Connection Error"; 
    errorO.message = error.description;
    [delegate requestDidFailWithError:errorO]; 
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO; 
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	
    NSJSONSerialization *json = [NSJSONSerialization JSONObjectWithData:_responseData 
                                                                options:NSJSONReadingAllowFragments 
                                                                  error:nil];
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults]; 
    //Bonus: Show response on iOS in an alert if setting key is ON ! Cool for debugging a server directly in your 
    //app.
    if ([userDefault boolForKey:@"DEBUGMESSAGE"]) {
        NSString *responseString = [[NSString alloc]initWithData:_responseData encoding:NSUTF8StringEncoding]; 
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"DEBUG" message:responseString delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil]; 
        [alertView show];    
    }
    [delegate requestDidFinishWithJSON:json];    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO; 
    
}


@end