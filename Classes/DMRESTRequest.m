//
//  DMRESTRequest.m
//
//  Created by Thomas Ricouard on 29/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DMRESTRequest.h"
#import "NSString+TotalEscaping.h"

typedef void (^ResponseBlock)(NSURLResponse *, NSInteger, long long);
typedef void (^ProgressBlock)(NSData *, NSData *, NSUInteger);
typedef void (^ErrorBlock)(NSError *);
typedef void (^CompletionBlock)(NSData *);
typedef void (^FullCompletionBlock)(NSURLResponse *, NSData *, NSError *, BOOL);
typedef DMRESTHTTPAuthCredential *(^HTTPAuthBlock)(void);

@interface DMRESTRequest ()
{
    NSMutableData *_responseData;
    NSURLConnection *_connection;
    NSURLResponse *_urlResponse;
    NSError *_error;
    BOOL _success;
    long long _contentSize;
    NSUInteger _currentSize;
}
@property (nonatomic, copy) ResponseBlock responseBlock;
@property (nonatomic, copy) ProgressBlock progressBlock;
@property (nonatomic, copy) ErrorBlock errorBlock;
@property (nonatomic, copy) CompletionBlock completionBlock;
@property (nonatomic, copy) HTTPAuthBlock httpAuthBlock;
@property (nonatomic, copy) FullCompletionBlock fullCompletionBlock;

@property (nonatomic, readonly) DMRESTSettings *inUseSettings;
@property (nonatomic, strong) NSString *method;
@property (nonatomic, strong) NSString *ressource;
@property (nonatomic, strong) NSDictionary *parameters;
@end

@implementation DMRESTRequest

-(id)initWithMethod:(NSString *)method  
          ressource:(NSString *)ressource 
         parameters:(NSDictionary *)parameters
{
    self = [super init]; 
    if (self) {
        _method = method; 
        _ressource = ressource; 
        _parameters = parameters;
        _contentSize = 0;
        _currentSize = 0;
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
    NSAssert(self.inUseSettings.baseURL, @"You must set a baseURL");
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setTimeoutInterval:self.inUseSettings.customTimemout];
    if ([_method isEqualToString:@"GET"]) {
        NSString *fileExt;
        if (self.inUseSettings.fileExtension) {
            fileExt = self.inUseSettings.fileExtension;
        }
        else{
            fileExt = @"";
        }
        [request setURL:[NSURL URLWithString:
                         [NSString stringWithFormat:@"%@/%@.%@?%@",
                          self.inUseSettings.baseURL.absoluteString,
                          _ressource,
                          fileExt,
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
            [request setHTTPBody:data];
        }
        else {
            NSData *jsonParameters = [self parametersToJSON];
            NSString *length = [NSString stringWithFormat:@"%d", jsonParameters.length];
            [request setValue:length forHTTPHeaderField:@"Content-Length"];
            [request setHTTPBody:jsonParameters];
        }
        [self.inUseSettings.permanentHTTPHeaderFields enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSString *stringKey = (NSString *)key;
            NSString *value = (NSString *)obj;
            [request setValue:value forHTTPHeaderField:stringKey];
        }];
        
    }
    return request; 
}

-(NSString *)constructParametersString
{
    __block NSString *parametersString = [[NSString alloc]init];
    if (_parameters) {
        [_parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if (self.inUseSettings.isEscaping) {
                if ([obj isKindOfClass:[NSString class]]) {
                    NSString *string = (NSString *)obj;
                    NSString *escapedParameter = [string stringByEscapingForURLWithString:string];
                    parametersString = [parametersString stringByAppendingFormat:@"%@=%@&", key, escapedParameter];
                }
                else{
                    parametersString = [parametersString stringByAppendingFormat:@"%@=%@&", key, obj];
                }
            }
            else{
                parametersString = [parametersString stringByAppendingFormat:@"%@=%@&", key, obj];
            }
        }];
    } 
    if (self.inUseSettings.permanentParameters) {
        [self.inUseSettings.permanentParameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            parametersString = [parametersString stringByAppendingFormat:@"%@=%@&", key, obj];
        }];
    }
    
    parametersString = [parametersString stringByReplacingOccurrencesOfString:@"%3D" withString:@"="];
    if ([parametersString length] > 0) {
        parametersString = [parametersString substringToIndex:[parametersString length] - 1];
    }
    
    if (!_parameters && !self.inUseSettings.permanentParameters) {
         parametersString = @"";
    }
    return parametersString;
}

-(NSData *)parametersToJSON
{
    NSError *error = nil;
    __block NSMutableDictionary *finalParameters = [[NSMutableDictionary alloc]init];
    [_parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [finalParameters setObject:obj forKey:key];
    }];
    if (self.inUseSettings.permanentParameters) {
        [self.inUseSettings.permanentParameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [finalParameters setObject:obj forKey:key];
        }];
    }
    return [NSJSONSerialization dataWithJSONObject:finalParameters
                                           options:NSJSONWritingPrettyPrinted 
                                             error:&error]; 
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

