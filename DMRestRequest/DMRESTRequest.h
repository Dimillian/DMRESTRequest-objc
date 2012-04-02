//
//  MSRESTRequest.h
//  MySeeen
//
//  Created by Thomas Ricouard on 29/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DMJSonError.h"

@protocol DMRESTRequestDelegate;
@interface DMRESTRequest : NSObject <NSURLConnectionDelegate>
{
    id<DMRESTRequestDelegate>__unsafe_unretained delegate; 
    BOOL _sucessResponse; 
    BOOL _shouldEscape; 
    NSString *_method; 
    NSString *_ressource; 
    NSArray *_parameters;
    NSMutableData *_responseData; 
    NSURLConnection *_connection; 
}
@property (nonatomic, unsafe_unretained) id<DMRESTRequestDelegate> delegate; 
@property BOOL fromLogin; 
-(id)initWithMethod:(NSString *)method 
          ressource:(NSString *)ressource 
         parameters:(NSArray *)array 
        shouldEscapeParameters:(BOOL)escape;

-(NSMutableURLRequest *)constructRequest; 
-(NSString *)constructParametersString; 
-(void)executeRequest;
-(void)executeBlockRequest:(void (^)(NSJSONSerialization *response, DMJSonError *error))handler;
-(void)cancelRequest; 
-(void)reset; 
                                                       
                                                
@end

@protocol DMRESTRequestDelegate <NSObject>
@required
-(void)requestDidStart;
-(void)requestDidFinishWithJSON:(NSJSONSerialization *)json; 
-(void)requestDidFailWithError:(DMJSonError *)error; 
@optional
-(void)requestDidRespondWithHTTPStatus:(NSInteger)status; 
-(void)requestDidFailBecauseNoActiveConnection; 
@end
