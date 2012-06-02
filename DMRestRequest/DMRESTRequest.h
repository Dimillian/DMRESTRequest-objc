//
//  MSRESTRequest.h
//  MySeeen
//
//  Created by Thomas Ricouard on 29/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DMRESTRequestDelegate;
@interface DMRESTRequest : NSObject <NSURLConnectionDelegate>
{
    id<DMRESTRequestDelegate>__unsafe_unretained delegate; 
    BOOL _shouldEscape; 
    BOOL _sendJSON; 
    NSString *_method; 
    NSString *_ressource; 
    NSDictionary *_parameters;
    NSMutableData *_responseData; 
    NSURLConnection *_connection; 
    
    
    //Support HTTP AUth
    NSString *_user; 
    NSString *_password; 
    NSString *_authEndPoint; 
    BOOL _alreadyTried; 
}
@property (nonatomic, strong) NSDictionary *HTTPHeaderFields; 
//Default timeout is 60
@property NSTimeInterval timeout;
@property BOOL sendJSON; 
@property (nonatomic, unsafe_unretained) id<DMRESTRequestDelegate> delegate; 
-(id)initWithMethod:(NSString *)method 
          ressource:(NSString *)ressource 
         parameters:(NSDictionary *)parameters 
shouldEscapeParameters:(BOOL)escape;


-(id)initForhHTTPAuthWithUser:(NSString *)user
                     password:(NSString *)password
                 authEndPoint:(NSString *)endPoint; 
-(void)executeHTTPAuthRequest;  

-(NSMutableURLRequest *)constructRequest; 
-(NSString *)constructParametersString; 
-(NSData *)parametersToJSON; 
-(void)executeRequest;
-(void)executeBlockRequest:(void (^)(NSURLResponse *response, NSData *data, NSError *error))handler;
-(void)cancelRequest; 


@end

@protocol DMRESTRequestDelegate <NSObject>
@required
-(void)requestDidStart;
-(void)requestDidFinishWithJSON:(NSJSONSerialization *)json; 
-(void)requestDidFailWithError:(NSError *)error; 
@optional
-(void)requestDidRespondWithHTTPStatus:(NSInteger)status; 
-(void)requestDidFinishWithData:(NSMutableData *)data; 
-(void)requestDidFailBecauseNoActiveConnection; 
-(void)requestCredentialIncorrectForHTTPAuth; 
@end
