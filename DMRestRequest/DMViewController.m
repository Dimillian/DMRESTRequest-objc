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
    [[DMRESTSettings sharedSettings]setBaseURL:[NSURL URLWithString:@"https://api.virtual-info.info"]];
    [[DMRESTSettings sharedSettings]setFileExtension:@"json"];
    //Adding some permanent parameter like a AuthToken
    [[DMRESTSettings sharedSettings]setPermananentParameterValue:@"1234" forParameter:@"AuthToken"];
    NSLog(@"%@", [[DMRESTSettings sharedSettings]valueForPermanentParameter:@"AuthToken"]);
    //usage exemple
    
    //Block method, short method without using the delegate. 
    DMRESTRequest *blockrestRequest = [[DMRESTRequest alloc]initWithMethod:@"GET" 
                                                            ressource:@"self"
                                                                parameters:@{@"user": @"Dimillian"}];
    [blockrestRequest executeBlockRequest:^(NSURLResponse *response, NSData *data, NSError *error, BOOL success){
        if (error || !success) {
            //TODO show error message
        }
        else{
            NSJSONSerialization *json = [NSJSONSerialization JSONObjectWithData:data
                                                                        options:NSJSONReadingAllowFragments
                                                                          error:nil];
            NSLog(@"%@", json);
            //TODO do something with response
        }
    }];
    
    
    //Complexe block usage
    DMRESTRequest *complexeBlockRequest = [[DMRESTRequest alloc]initWithMethod:@"GET"
                                                                 ressource:@"self"
                                                                    parameters:@{@"user": @"Dimillian"}];
    [complexeBlockRequest
     executeDetailedBlockRequestReceivedResponse:^(NSURLResponse *response, NSInteger httpStatusCode, float exeptedContentSize) {
         NSLog(@"Size: %f", exeptedContentSize);
         NSLog(@"HTTP Status: %d", httpStatusCode);
        
    } progressWithReceivedData:^(NSData *data, float progress) {
        NSLog(@"Progress: %f", progress);
        
    } failedWithError:^(NSError *error) {
        
    } finishedRequest:^(NSData *completeData) {
        NSJSONSerialization *json = [NSJSONSerialization JSONObjectWithData:completeData
                                                                    options:NSJSONReadingAllowFragments
                                                                      error:nil];
        NSLog(@"Complexe block: %@", json);
    }];
    
    //Using JSON in BODY with private settings, so only for 1 request
    DMRESTSettings *settings = [[DMRESTSettings alloc]initForPrivateSettingsFromSharedSettings];
    [settings setSendJSON:YES];
    [settings setUserAgent:@"DMRESTRequest/version type/JSON"];
    DMRESTRequest *postRequest = [[DMRESTRequest alloc]initWithMethod:@"POST"
                                                        ressource:@"self"
                                                       parameters:@{@"user": @"dimillian",
                              @"movies": [NSNumber numberWithInt:1]}];
    [postRequest setPrivateCustomSettings:settings];
    [postRequest executeBlockRequest:^(NSURLResponse *response, NSData *data, NSError *error, BOOL success) {
        if (success) {
            NSJSONSerialization *json = [NSJSONSerialization JSONObjectWithData:data
                                                                        options:NSJSONReadingAllowFragments
                                                                          error:nil];
            NSLog(@"%@", json);
        }
    }];
    
    //Using delegate
    //you should cancel the previous request before launching a new one if referenced as a class variable.
    [restRequest cancelRequest]; 
    
    restRequest = [[DMRESTRequest alloc]initWithMethod:@"GET" 
                                             ressource:@"users"
                                            parameters:
                   [NSDictionary dictionaryWithObject:@"Dimillian" forKey:@"user"]];
    [restRequest setDelegate:self];
    [restRequest executeRequest]; 
    
    //Other examples with multiple parameters and other properties
    DMRESTRequest *newRequest = [[DMRESTRequest alloc]initWithMethod:@"POST" 
                                                                 ressource:@"users"
                                                                parameters:
                                 [NSDictionary dictionaryWithObjectsAndKeys:@"13", @"userId", @"Dimillian", @"username", nil]];
    DMRESTSettings *privateSettings = [[DMRESTSettings alloc]initForPrivateSettingsWithBaseURL:
                                       [NSURL URLWithString:@"http://google.com"]
                                                                                 fileExtension:@"json"];
    privateSettings.customTimemout = 40;
    privateSettings.sendJSON = YES;
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

-(void)requestCredentialIncorrectForHTTPAuth
{
    //Crendential provided incorect
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
