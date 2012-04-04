# DMRESTRequest
## Overview
**DMRESTRequest** is a super simple wrapper around **NSURLConnection** and **NSMutableRequest**. 
It allow you to lauch REST Requests to your server in 2 line, literraly. 

It's built using **ARC** and targeted for iOS 5. 

I've wrote it as an highly re-usable class, you are invited to customize it to make it fit in your client/server implementation.

This is not a framework or a complete solution like RESTKit is. 
**DMRESTRequest** is a utility I wrote mostly because all other frameworks was too much complicated for my need. It is aim to do simple REST Request to a server without object mapping, network management, queing etc...

## Features
1. Support 2 way of executing a request, using block or delegate. 
2. Super simple to instantiate, you have to pass the **HTTP** method you want to use, the targeted **ressource** and the **parameters** as a dictionnary `key=value`
3. The class take care of building the appropriate request and the parameters data. 
4. Response trought a delegate method when no active connection is available. No Reachbility needed. 
5. Work with the status bar activity indicator. 
6. I've wrote a little categorie to encode the parametters string in UTF-8 and escape it. It is included as **DMRESTRequest** use it. 

## What you should know before using it
You have to edit 2 constants, in **DMRESTRequest**, your `API_URL` and `FILE_EXT`. Those constants represent your server endpoint and the file extensions you use (ie .json).
URL string is constructed like this `API_URL/ressource.FILE_EXT?parameters`

The standard HTTP content-type is hardoced to `application/x-www-form-urlencoded`, you're free to make it dynamic if you need a custom one. But for most/all of your requests it should works. 

Default `Timeout` interval is 60 seconds, support custom HTTP header fields. Both are properties that you can set:  `request.timeout = 30`. 

## Getting started
This is a really simple set of classes, ready to use, just import **DMRESTRequest**, **DMError** and **NSString+TotalEscaping** in your project, import **DMRESTRequest.h**  where you wan to make requests and you're done. 

## Code example
You will find more detailled examples in the project... 

### using block method

	 restRequest = [[DMRESTRequest alloc]initWithMethod:@"GET" 
                                             ressource:@"users"
                                            parameters:
				[NSDictionary dictionaryWithObject:@"Dimillian" forKey:@"user"] 
                                        shouldEscapeParameters:YES];

    [restRequest executeBlockRequest:^(NSJSONSerialization *json, DMError *error){
        if (error) {
 			//error
        }
        else {
            //TODO do something with json
        }
    }];`
   
   
### using delegate 
     restRequest = [[DMRESTRequest alloc]initWithMethod:@"GET" 
                                             ressource:@"users"
                                            parameters:
				[NSDictionary dictionaryWithObject:@"Dimillian" forKey:@"user"] 
                                        shouldEscapeParameters:YES];
    [restRequest setDelegate:self]; 
    [restRequest executeRequest]; 
    
    //delegate methodes available. 
    
    -(void)requestDidStart
	{
		
	}

	-(void)requestDidRespondWithHTTPStatus:(NSInteger)status
	{
	
	}

	-(void)requestDidFinishWithJSON:(NSJSONSerialization *)	json
	{

	}

	-(void)requestDidFailWithError:(DMError *)error
	{
	}

	-(void)requestDidFailBecauseNoActiveConnection
	{
	}
	
## How to enhance it ? 
Here is a few points you should take into considerations to make this class better.

1. You can enhance the custom model for error handling to make it match your server error response.
3. Add some authentification support. 
4. Make it more HTTP complient. Support custom content type. 
5. Create your own JSON parsers and create your own model to match your server implementation and make them works with this class. 

## Licensing 
Copyright (C) 2012 by Thomas Ricouard. 

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.