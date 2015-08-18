//
//  ServerRequester.swift
//  Origami
//
//  Created by CloudCraft on 08.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class ServerRequester: NSObject
{
    typealias networkResult = (AnyObject?,NSError?) -> ()
    
    let httpManager:AFHTTPRequestOperationManager = AFHTTPRequestOperationManager()
    
    //MARK: User
    func registerNewUser(firstName:String, lastName:String, userName:String, completion:(success:Bool, error:NSError?) ->() )
    {
        var requestString:String = "\(serverURL)" + "\(registerUserUrlPart)"
        var parametersToRegister = [firstNameKey:firstName, lastNameKey:lastName, loginNameKey:userName]
        
        let operation = httpManager.GET(
            requestString,
            parameters: parametersToRegister,
            success:
            { (operation, resultObject)  in
                completion(success: true, error: nil)
        })
        { (operation, error)  in
            completion(success: false, error: error)
        }
        
        operation.start()
    }
    
    func editUser(userToEdit:User, completion:(success:Bool, error:NSError?) -> () )
    {
        var requestString:String = "\(serverURL)" + "\(editUserUrlPart)"
        var params = ["user":userToEdit]
        
        var jsonSerializer = httpManager.responseSerializer
        let acceptableTypes:NSSet = jsonSerializer.acceptableContentTypes as NSSet
      
        var newSet = NSMutableSet(set: acceptableTypes)
        newSet.addObjectsFromArray(["text/html", "application/json"])
        jsonSerializer.acceptableContentTypes = newSet as Set<NSObject>
        
        let editOperation = httpManager.POST(
            requestString,
            parameters: params,
            success:
            { (operation, resultObject) -> Void in
                completion(success: true, error: nil)
            
        })
            { (operation, responseError) -> Void in
            completion(success: false, error: responseError)
        }
        
        editOperation.start()
    }
    
    func loginWith(userName:String, password:String, completion:networkResult)
    {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        var requestString:String = "\(serverURL)" + "\(loginUserUrlPart)"
        var params = ["username":userName, "password":password]
        
        let loginOperation = httpManager.GET(
            requestString,
            parameters: params,
            success:
            { (operation, responseObject) -> Void in
            
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                if let
                    dictionary = responseObject as? [String:AnyObject],
                    userDict = dictionary["LoginResult"] as? [String:AnyObject]
                {
                    let user = User(info: userDict)
                    completion(user, nil)
                }
                else
                {
                    let lvError = NSError(domain: "Login Error", code: 701, userInfo: [NSLocalizedDescriptionKey:"Could not login, please try once more"])
                    completion(nil, lvError)
                }
                
        })
            { (operation, responseError) -> Void in
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                if let errorMessage = operation.responseString
                {
                    let lvError = NSError(domain: "Login Error", code: 701, userInfo: [NSLocalizedDescriptionKey:errorMessage])
                    completion(nil, lvError);
                }
                else
                {
                    completion(nil, responseError);
                }
        }
        
        loginOperation.start()
        
    }
    
    //MARK: Elements
    func loadAllElements(completion:networkResult)
    {
        if let tokenString = DataSource.sharedInstance.user?.token as? String
        {
            let params = [tokenKey:DataSource.sharedInstance.user?.token as! String]
        
            var requestString = "\(serverURL)" + "\(getElementsUrlPart)"
            let requestOperation = httpManager.GET(
                requestString,
                parameters:params,
                success:
                { (operation, responseObject) -> Void in
                    if let dictionary = responseObject as? [String:AnyObject],
                        elementsArray = dictionary["GetElementsResult"] as? [[String:AnyObject]]
                    {
                        var elements = [Element]()
                        for lvElementDict in elementsArray
                        {
                            let type = lvElementDict["TypeId"] as? Int
                            //println(" -> element type: \(type) \n")
                            let lvElement = Element(info: lvElementDict)
                            //println("\(lvElement.toDictionary())")
                            elements.append(lvElement)
                        }
                        completion(elements,nil)
                    }
                    else
                    {
                        completion(nil,NSError())
                    }
                    
            },
                failure:
                { (operation, responseError) -> Void in
                completion(nil, responseError)
            })
        }
        else
        {
            completion(nil,noUserTokenError)
        }
    }
    
    func submitNewElement(element:Element, completion:networkResult)
    {
        if let tokenString = DataSource.sharedInstance.user?.token as? String
        {
            NSOperationQueue().addOperationWithBlock({ [unowned self]() -> Void in
                let elementDict = element.toDictionary()
           
                let postString = serverURL + addElementUrlPart + "?token=" + "\(tokenString)"
                let params = ["element":elementDict]
                
                var requestSerializer = AFJSONRequestSerializer()
                requestSerializer.timeoutInterval = 15.0 as NSTimeInterval
                requestSerializer.setValue("application/json", forHTTPHeaderField: "Accept")
                requestSerializer.setValue("application/json", forHTTPHeaderField: "Content-Type")
                self.httpManager.requestSerializer = requestSerializer
                
                let postOperation = self.httpManager.POST(
                    postString,
                    parameters: params,
                    success:
                    { (operation, result) -> Void in
                        
                        if let
                            resultDict = result as? Dictionary<String, AnyObject>,
                            newElementDict = resultDict["AddElementResult"] as? Dictionary<String, AnyObject>
                        {
                            let newUploadedElement = Element(info: newElementDict)
                            completion(newUploadedElement, nil)
                        }
                        else
                        {
                            let lvError = NSError(domain: "com.DictionaryConversion.Failure", code: -801, userInfo: [NSLocalizedDescriptionKey:"Failed to convert response to dictionary"])
                            completion(nil, lvError)
                        }
                        
                    },
                    failure:
                    { (operation, error) -> Void in
                        
                        if let errorString = operation.responseString
                        {
                            let lvError = NSError(domain: "com.ElementSubmission.Failure", code: -802, userInfo: [NSLocalizedDescriptionKey:errorString])
                            completion(nil,lvError)
                        }
                        else
                        {
                            completion(nil, error)
                        }
                })
                
                postOperation.start()
            })
        }
        else
        {
            completion(nil,noUserTokenError)
        }
    }
    
    func editElement(element:Element, completion completonClosure:(success:Bool, error:NSError?) -> () )
    {
        if let userToken = DataSource.sharedInstance.user?.token as? String
        {
            var requestError:NSError?
            NSOperationQueue().addOperationWithBlock({ () -> Void in
                let editUrlString = "\(serverURL)" + "\(editElementUrlPart)" + "?token=" + "\(userToken)"
                let elementDict = element.toDictionary()
                let params = ["element":elementDict]
                let manager = AFHTTPRequestOperationManager()
                let requestSerializer = AFJSONRequestSerializer()
                requestSerializer.timeoutInterval = 15.0
                requestSerializer.setValue("application/json", forHTTPHeaderField:"Content-Type")
                requestSerializer.setValue("application/json", forHTTPHeaderField: "Accept")
                manager.requestSerializer = requestSerializer
                UIApplication.sharedApplication().networkActivityIndicatorVisible = true
                let editRequestOperation = manager.POST(editUrlString,
                    parameters: params,
                    success: { (operation, resultObject) -> Void in
                        
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                       completonClosure(success: true, error: nil)
                    },
                    failure: { (operation, error) -> Void in
                        
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                        
                        if let responseString = operation.responseString
                        {
                            if responseString.isEmpty
                            {
                                requestError = error
                            }
                            else
                            {
                                requestError = NSError(domain: "ElementEditingError", code: -1002, userInfo: [NSLocalizedDescriptionKey:responseString])
                            }
                            completonClosure(success: false, error: requestError)
                        }
                        else
                        {
                            completonClosure(success: false, error: error)
                        }                        
                })
                
                editRequestOperation.start()
            })
        }
    }
    
    func setElementWithId(elementId:NSNumber, favourite isFavourite:Bool, completion completionClosure:(success:Bool, error:NSError?)->())
    {
        if let userToken = DataSource.sharedInstance.user?.token as? String
        {
            
            NSOperationQueue().addOperationWithBlock({ () -> Void in
                
                let requestString = "\(serverURL)" + "\(favouriteElementUrlPart)" + "?elementId=" + "\(elementId.integerValue)" + "&token=" + "\(userToken)"
                var requestError = NSError()
                
                let manager = AFHTTPRequestOperationManager()
                let requestSerializer = AFJSONRequestSerializer()
                requestSerializer.timeoutInterval = 15.0
                requestSerializer.setValue("application/json", forHTTPHeaderField:"Content-Type")
                requestSerializer.setValue("application/json", forHTTPHeaderField: "Accept")
                manager.requestSerializer = requestSerializer
                UIApplication.sharedApplication().networkActivityIndicatorVisible = true
                let editRequestOperation = manager.POST(requestString,
                    parameters: nil,
                    success: { (operation, resultObject) -> Void in
                        
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                        completionClosure(success: true, error: nil)
                    },
                    failure: { (operation, error) -> Void in
                        
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                        
                        let responseString = operation.responseString
                        if responseString.isEmpty
                        {
                            requestError = error
                        }
                        else
                        {
                            requestError = NSError(domain: "ElementEditingError", code: -1002, userInfo: [NSLocalizedDescriptionKey:responseString])
                            
                        }
                        completionClosure(success: false, error: requestError)
                })
                
                editRequestOperation.start()
            })
            return
        }
        completionClosure(success: false, error: NSError(domain: "TokenError", code: -101, userInfo: [NSLocalizedDescriptionKey:"No User token found."]))
    }
    
    
    func loadPassWhomIdsForElementID(elementId:Int, completion completionClosure:([NSNumber]?, NSError?)->() )
    {
        if let userToken = DataSource.sharedInstance.user?.token as? String{
            
            let requestString = "\(serverURL)" + "\(passWhomelementUrlPart)" + "?elementId=" + "\(elementId)" + "&token=" + "\(userToken)"
            
            let requestIDsOperation = AFHTTPRequestOperationManager().GET(requestString, parameters: nil, success: { (operation, result) -> Void in
                if let resultArray = result["GetPassWhomIdsResult"] as? [NSNumber]
                {
                    let idsSet = Set(resultArray)
                    completionClosure(Array(idsSet), nil)
                }
                else
                {
                    completionClosure(nil, NSError(domain: "Connected Contacts Error", code: -102, userInfo: [NSLocalizedDescriptionKey:"Failed to load contacts for element with id \(elementId)"]))
                }
            }, failure: { (operation, error) -> Void in
                if let responseString = operation.responseString
                {
                    completionClosure(nil, NSError(domain: "Connected Contacts Error", code: -103, userInfo: [NSLocalizedDescriptionKey: responseString]))
                }
                else
                {
                    completionClosure(nil, error)
                }
            })
            
            requestIDsOperation.start()
            
            return
        }
        
        completionClosure(nil, NSError(domain: "TokenError", code: -101, userInfo: [NSLocalizedDescriptionKey:"No User token found."]))
    }
    
    func deleteElement(elementID:Int, completion closure:(deleted:Bool, error:NSError?) ->())
    {
        // "DeleteElement?elementId={elementId}&token={token}" POST
        let token = DataSource.sharedInstance.user!.token! as String
        
        let deleteString = serverURL + deleteElementUrlPart + "?token=" + token + "&elementId=" + "\(elementID)"
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        let deleteOperation = httpManager.POST(deleteString,
            parameters: nil,
            success: { (response, responseObject) -> Void in
                if let dict = responseObject as? [String:AnyObject]
                {
                    println("Success response while deleting element: \(dict) ")
                }
                closure(deleted: true, error: nil)
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }) { (response, failureError) -> Void in      /*...failure closure...*/
            
                if let responseString = response.responseString
                {
                    let lvError = NSError(domain: "Origami.DeleteElement.Error", code: -432, userInfo: [NSLocalizedDescriptionKey:responseString])
                    closure(deleted: false, error: lvError)
                }
                else
                {
                    closure(deleted: false, error: failureError)
                }
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
        
        deleteOperation.start()
    }
    
    //MARK: Messages
    func loadAllMessages(completion:networkResult)
    {
        if let tokenString = DataSource.sharedInstance.user?.token as? String
        {
            let urlString = "\(serverURL)" + "\(getAllMessagesPart)" + "?token=" + "\(tokenString)"
            
            let messagesOp = httpManager.GET(urlString,
                parameters: nil,
                success:
                { [unowned self] (operation, result) -> Void in
                    
                    dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), { () -> Void in
                        if let
                            lvResultDict = result as? [NSObject:AnyObject],
                            messageDictsArray = lvResultDict["GetMessagesResult"] as? [[String:AnyObject]],
                            messagesArray = ObjectsConverter.convertToMessages(messageDictsArray)
                        {
                            completion(messagesArray, nil)
                        }
                    })
                   
                })
                { /*failure closure*/(operation, requestError) -> Void in
                    if let errorString = operation.responseString
                    {
                        let lvError = NSError(domain: "Messages Loading Error", code: 704, userInfo: [NSLocalizedDescriptionKey:errorString])
                    }
                    else
                    {
                        completion(nil, requestError)
                    }
            }
            
            messagesOp.start()
            return
        }
        
        completion(nil, NSError(domain: "TokenError", code: -101, userInfo: [NSLocalizedDescriptionKey:"No User token found."]))
        
    }
    
    func sendMessage(message:Message, toElement elementId:NSNumber, completion:networkResult?)
    {
        println(" -> sendMessage Called.")
        //POST
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        if let tokenString = DataSource.sharedInstance.user?.token as? String
        {
            let postUrlString =  "\(serverURL)" + "\(sendMessageUrlPart)" + "?token=" + "\(tokenString)" + "&elementId=" + "\(elementId.integerValue)"
            println("sending message to element: \(elementId)")
            var messageToSend = message.textBody!
            
            let params = NSDictionary(dictionary: ["msg":messageToSend])
            
            
            
            var serializer = AFJSONRequestSerializer();
            
            serializer.timeoutInterval = 20;
            serializer.setValue("application/json", forHTTPHeaderField:"Content-Type")
            serializer.setValue("application/json", forHTTPHeaderField:"Accept")
            
            
            httpManager.requestSerializer = serializer;
            
            let messageSendOp = httpManager.POST(postUrlString,
                parameters: params,
                success: { (requestOp, result) -> Void in
                    
                    if let completionBlock = completion
                    {
                        completionBlock([String:AnyObject](), nil)
                    }
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                },
                failure: { (requestOp, error) -> Void in
                    
                    if let responseString = requestOp.responseString
                    {
                        println("\r - Error Sending Message: \r \(responseString) ");
                        let lvError = NSError(domain: "Failure Sending Message", code: 703, userInfo: [NSLocalizedDescriptionKey:responseString])
                        if completion != nil{
                            completion!(nil, lvError)
                        }
                    }
                    else
                    {
                        if let completionBlock = completion
                        {
                            completionBlock(nil, error)
                        }
                    }
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            })
            
            messageSendOp.start()
            
            return
        }
        
        if let completionBlock = completion
        {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            completionBlock(nil, noUserTokenError)
        }
    }
    
    
    func loadNewMessages(completion:((messages:[Message]?, error:NSError?)->())?)
    {
        if let userToken = DataSource.sharedInstance.user?.token as? String
        {
            let newMessagesURLString = serverURL + getNewMessagesUrlPart + "?token=" + userToken
            
            let lastMessagesOperation = httpManager.GET(
                newMessagesURLString,
                parameters: nil,
                success: { (operation, response) -> Void in
                    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), { () -> Void in
                        if let aResponse = response as? [NSObject:AnyObject], newMessageInfos = aResponse["GetNewMessagesResult"] as? [[String:AnyObject]]
                        {
                            if let completionBlock = completion
                            {
                                if let messagesArray = ObjectsConverter.convertToMessages(newMessageInfos)
                                {
                                    println("loaded newMessages")
                                    
                                    completionBlock(messages: messagesArray, error: nil)
                                }
                                else
                                {
                                    println("loaded empty messages")
                                    completionBlock(messages: nil, error: nil)
                                }
                                
                            }
                            return
                        }
                        
                        if let completionBlock = completion
                        {
                            completionBlock(messages: nil, error: nil)
                        }
                    })
                  
                    
            }, failure: { (operation, error) -> Void in
                
                if let completionBlock = completion
                {
                    completionBlock(messages: nil, error: error)
                }
                println("-> Error while loading last messages:\(error)")
                
            })
            
            lastMessagesOperation.start()
            return
        }
        
        if let completionBlock = completion
        {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            completionBlock(messages:nil, error:noUserTokenError)
        }
    }
    
    //MARK: Attaches
    func loadAttachesListForElementId(elementId:NSNumber, completion:networkResult)
    {
        //"GetElementAttaches?elementId={elementId}&token={token}"
        //NSString *urlString = [NSString stringWithFormat:@"%@GetElementAttaches?elementId=%@&token=%@", BasicURL, elementId, _currentUser.token];
        if let userToken = DataSource.sharedInstance.user?.token as? String
        {
            let requestString = "\(serverURL)" + getElementAttachesUrlPart + "?elementId=" + "\(elementId)" + "&token=" + userToken
            
            let requestOperation = httpManager.GET(requestString,
                parameters: nil,
                success: { [weak self] (operation, result) -> Void in
                    if let attachesArray = result["GetElementAttachesResult"] as? [[String:AnyObject]] //array of dictionaries
                    {
                        NSOperationQueue().addOperationWithBlock({/* [weak self]*/() -> Void in
//                            if let weakSelf = self
//                            {
                                if let attaches = ObjectsConverter.converttoAttaches(attachesArray)
                                {
                                    NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                                    completion(attaches, nil)
                                    })
                                }
                                else
                                {
                                    NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                                        completion(nil,nil)
                                    })
                            }
//                            }
                        })
                    }
                    else
                    {
                        let lvError = NSError(domain: "Attachment error", code: -45, userInfo: [NSLocalizedDescriptionKey:"Failed to convert recieved attaches data"])
                        completion(nil, lvError)
                    }
                    
            },
                failure: { (operation, error) -> Void in
                
                    
            })
            
            
            requestOperation.start()
            return
        }
        
        completion(nil, noUserTokenError)

    }
    
    func loadDataForAttach(attachId:NSNumber, completion completionClosure:(attachFileData:NSData?, error:NSError?)->() )
    {
        if let userToken = DataSource.sharedInstance.user?.token as? String
        {
            let requestString = serverURL + getAttachFileUrlPart + "?fileId=" + "\(attachId)" + "&token=" + userToken
            if let requestURL = NSURL(string: requestString)
            {
                var fileDataRequest = NSMutableURLRequest(URL: requestURL)
                fileDataRequest.HTTPMethod = "GET"

//                var synchronousError:NSError?
//                var synchroResponse:NSURLResponse?
//                var synchroData:NSData? = NSURLConnection.sendSynchronousRequest(fileDataRequest, returningResponse: &synchroResponse , error: &synchronousError)
//                if synchronousError != nil
//                {
//                    completionClosure(attachFileData: nil, error: synchronousError)
//                }
//                else if synchroData != nil
//                {
//                    var jsonReadingError:NSError? = nil
//                    if let responseDict = NSJSONSerialization.JSONObjectWithData(synchroData!, options: NSJSONReadingOptions.AllowFragments , error: &jsonReadingError) as? [NSObject:AnyObject]
//                    {
//                        if let arrayOfIntegers = responseDict["GetAttachedFileResult"] as? [Int]
//                        {
//                            if arrayOfIntegers.isEmpty
//                            {
//                                println("Empty response for Attach File id = \(attachId)")
//                                completionClosure(attachFileData: NSData(), error: nil)
//                            }
//                            else
//                            {
//                                if let lvData = NSData.dataFromIntegersArray(arrayOfIntegers)
//                                {
//                                    completionClosure(attachFileData: lvData, error: nil)
//                                }
//                                else
//                                {
//                                    //error
//                                    println("ERROR: Could not convert response to NSData object")
//                                    let convertingError = NSError(domain: "File loading failure", code: -1003, userInfo: [NSLocalizedDescriptionKey:"Failed to convert response."])
//                                    completionClosure(attachFileData: nil, error: convertingError)
//                                }
//                            }
//                        }
//                        else
//                        {
//                            //error
//                            println("ERROR: Could not convert to array of integers object.")
//                            let arrayConvertingError = NSError(domain: "File loading failure", code: -1004, userInfo: [NSLocalizedDescriptionKey:"Failed to read response."])
//                            completionClosure(attachFileData: nil, error: arrayConvertingError)
//                        }
//                    }
//                    else
//                    {
//                        println(" ERROR: \(jsonReadingError)")
//                        let convertingError = NSError (domain: "File loading failure", code: -1002, userInfo: [NSLocalizedDescriptionKey: "Could not process response."])
//                        completionClosure(attachFileData: nil, error: convertingError)
//                    }
//
//                }
//                else
//                {
//                    println("No response data..")
//                    completionClosure(attachFileData: NSData(), error: nil)
//                }
                
                let fileTask = NSURLSession.sharedSession().dataTaskWithRequest(fileDataRequest, completionHandler: { (responseData, urlResponse, responseError) -> Void
                    
                    in
                    
                    if responseError != nil
                    {
                        completionClosure(attachFileData: nil, error: responseError)
                    }
                    else if let synchroData = responseData
                    {
                        var jsonReadingError:NSError? = nil
                        if let responseDict = NSJSONSerialization.JSONObjectWithData(synchroData, options: NSJSONReadingOptions.AllowFragments , error: &jsonReadingError) as? [NSObject:AnyObject]
                        {
                            if let arrayOfIntegers = responseDict["GetAttachedFileResult"] as? [Int]
                            {
                                if arrayOfIntegers.isEmpty
                                {
                                    println("Empty response for Attach File id = \(attachId)")
                                    completionClosure(attachFileData: NSData(), error: nil)
                                }
                                else
                                {
                                    if let lvData = NSData.dataFromIntegersArray(arrayOfIntegers)
                                    {
                                        completionClosure(attachFileData: lvData, error: nil)
                                    }
                                    else
                                    {
                                        //error
                                        println("ERROR: Could not convert response to NSData object")
                                        let convertingError = NSError(domain: "File loading failure", code: -1003, userInfo: [NSLocalizedDescriptionKey:"Failed to convert response."])
                                        completionClosure(attachFileData: nil, error: convertingError)
                                    }
                                }
                            }
                            else
                            {
                                //error
                                println("ERROR: Could not convert to array of integers object.")
                                let arrayConvertingError = NSError(domain: "File loading failure", code: -1004, userInfo: [NSLocalizedDescriptionKey:"Failed to read response."])
                                completionClosure(attachFileData: nil, error: arrayConvertingError)
                            }
                        }
                        else
                        {
                            println(" ERROR: \(jsonReadingError)")
                            let convertingError = NSError (domain: "File loading failure", code: -1002, userInfo: [NSLocalizedDescriptionKey: "Could not process response."])
                            completionClosure(attachFileData: nil, error: convertingError)
                        }
                        
                    }
                    else
                    {
                        println("No response data..")
                        completionClosure(attachFileData: NSData(), error: nil)
                    }

                })
                
                fileTask.resume()
            }
            
        }
    }
        //attach file to element
    func attachFile(file:MediaFile, toElement elementId:NSNumber, completion completionClosure:(success:Bool, attachId:NSNumber?, error:NSError?)->() ){
        /*
        
        NSString *photoUploadURL = [NSString stringWithFormat:@"%@AttachFileToElement?elementId=%@&fileName=%@&token=%@", BasicURL, elementId, fileName, _currentUser.token];
        
        NSMutableURLRequest *mutableRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:photoUploadURL]];
        [mutableRequest setHTTPMethod:@"POST"];
        
        [mutableRequest setHTTPBody:fileData];
        */
        
        if let userToken = DataSource.sharedInstance.user?.token
        {
            let attachedFileDataLength = file.data.length
            println("\n -> attaching \"\(attachedFileDataLength)\" bytes...")
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            let postURLstring = "\(serverURL)" + attachToElementUrlPart + "?elementId=" + "\(elementId)" + "&fileName=" + "\(file.name)" + "&token=" + "\(userToken)" as NSString
            let postURL = NSURL(string: postURLstring as String)
            var mutableRequest = NSMutableURLRequest(URL: postURL!)
            mutableRequest.HTTPMethod = "POST"
            mutableRequest.HTTPBody = file.data
            
            var backgroundQueue = NSOperationQueue()
            backgroundQueue.maxConcurrentOperationCount = 2
            NSURLConnection.sendAsynchronousRequest(mutableRequest,
                queue: backgroundQueue,
                completionHandler: { (response, responseData, error) -> Void in

                    if error != nil {
                       println("\(error)")
                        completionClosure(success: false, attachId:nil, error: error)
                        return
                    }
                    
                    var lvError:NSError? = nil
                    let optionReading = NSJSONReadingOptions.AllowFragments
                    if let responseDict = NSJSONSerialization.JSONObjectWithData(responseData, options: optionReading, error: &lvError) as? [NSObject:AnyObject]
                    {
                        if lvError != nil {
                            println("\(lvError)")
                            completionClosure(success: false, attachId:nil, error: lvError)
                        }
                        else
                        {
                            println("Success sending file to server: \n \(responseDict)")
                            if let attachID = responseDict["AttachFileToElementResult"] as? NSNumber
                            {
                                completionClosure(success: true, attachId:attachID ,error: nil)
                            }
                        }
                    }
                    
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            })
            
            return
        }
        
        completionClosure(success: false,  attachId:nil, error: noUserTokenError)
    }
        //remove attached file from element attaches
    func unAttachFile(name:String, fromElement elementId:NSNumber, completion completionClosure:((success:Bool, error:NSError?)->() )? = nil ) {
        /*
        
        //"RemoveFileFromElement?elementId={elementId}&fileName={fileName}&token={token}"
        NSString *removeURL = [NSString stringWithFormat:@"%@RemoveFileFromElement?elementId=%@&fileName=%@&token=%@", BasicURL, elementId, fileName, _currentUser.token];
        
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        AFHTTPRequestOperation *removeOp = [manager GET:removeURL
        parameters:nil
        success:^(AFHTTPRequestOperation *operation, id responseObject)
        {
        if (completionBlock)
        {
        NSDictionary *response = [(NSDictionary *)responseObject objectForKey:@"RemoveFileFromElementResult"];
        completionBlock(response, nil);
        }
        }
        failure:^(AFHTTPRequestOperation *operation, NSError *error)
        {
        if (completionBlock)
        {
        completionBlock(nil, error);
        }
        }];
        
        [removeOp start]
        
        */
        if let userToken = DataSource.sharedInstance.user?.token as? String {
            unAttachFileUrlPart
            let requestString = "\(serverURL)" + attachToElementUrlPart + "?elementId=" + "\(elementId)" + "&fileName=" + "\(name)" + "&token=" + "\(userToken)"
            let requestOperation = httpManager.GET(requestString,
                parameters: nil,
                success: { (operation, result) -> Void in
                    if let response = result["RemoveFileFromElementResult"] as? [NSObject:AnyObject]
                    {
                        println("\n --- Successfully unattached file from element: \(response)")
                    }
                    if completionClosure != nil
                    {
                        completionClosure!(success: true, error: nil)
                    }
                
            },
                failure: { (operation, error) -> Void in
                    if let errorString = operation.responseString {
                        let lvError = NSError(domain: "Attachment Error", code: -44, userInfo: [NSLocalizedDescriptionKey:errorString])
                        if completionClosure != nil
                        {
                            completionClosure!(success: false, error: lvError)
                        }
                        
                    }
                    else {
                        if completionClosure != nil
                        {
                            completionClosure!(success: false, error: error)
                        }
                    }
            })
            
            requestOperation.start()
            return
        }
        
        if  completionClosure != nil
        {
            completionClosure!(success: false, error: noUserTokenError)
        }
    }
    
    
    //MARK: Avatars
    func loadAvatarDataForUserName(loginName:String, completion completionBlock:((avatarData:NSData?, error:NSError?) ->())? )
    {
        /*
        NSString *userAvatarRequestURL = [NSString stringWithFormat:@"%@GetPhoto?userName=%@", BasicURL, userLoginName];
        NSURL *requestURL = [NSURL URLWithString:userAvatarRequestURL];
        
        NSMutableURLRequest *avatarRequest = [NSMutableURLRequest requestWithURL:requestURL];
        [avatarRequest setHTTPMethod:@"GET"];
        
        [NSURLConnection sendAsynchronousRequest:avatarRequest
        queue:[NSOperationQueue currentQueue]
        completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
        {
        //NSLog(@"Response: \r %@", response);
        if (completionBlock)
        {
        if (!connectionError)
        {
        if (data.length > 0)
        {
        NSError *jsonError;
        id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
        
        if (jsonObject)
        {
        if ([(NSDictionary *)jsonObject objectForKey:@"GetPhotoResult"] != [NSNull null])
        {
        NSArray *result = [(NSDictionary *)jsonObject objectForKey:@"GetPhotoResult"];
        
        NSMutableData *mutableData = [NSMutableData data];
        
        for (NSNumber *number in result) //iterate through array and convert digits to bytes
        {
        int digit = [number intValue];
        
        NSData *lvData = [NSData dataWithBytes:&digit length:1];
        
        [mutableData appendData:lvData];
        }
        
        NSData *photoData = [NSData dataFromIntegersArray:result];
        
        if (mutableData.length == photoData.length)
        {
        NSLog(@"\n  PHOTO TEST PASSED \n");
        }
        
        UIImage *photo = [UIImage imageWithData:mutableData];
        if (photo)
        {
        NSDictionary *photoDict = @{userLoginName : photo};
        completionBlock(photoDict, nil);
        }
        else
        {
        NSError *lvError = [NSError errorWithDomain:@"Image Loading failure"
        code:NSKeyValueValidationError
        userInfo:@{NSLocalizedDescriptionKey:@"Could not convert data to Image"}];
        completionBlock(nil, lvError);
        }
        
        }
        else
        {
        NSError *lvError = [NSError errorWithDomain:@"Image Loading failure"
        code:NSKeyValueValidationError
        userInfo:@{NSLocalizedDescriptionKey:@"No Image for User"}];
        completionBlock(nil, lvError);
        }
        }
        else
        {
        NSError *lvError = [NSError errorWithDomain:@"Image Loading failure"
        code:NSKeyValueValidationError
        userInfo:@{NSLocalizedDescriptionKey:@"Wrong response object"}];
        completionBlock(nil, lvError);
        }
        
        }
        else
        {
        NSError *lvError = [NSError errorWithDomain:@"Image Loading failure"
        code:NSKeyValueValidationError
        userInfo:@{NSLocalizedDescriptionKey:@"Wrong data format"} ];
        completionBlock(nil, lvError);
        }
        }
        else
        {
        completionBlock(nil, connectionError);
        }
        }
        }];
        */
        
        let userAvatarRequestURLString = serverURL + "GetPhoto?userName=" + loginName
        if let requestURL = NSURL(string: userAvatarRequestURLString)
        {
            var mutableRequest = NSMutableURLRequest(URL: requestURL)
            mutableRequest.timeoutInterval = 30.0
            mutableRequest.HTTPMethod = "GET"
            
            let sessionTask = NSURLSession.sharedSession().dataTaskWithRequest(mutableRequest, completionHandler: { (responseData, response, responseError) -> Void in
                if let toReturnCompletion = completionBlock
                {
                    if let responseBytes = responseData
                    {
                        var jsonError:NSError?
                        if let
                            jsonObject = NSJSONSerialization.JSONObjectWithData(responseBytes, options: NSJSONReadingOptions.MutableContainers, error: &jsonError) as? [String:AnyObject],
                            response = jsonObject["GetPhotoResult"] as? [Int]
                        {
                            if let aData = NSData.dataFromIntegersArray(response)
                            {
                                toReturnCompletion(avatarData: aData, error: nil)
                            }
                        }
                        return
                    }
                    toReturnCompletion(avatarData: nil, error: responseError)
                }
            })
            
            sessionTask.resume()
        }
        
    }
    
    
    //MARK: Contacts
    
    /** Queries server for contacts and  on completion or timeout returns  array of contacts or error
        - Precondition: No Parameters. The function detects all that it needs from DataSource
        - Parameter completion: A caller may specify wether it wants or not to recieve data on completion - an optional var for contacts array and optional var for error handling
        - Returns: Void
    */
    func downloadMyContacts(completion completionClosure:((contacts:[Contact]?, error:NSError?) -> () )? = nil )
    {
        if let userToken = DataSource.sharedInstance.user?.token as? String
        {
            let requestString = serverURL + myContactsURLPart + "?token=" + userToken
            
            let contactsRequestOp = httpManager.GET(requestString,
                parameters: nil,
                success: { [unowned self] (operation, result) -> Void in
                NSOperationQueue().addOperationWithBlock({ () -> Void in
                    if let completion = completionClosure
                    {
                        if let lvContactsArray = result["GetContactsResult"] as? [[String:AnyObject]]
                        {
                            let convertedContacts = ObjectsConverter.convertToContacts(lvContactsArray)
                            completion(contacts:convertedContacts, error: nil)
                        }
                        else
                        {
                            let error = NSError(domain: "Contacts Reading Error.", code: -501, userInfo: [NSLocalizedDescriptionKey:"Could not read contacts raw info from response."])
                            completion(contacts:nil, error:error)
                        }
                    }
                })
                    
            }, failure: { (operation, requestError) -> Void in
                if let completion = completionClosure
                {
                    if let responseString = operation.responseString
                    {
                        let lvError = NSError(domain: "Contacts Query Error.", code: -502, userInfo: [NSLocalizedDescriptionKey:responseString])
                        completion(contacts: nil, error: lvError)
                    }
                    else
                    {
                        completion(contacts:nil, error:requestError)
                    }
                }
            })
            
            contactsRequestOp.start()
            return
        }
        if completionClosure != nil
        {
            completionClosure!(contacts: nil, error: noUserTokenError)
        }
    }
    
    func passElement(elementId:NSNumber, toContact contactId:NSNumber, forDeletion delete:Bool, completion completionClosure:(success:Bool, error: NSError?) -> ())
    {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        let elementIdInteger = (delete) ? elementId.integerValue * -1 : elementId.integerValue
        let rightElementId = NSNumber(integer: elementIdInteger)
        
        if let userToken = DataSource.sharedInstance.user?.token as? String
        {
            let requestString = serverURL + passElementUrlPart + "?token=" + userToken + "&elementId=" + "\(rightElementId)" + "&userPassTo=" + "\(contactId)"
            
            var serializer = AFJSONRequestSerializer()
            
            serializer.timeoutInterval = 10.0
            serializer.setValue("application/json", forHTTPHeaderField:"Content-Type")
            serializer.setValue("application/json", forHTTPHeaderField:"Accept")
            
            httpManager.requestSerializer = serializer;
            
            let requestOp = httpManager.POST(requestString,
                parameters: nil,
                success: { (operation, result) -> Void in
                    
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                if let resultDict = result as? [String:AnyObject]
                {
                    println("\n ->passElement Response from server: \(resultDict)")
                    completionClosure(success: true, error: nil)
                    return
                }
                let parsingError = NSError(domain: "Request reading error", code: -503, userInfo: [NSLocalizedDescriptionKey:"Failed to parse response from server."])
                completionClosure(success: false, error: parsingError)
                
            },
                failure: { (operation, requestError) -> Void in
                
                if let responseString = operation.responseString
                {
                    let responseError = NSError(domain: "Pass Element request Error", code: -504, userInfo: [NSLocalizedDescriptionKey:responseString])
                    completionClosure(success: false, error: responseError)
                }
                else
                {
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    completionClosure(success: false, error: requestError)
                }
            })
            
            requestOp.start()
            return
        }
        
        completionClosure(success: false, error: noUserTokenError)
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    func passElement(elementId : Int, toSeveratContacts contactIDs:Set<Int>, completion completionClosure:((succeededIDs:[Int], failedIDs:[Int])->())?)
    {
        let token = DataSource.sharedInstance.user!.token! as! String
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        NSOperationQueue.currentQueue()!.addOperationWithBlock { () -> Void in
            var failedIDs = [Int]()
            var succededIDs = [Int]()
            for lvUserID in contactIDs
            {
                let addSrtingURL = serverURL + passElementUrlPart + "?token=" + token + "&elementId=" + "\(elementId)" + "&userPassTo=" + "\(lvUserID)"
                
                if let addUrl = NSURL(string: addSrtingURL)
                {
                    var request:NSMutableURLRequest = NSMutableURLRequest(URL: addUrl)
                    request.HTTPMethod = "POST"
                    var lvError:NSError? = nil
                    var urlResponse:NSURLResponse? = nil
                    
                    //using SYNCHRONOUS requests because we need to wait FOR loop to finish
                    var responseData:NSData? = NSURLConnection.sendSynchronousRequest(request, returningResponse: &urlResponse, error: &lvError)
                    
                    if let error = lvError
                    {
                        failedIDs.append(lvUserID)
                    }
                    else
                    {
                        if let dict = NSJSONSerialization.JSONObjectWithData(responseData!, options: NSJSONReadingOptions.AllowFragments, error: &lvError) as? [String:AnyObject]
                        {
                            //recieved good response
                            //now check if any contact id is returned
                            //returned ids mean failed ids
                            if dict.isEmpty
                            {
                                succededIDs.append(lvUserID)
                            }
                            else
                            {
                                failedIDs.append(lvUserID)
                            }
                        }
                        else if let arr = NSJSONSerialization.JSONObjectWithData(responseData!, options: NSJSONReadingOptions.AllowFragments, error: &lvError) as? [AnyObject]
                        {
                            println("response:\(arr)")
                            failedIDs.append(lvUserID)
                        }
                        else if let string = NSString(data: responseData!, encoding: NSUTF8StringEncoding)
                        {
                            println(string)
                            failedIDs.append(lvUserID)
                        }
                    }
                }
                else
                {
                    failedIDs.append(lvUserID)
                }
            }
            
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                
                println("succeeded contact ids: \(succededIDs)")
                
                completionClosure?(succeededIDs: succededIDs, failedIDs: failedIDs)
            })
        }
    }
    
    func unPassElement(elementId :Int, fromSeveralContacts contactIDs:Set<Int>, completion completionClosure:((succeededIDs:[Int], failedIDs:[Int])->())?)
    {
        self.passElement((elementId * -1), toSeveratContacts: contactIDs, completion: completionClosure)
    }
    
    func loadAllContacts(completion:((contacts:[Contact]?, error:NSError?)->())?)
    {
        if let userToken = DataSource.sharedInstance.user?.token as? String
        {
            let requestString = serverURL + allContactsURLPart + "?token=" + userToken
            
            let contactsRequestOp = httpManager.GET(requestString,
                parameters: nil,
                success: { [unowned self] (operation, result) -> Void in
                    NSOperationQueue().addOperationWithBlock({ () -> Void in
                        if let completionBlock = completion
                        {
                            if let lvContactsArray = result["GetAllContactsResult"] as? [[String:AnyObject]]
                            {
                                let convertedContacts = ObjectsConverter.convertToContacts(lvContactsArray)
                                
                                //println("Loaded all contacts:\(convertedContacts)")
                                
                                completionBlock(contacts:convertedContacts, error: nil)
                            }
                            else
                            {
                                let error = NSError(domain: "Contacts Reading Error.", code: -501, userInfo: [NSLocalizedDescriptionKey:"Could not read contacts raw info from response."])
                                completionBlock(contacts:nil, error:error)
                            }
                        }
                    })
                    
                }, failure: { (operation, requestError) -> Void in
                    if let completionBlock = completion
                    {
                        if let responseString = operation.responseString
                        {
                            let lvError = NSError(domain: "Contacts Query Error.", code: -502, userInfo: [NSLocalizedDescriptionKey:responseString])
                            completionBlock(contacts: nil, error: lvError)
                        }
                        else
                        {
                            completionBlock(contacts:nil, error:requestError)
                        }
                    }
            })
            
            contactsRequestOp.start()
            
//            let queue = NSOperationQueue()
//            var request = NSMutableURLRequest(URL: NSURL(string: requestString)!)
//            request.HTTPMethod = "GET"
//            NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler: { (urlResponse, responseData, responseError) -> Void in
//                if let data = responseData
//                {
//                    var jsonError:NSError?
//                    if let json = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &jsonError) as? [NSObject:AnyObject]
//                    {
//                        println("---> Raw response: \(json)")
//                    }
//                    else if let string = NSString(data: data, encoding: NSUTF8StringEncoding)
//                    {
//                        println("---> RawString response: \(string)")
//                    }
//                }
//            })
            
            
            
            return
        }
        
        if let completionBlock = completion
        {
            completionBlock(contacts: nil, error: noUserTokenError)
        }

    }
    
    func toggleContactFavourite(contactId:Int, completion:((success:Bool, error:NSError?)->())?)
    {
        if let userToken = DataSource.sharedInstance.user?.token as? String
        {
            let favUrlString = serverURL + favContactURLPart + "?token=" + userToken + "&contactId=" + "\(contactId)"
            
            let favOperation = httpManager.GET(favUrlString, parameters: nil, success: { (operation, response) -> Void in
                if let aResponse = response as? [NSObject:AnyObject]
                {
                    if let completionBlock = completion
                    {
                        completionBlock(success: true, error: nil)
                    }
                }
            }, failure: { (operation, error) -> Void in
                if let completionBlock = completion
                {
                    completionBlock(success: false, error: error)
                }
            })
            
            favOperation.start()
            return
        }
        
        if let completionBlock = completion
        {
            completionBlock(success: false, error: noUserTokenError)
        }
    }
    
    func removeMyContact(contactId:Int, completion:((success:Bool, error:NSError?)->())?)
    {
        /*
        //RemoveContact?contactId={contactId}&token={token}
        NSString *requestUrlString = [NSString stringWithFormat:@"%@RemoveContact", BasicURL];
        
        NSDictionary *parameters = @{@"contactId":idNumber, @"token":_currentUser.token};
        
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager.requestSerializer setTimeoutInterval:15];
        
        AFHTTPRequestOperation *requestOp = [manager GET:requestUrlString
        parameters:parameters
        success:^(AFHTTPRequestOperation *operation, id responseObject)
        {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        NSDictionary *response = (NSDictionary *)responseObject;
        
        NSLog(@"\n--removeContactWithId-- Success response:\n- %@",response);
        if (completionBlock)
        {
        completionBlock(response,nil);
        }
        
        
        
        }
        failure:^(AFHTTPRequestOperation *operation, NSError *error)
        {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        NSLog(@"\n removeContactWithId Error: \n-%@", error);
        if (completionBlock)
        {
        completionBlock(nil, error);
        }
        }];
        
        [requestOp start];
        
        */
        
        
        if let userToken = DataSource.sharedInstance.user?.token as? String
        {
            let removeUrlString = serverURL + "RemoveContact" + "?token=" + userToken + "&contactId=" + "\(contactId)"
            let removeContactOperation = httpManager.GET(removeUrlString, parameters: nil, success: { (operation, response) -> Void in
                if let aResponse = response as? [NSObject:AnyObject]
                {
                    if let completionBlock = completion
                    {
                        completionBlock(success: true, error: nil)
                    }
                }
                }, failure: { (operation, error) -> Void in
                    if let completionBlock = completion
                    {
                        completionBlock(success: false, error: error)
                    }
            })
            
            removeContactOperation.start()
            return
        }
        
        if let completionBlock = completion
        {
            completionBlock(success: false, error: noUserTokenError)
        }
    }
    
    func addToMyContacts(contactId:Int, completion:((success:Bool, error:NSError?)->())?)
    {
        /*
        NSString *requestUrlString = [NSString stringWithFormat:@"%@AddContact", BasicURL];
        
        NSDictionary *parameters = @{@"contactId":idNumber, @"token":_currentUser.token}; //we send UserID, not ContactID  here, because server returns USER object on search querry
        
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager.requestSerializer setTimeoutInterval:15];
        
        AFHTTPRequestOperation *requestOp = [manager GET:requestUrlString
        parameters:parameters
        success:^(AFHTTPRequestOperation *operation, id responseObject)
        {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        NSDictionary *response = (NSDictionary *)responseObject;
        
        //[[DataSource sharedInstance].contacts removeAllObjects];
        
        [[ServerRequester sharedRequester] loadContactsWithCompletion:^(NSDictionary *successResponse, NSError *error)
        {
        if (completionBlock)
        {
        completionBlock(response,nil);
        }
        } progressView:nil];
        
        }
        failure:^(AFHTTPRequestOperation *operation, NSError *error)
        {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        NSLog(@"\n addContactWithId: Error: \n-%@", error);
        if (completionBlock)
        {
        completionBlock(nil,error);
        }
        }];
        
        [requestOp start];
        
        */
        
        if let userToken = DataSource.sharedInstance.user?.token as? String
        {
            let addUrlString = serverURL + "AddContact" + "?token=" + userToken + "&contactId=" + "\(contactId)"
            let addContactOperation = httpManager.GET(addUrlString, parameters: nil, success: { (operation, response) -> Void in
                if let aResponse = response as? [NSObject:AnyObject]
                {
                    if let completionBlock = completion
                    {
                        completionBlock(success: true, error: nil)
                    }
                }
                }, failure: { (operation, error) -> Void in
                    if let completionBlock = completion
                    {
                        completionBlock(success: false, error: error)
                    }
            })
            
            addContactOperation.start()
            return
        }
        
        if let completionBlock = completion
        {
            completionBlock(success: false, error: noUserTokenError)
        }
    }
}
