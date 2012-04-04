//
//  MSJSonError.h
//  MySeeen
//
//  Created by Thomas Ricouard on 13/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DMJSonError : NSObject


//If you use FRAPI on your server this constructor is intended to match
//a FRAPI error response, just send the dic inside an "error" response from a FRAPI server. 
-(id)initWithDictionnary:(NSDictionary *)dic; 

@property (nonatomic, strong) NSString *message; 
@property (nonatomic, strong) NSString *name; 
@property NSInteger code; 
@end
