//
//  MSRESTRequest.m
//  MySeeen
//
//  Created by Thomas Ricouard on 29/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DMRESTRequest.h"
#import "NSString+TotalEscaping.h"

typedef void (^ResponseBlock)(NSURLResponse *, NSInteger, float);
typedef void (^ProgressBlock)(NSData *, float);
typedef void (^ErrorBlock)(NSError *);
typedef void (^CompletionBlock)(NSData *);

@interface DMRESTRequest ()
{
    NSMutableData *_responseData;
    NSURLConnection *_connection;
    
    NSString *_user;
    NSString *_password;
    NSString *_authEndPoint;
    BOOL _alreadyTried;
    
    float _contentSize;
    
    
}
@property (nonatomic, copy) ResponseBlock responseBlock;
@property (nonatomic, copy) ProgressBlock progressBlock;
@property (nonatomic, copy) ErrorBlock errorBlock;
@property (nonatomic, copy) CompletionBlock completionBlock;
@property (nonatomic, readonly) DMRESTSettings *inUseSettings;
@property (nonatomic, strong) NSString *method;
@property (nonatomic, strong) NSString *ressource;
@property (nonatomic, strong) NSDictionary *parameters;
@end

@implementation DMRESTRequest
@synthesize delegate = _delegate;

-(id)initWithMethod:(NSString *)method  
          ressource:(NSString *)ressource 
         parameters:(NSDictionary *)parameters
{
    self = [super init]; 
    if (self) {
        _method = method; 
        _ressource = ressource; 
        _parameters = parameters; 
    }
    return self; 
}

-(DMRESTSettings *)inUseSettings
{
    if (_privateCustomSettings) {
        return _privateCustomSettings;
    }
    return [DMRESTSettings sharedSettings];
}


-(NSMutableURLRequest *)constructRequest
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setTimeoutInterval:self.inUseSettings.customTimemout];
    if ([_method isEqualToString:@"GET"]) { 
        [request setURL:[NSURL URLWithString:
                         [NSString stringWithFormat:@"%@/%@.%@?%@",
                          self.inUseSettings.baseURL.absoluteString,
                          _ressource,
                          self.inUseSettings.fileExtension,
                          [self constructParametersString]]]];
    }
    else {
        [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@.%@",
                                              self.inUseSettings.baseURL.absoluteString,
                                              _ressource,
                                              self.inUseSettings.fileExtension]]];
        [request setHTTPMethod:_method];
        if (![self.inUseSettings isSendJSON]) {
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
    
    if (self.inUseSettings.customHTTPHeaderFields) {
        [request setAllHTTPHeaderFields:self.inUseSettings.customHTTPHeaderFields];
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
            if ([self.inUseSettings isEscapring]) {
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
        [self.delegate requestDidStart];
    }
    
}

-(void)executeBlockRequest:(void (^)(NSURLResponse *, NSData *, NSError *, BOOL))handler
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES; 
    [NSURLConnection sendAsynchronousRequest:[self constructRequest] 
                                       queue:[NSOperationQueue currentQueue] 
                           completionHandler:^(NSURLResponse *res, NSData *data, NSError *error){
                               [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                               if (error.code == -1009) {
                                   handler(res, data, error, NO);
                               }
                               else{
                                   handler(res, data, error, YES);
                               }
                           }]; 
}

- (void)executeDetailedBlockRequestReceivedResponse:(void (^)(NSURLResponse *, NSInteger, float))responseBlock
                           progressWithReceivedData:(void (^)(NSData *, float))progressBlock
                                    failedWithError:(void (^)(NSError *))errorBlock
                                    finishedRequest:(void (^)(NSData *))completionBlock
{
    _completionBlock = completionBlock;
    _errorBlock = errorBlock;
    _responseBlock = responseBlock;
    _progressBlock = progressBlock;
    _connection = [[NSURLConnection alloc] initWithRequest:[self constructRequest] delegate:self];
    if (_connection) {
        _responseData = [[NSMutableData alloc] init];
        [self.delegate requestDidStart];
    }

}

-(void)cancelRequest
{
    [_connection cancel]; 
    _connection = nil; 
    _responseData = nil; 
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    _completionBlock = nil;
    _errorBlock = nil;
    _progressBlock = nil;
    _responseBlock = nil;
}


#pragma mark - NSURLConnection Delegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	[_responseData setLength:0];
    
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    NSInteger responseStatusCode = [httpResponse statusCode];
    if (_responseBlock) {
        _contentSize = (float)[response expectedContentLength];
        _responseBlock(response, responseStatusCode, _contentSize);
    }
    if ([self.delegate respondsToSelector:@selector(requestDidRespondWithHTTPStatus:)]) {
        [self.delegate requestDidRespondWithHTTPStatus:responseStatusCode];
    }
    
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_responseData appendData:data];
    if (_progressBlock) {
        float progress = ((float) [_responseData length] / (float) _contentSize);
        _progressBlock(_responseData, progress);
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	if ([error code] == -1009) {
        if ([self.delegate respondsToSelector:@selector(requestDidFailBecauseNoActiveConnection)]) {
            [self.delegate requestDidFailBecauseNoActiveConnection];
        }
    }
    if (_errorBlock) {
        _errorBlock(error);
    }
    [self.delegate requestDidFailWithError:error];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO; 
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	
    if(_completionBlock){
        _completionBlock(_responseData);
    }
    
    if ([self.delegate respondsToSelector:@selector(requestDidFinishWithData:)]) {
        [self.delegate requestDidFinishWithData:_responseData];
    }
    
    NSJSONSerialization *json = [NSJSONSerialization JSONObjectWithData:_responseData 
                                                                options:NSJSONReadingAllowFragments 
                                                                  error:nil];
    
    [self.delegate requestDidFinishWithJSON:json];
    
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
        [self.delegate requestDidStart];
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