- (void)executeBlockRequest:(void (^)(NSURLResponse *, NSData *, NSError *, BOOL))handler
      requestAskforHTTPAuth:(DMRESTHTTPAuthCredential *(^)(void))httpAuthBlock
{
    _fullCompletionBlock = handler;
    _httpAuthBlock = httpAuthBlock;
    _responseData = [[NSMutableData alloc] init];
    _connection = [[NSURLConnection alloc] initWithRequest:[self constructRequest] delegate:self];
}

- (void)executeDetailedBlockRequestReceivedResponse:(void (^)(NSURLResponse *, NSInteger, long long))responseBlock
                              requestAskforHTTPAuth:(DMRESTHTTPAuthCredential *(^)(void))httpAuthBlock
                           progressWithReceivedData:(void (^)(NSData *, NSData *, NSUInteger))progressBlock
                                    failedWithError:(void (^)(NSError *))errorBlock
                                    finishedRequest:(void (^)(NSData *))completionBlock
{
    _completionBlock = completionBlock;
    _errorBlock = errorBlock;
    _responseBlock = responseBlock;
    _progressBlock = progressBlock;
    _httpAuthBlock = httpAuthBlock;
    _responseData = [[NSMutableData alloc] init];
    _connection = [[NSURLConnection alloc] initWithRequest:[self constructRequest] delegate:self];
}

- (void)executeRequestWithDelegate
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
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
    _fullCompletionBlock = nil;
    _currentSize = 0;
    _contentSize = 0;
}


#pragma mark - NSURLConnection Delegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	[_responseData setLength:0];
    _urlResponse = response;
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    NSInteger responseStatusCode = [httpResponse statusCode];
    if (_responseBlock) {
        _contentSize = [response expectedContentLength];
        _currentSize = 0;
        _responseBlock(response, responseStatusCode, _contentSize);
    }
    if ([self.delegate respondsToSelector:@selector(requestDidRespondWithHTTPStatus:)]) {
        [self.delegate requestDidRespondWithHTTPStatus:responseStatusCode];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_responseData appendData:data];
    if (_progressBlock) {
        _currentSize += [data length];
        _progressBlock(_responseData, data, _currentSize);
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    if ([error code] == -1009) {
        if ([self.delegate respondsToSelector:@selector(requestDidFailBecauseNoActiveConnection)]) {
            [self.delegate requestDidFailBecauseNoActiveConnection];
        }
    }
    if ([self.delegate respondsToSelector:@selector(requestDidFailWithError:)]) {
        [self.delegate requestDidFailWithError:error];
    }
    if (_errorBlock) {
        _errorBlock(error);
    }
    _error = error;
    _success = NO;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO; 
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
	_success = YES;
    if(_completionBlock){
        _completionBlock(_responseData);
    }
    if (_fullCompletionBlock) {
        _fullCompletionBlock(_urlResponse, _responseData, _error, _success);
    }
    
    if ([self.delegate respondsToSelector:@selector(requestDidFinishWithData:)]) {
        [self.delegate requestDidFinishWithData:_responseData];
    }
    
    if ([self.delegate respondsToSelector:@selector(requestDidFinishWithJSON:)]) {
        NSError *jsonError;
        NSJSONSerialization *json = [NSJSONSerialization JSONObjectWithData:_responseData
                                                                    options:NSJSONReadingAllowFragments
                                                                      error:&jsonError];
        if (!jsonError && json) {
            [self.delegate requestDidFinishWithJSON:json];
        }
    }
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO; 
    
}


#pragma mark - HTTP auth


-(void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    DMRESTHTTPAuthCredential *auth = _httpAuthBlock();
    if (auth.login && auth.password && auth.continueLogin) {
        NSURLCredential *credential = [[NSURLCredential alloc]initWithUser:auth.login
                                                                  password:auth.password
                                                               persistence:NSURLCredentialPersistenceForSession];
        
        [[challenge sender]useCredential:credential forAuthenticationChallenge:challenge]; 
    }
    else if (!auth.continueLogin){
        [[challenge sender]cancelAuthenticationChallenge:challenge];
        [self cancelRequest];
        _fullCompletionBlock(_urlResponse, nil, _error, NO);
    }
}

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection
{
    return NO; 
}

@end

@interface DMRESTHTTPAuthCredential ()
@property (nonatomic, copy, readwrite) NSString *login;
@property (nonatomic, copy, readwrite) NSString *password;
@property (nonatomic, readwrite) BOOL continueLogin;
@end

@implementation DMRESTHTTPAuthCredential
- (id)initWithLogin:(NSString *)login password:(NSString *)password continueLogin:(BOOL)continueLogin
{
    self = [super init];
    if (self) {
        _login = login;
        _password = password;
        _continueLogin = continueLogin;
    }
    return self;
}

@end
