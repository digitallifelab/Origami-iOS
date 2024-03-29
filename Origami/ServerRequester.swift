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
            var requestError = NSError()
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
                        
                        let responseString = operation.responseString
                        if responseString.isEmpty
                        {
                            requestError = error
                        }
                        else
                        {
                            requestError = NSError(domain: "ElementEditingError", code: -1002, userInfo: [NSLocalizedDescriptionKey:responseString])
                            
                        }
                       completonClosure(success: false, error: requestError)
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
    
    
    func loadPassWhomIdsForElementID(elementId:NSNumber, completion completionClosure:([NSNumber]?, NSError?)->() )
    {
        if let userToken = DataSource.sharedInstance.user?.token as? String{
            
            let requestString = "\(serverURL)" + "\(passWhomelementUrlPart)" + "?elementId=" + "\(elementId)" + "&token=" + "\(userToken)"
            
            let requestIDsOperation = AFHTTPRequestOperationManager().GET(requestString, parameters: nil, success: { (operation, result) -> Void in
                if let resultArray = result["GetPassWhomIdsResult"] as? [Int]
                {
                    completionClosure(resultArray, nil)
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
            let postUrlString =  "\(serverURL)" + "\(sendMessageUrlPart)" + "?token=" + "\(tokenString)" + "&elementId=" + "\(elementId.integerValue)"//[NSString stringWithFormat:@"%@SendElementMessage?token=%@&elementId=%@", BasicURL, _currentUser.token, elementId];
            //    NSDictionary *messageDict = [message toDictionary];
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
                        NSOperationQueue().addOperationWithBlock({ [weak self]() -> Void in
                            if self != nil
                            {
                                let attaches = ObjectsConverter.converttoAttaches(attachesArray)// convertToAttaches(attachesArray)
                                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                                    completion(attaches, nil)
                                })
                            }
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

                var synchronousError:NSError?
                var synchroResponse:NSURLResponse?
                var synchroData:NSData? = NSURLConnection.sendSynchronousRequest(fileDataRequest, returningResponse: &synchroResponse , error: &synchronousError)
                if synchronousError != nil
                {
                    completionClosure(attachFileData: nil, error: synchronousError)
                }
                else if synchroData != nil
                {
                    var jsonReadingError:NSError? = nil
                    if let responseDict = NSJSONSerialization.JSONObjectWithData(synchroData!, options: NSJSONReadingOptions.AllowFragments , error: &jsonReadingError) as? [NSObject:AnyObject]
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
    //MARK: Contacts
    
    /** Queries server for contacts and  on completion or timeout returns  array of contacts or error
        - Precondition: No Parameters. The function detects all that it needs from DataSource
        - Parameter completion: A caller may specify wether it wants or not to recieve data on completion - an optional var for contacts array and optional var for error handling
        - Returns: Void
    */
    func downloadAllContacts(completion completionClosure:((contacts:[Contact]?, error:NSError?) -> () )? = nil )
    {
        if let userToken = DataSource.sharedInstance.user?.token as? String
        {
            let requestString = serverURL + allContactsURLPart + "?token=" + userToken
            
            let contactsRequestOp = httpManager.GET(requestString,
                parameters: nil,
                success: { [unowned self] (operation, result) -> Void in
                
                    if completionClosure != nil
                    {
                        if let lvContactsArray = result["GetContactsResult"] as? [[String:AnyObject]]
                        {
                            let convertedContacts = ObjectsConverter.convertToContacts(lvContactsArray)
                            completionClosure!(contacts:convertedContacts, error: nil)
                        }
                        else
                        {
                            let error = NSError(domain: "Contacts Reading Error.", code: -501, userInfo: [NSLocalizedDescriptionKey:"Could not read contacts raw info from response."])
                            completionClosure!(contacts:nil, error:error)
                        }
                    }
                    
            }, failure: { (operation, requestError) -> Void in
                if completionClosure != nil
                {
                    if let responseString = operation.responseString
                    {
                        let lvError = NSError(domain: "Contacts Query Error.", code: -502, userInfo: [NSLocalizedDescriptionKey:responseString])
                        completionClosure!(contacts: nil, error: lvError)
                    }
                    else
                    {
                        completionClosure!(contacts:nil, error:requestError)
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
                    println(resultDict)
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
    
    func passElement(elementId : Int, toSeveratContacts contactIDs:[Int], completion completionClosure:(succeededIDs:[Int], failedIDs:[Int])->())
    {
        let token = DataSource.sharedInstance.user!.token! as! String
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        NSOperationQueue().addOperationWithBlock { () -> Void in
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
                        else
                        {
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
                completionClosure(succeededIDs: succededIDs, failedIDs: failedIDs)
            })
        }
    }
}
