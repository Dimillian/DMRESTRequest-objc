//
//  MSRESTRequest.h
//  MySeeen
//
//  Created by Thomas Ricouard on 29/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DMError.h"

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


-(id)initWithMethod:(NSString *)method 
          ressource:(NSString *)ressource 
         parameters:(NSDictionary *)parameters 
               user:(NSString *)user
           password:(NSString *)password
        shouldEscapeParameters:(BOOL)escape;

-(NSMutableURLRequest *)constructRequest; 
-(NSString *)constructParametersString; 
-(NSData *)parametersToJSON; 
-(void)executeRequest;
-(void)executeBlockRequest:(void (^)(NSJSONSerialization *response, DMError *error))handler;
-(void)cancelRequest; 
                                                       
                                                
@end

@protocol DMRESTRequestDelegate <NSObject>
@required
-(void)requestDidStart;
-(void)requestDidFinishWithJSON:(NSJSONSerialization *)json; 
-(void)requestDidFailWithError:(DMError *)error; 
@optional
-(void)requestDidRespondWithHTTPStatus:(NSInteger)status; 
-(void)requestDidFinishWithData:(NSMutableData *)data; 
-(void)requestDidFailBecauseNoActiveConnection; 
@end
