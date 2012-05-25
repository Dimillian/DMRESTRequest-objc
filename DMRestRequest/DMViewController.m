//
//  DMViewController.m
//  DMRestRequest
//
//  Created by Thomas Ricouard on 02/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DMViewController.h"

@interface DMViewController ()

@end

@implementation DMViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //usage exemple
    
    //Block method, short method without using the delegate. 
    DMRESTRequest *blockrestRequest = [[DMRESTRequest alloc]initWithMethod:@"GET" 
                                                            ressource:@"users"
                                                           parameters:[NSDictionary dictionaryWithObject:@"Dimillian" forKey:@"user"] 
                                                    shouldEscapeParameters:YES];
    [blockrestRequest executeBlockRequest:^(NSJSONSerialization *json, NSError *error){
        if (error) {
            //TODO show error message
        }
        else{
            //TODO do something with json
        }
    }]; 
    
    //Using delegate
    //you should cancel the previous request before launching a new one if referenced as a class variable.
    [restRequest cancelRequest]; 
    
    restRequest = [[DMRESTRequest alloc]initWithMethod:@"GET" 
                                             ressource:@"users"
                                            parameters:
                                        [NSDictionary dictionaryWithObject:@"Dimillian" forKey:@"user"] 
                                        shouldEscapeParameters:YES];
    [restRequest setDelegate:self]; 
    [restRequest executeRequest]; 
    
    
    //Other examples with multiple parameters and other properties
    DMRESTRequest *newRequest = [[DMRESTRequest alloc]initWithMethod:@"POST" 
                                                                 ressource:@"users"
                                                                parameters:
                        [NSDictionary dictionaryWithObjectsAndKeys:@"13", @"userId", @"Dimillian", @"username", nil]                    shouldEscapeParameters:YES];
    newRequest.timeout = 50; 
    newRequest.sendJSON = YES; 
    [newRequest setHTTPHeaderFields:[NSDictionary dictionaryWithObject:@"From: user@example.com" forKey:@"From"]]; 
    [newRequest executeRequest]; 
    [newRequest cancelRequest]; 
    
}

#pragma mark - DMRestRequest delegate

-(void)requestDidStart
{
    //The request just started, you should start your loading screen or something
}

-(void)requestDidRespondWithHTTPStatus:(NSInteger)status
{
    //Useful if you rely on HTTP status code on your client to do some opérations. 
    //This delegate will be called first after requestDidStart.
    
    //ie if(status==200) OK
}

-(void)requestDidFinishWithJSON:(NSJSONSerialization *)json
{
    //Request is finished with success and you have the full JSON response from your server. 
    //The response can be an NSDictionnary or an NSArray (mutable). 
    
    //ie: NSDictionary *jsonDic = (NSDictionary*)json; 
    
    //This is where you can parse it into your model object and start doing some crazy shit
}

-(void)requestDidFailWithError:(NSError *)error
{
    //Request did fail with an error, check the error to know why and refresh your UI. 
}

-(void)requestDidFailBecauseNoActiveConnection
{
    //No active connection detected
    //you should display en error message
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
