# DMRESTRequest
## Overview
**DMRESTRequest** is a super simple wrapper around **NSURLConnection** and **NSMutableRequest**. 
It's allow you to launch REST Requests to your server in 2 line, literally. 

**DMRESTRequest** built using **ARC** and targeted for iOS 5 and later, Mac OSX Snow Leopard and later. 

I wrote it as an highly re-usable class, you are invited to customize it to make it fit in your client/server implementation.

This is not a framework nor a complete solution like RESTKit is. 

**DMRESTRequest** is a utility I wrote mostly because all other frameworks was doing too much  for my need. It is aim to do simple REST Request to a server without object mapping and queuing.

## Features
1. Support 2 way of executing a request, using block or delegate. 
2. Super simple to instantiate, you have to pass the **HTTP** method you want to use, the targeted **ressource** and the **parameters** as a dictionary `key=value`
3. The class take care of building the appropriate request and the parameters data. 
4. Response trough block (also works with delegate) method when no active internet connection is available. No Reachbility needed. 
5. Work with the status bar activity indicator. 
6. I've wrote a little category to encode the parameters string in UTF-8 and escape it. It is included as **DMRESTRequest** use it. 
7. Automatic parameters converstion to JSON format for HTTPBody if needed. 
8. Basic HTTP auth support. 

## What you should know before using it

###Constants
You have to edit 2 constants, in **DMRESTRequest**, your `API_URL` and `FILE_EXT`. Those constants represent your server endpoint and the file extensions you use (ie .json).
URL string is constructed like this `API_URL/ressource.FILE_EXT?parameters`for a GET request.

###Timeout
Default `Timeout` interval is 60 seconds You can you can set:  `request.timeout = 30`.

###Sending parameters as JSON
For automatic parameters conversion to JSON format for HTTPBody just set `request.sendJSON = YES` before executing the request.
It will automagically convert your parameters to a JSON string and set thr HTTP stuff like `application/json`.

###HTTP header fields
The standard HTTP content-type is hardcoded to `application/x-www-form-urlencoded`, you're free to make it dynamic if you need a custom one. But for most/all of your requests it should works. (It's set to `application/json` if you send params as JSON).


###Custom HTTP header fields
With the property `HTTPHeaderFields` you can overwrite the default HTTP header fields by yours. Once this property is modified DMRestRequest will not add any extra parameters itself. So you have to take care of everythings. 

## Getting started
This is a really simple set of classes, ready to use, just import **DMRESTRequest**, and **NSString+TotalEscaping** in your project, import **DMRESTRequest.h**  where you wan to make requests and you're done. 

## Code example
You will find more detailled examples in the project... 

### using block method

	DMRESTRequest *blockrestRequest = [[DMRESTRequest alloc]initWithMethod:@"GET" 
                                                            ressource:@"users"
                                                           parameters:[NSDictionary dictionaryWithObject:@"Dimillian" forKey:@"user"] 
                                                    shouldEscapeParameters:YES];
    [blockrestRequest executeBlockRequest:^(NSURLResponse *response, NSData *data, NSError *error, BOOL success){
        if (error || !success) {
            //TODO show error message
        }
        else{
            //TODO do something with response
        }
    }]; 
   
   
### using delegate 

	[restRequest setDelegate:self]; 
    [restRequest executeRequest]; 

	-(void)requestDidStart
	{
	   
	}
	
	-(void)requestDidRespondWithHTTPStatus:(NSInteger)status
	{
	 
	}
	
	-(void)requestDidFinishWithJSON:(NSJSONSerialization *)json
	{
	    
	}
	
	-(void)requestDidFailWithError:(NSError *)error
	{
	   
	}
	
	-(void)requestDidFailBecauseNoActiveConnection
	{
	    
	}
	
	-(void)requestCredentialIncorrectForHTTPAuth
	{
	    
	}
	
###Cancel a request
	[restRequest cancelRequest]; 
	

	
## How to enhance it ? 
Here is a few points you should take into considerations to make this class better.

1. Add a method to inject your **OAUTH** token within **DMRESTRequest**
2. Make it more HTTP compliant. Support custom content type. 
3. Create your own JSON parsers and create your own model to match your server implementation and make them works with this class. 

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