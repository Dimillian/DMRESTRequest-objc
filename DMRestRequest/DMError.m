//
//  MSJSonError.m
//  MySeeen
//
//  Created by Thomas Ricouard on 13/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DMError.h"

@implementation DMError
@synthesize name = _name, message = _message, code = _code; 

-(id)initWithDictionnary:(NSDictionary *)dic
{
    self = [super init]; 
    if (self) {
        _message = [dic objectForKey:@"message"]; 
        _name = [dic objectForKey:@"name"];   
    }
    return self; 
}

@end
