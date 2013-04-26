//
//  NSString+TotalEscaping.h
//  MySeeen
//
//  Created by Thomas Ricouard on 28/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (TotalEscaping)

-(NSString *)stringByEscapingForURLWithString:(NSString *)string; 
@end
