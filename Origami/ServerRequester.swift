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
        let requestString:String = "\(serverURL)" + "\(registerUserUrlPart)"
        let parametersToRegister = [firstNameKey:firstName, lastNameKey:lastName, loginNameKey:userName]
        
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
        
        operation?.start()
    }
    
    func editUser(userToEdit:User, completion:((success:Bool, error:NSError?) -> ())? )
    {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        let requestString:String = "\(serverURL)" + "\(editUserUrlPart)"
        let dictUser = userToEdit.toDictionary()
        //let dictionaryDebug = NSDictionary(dictionary: dictUser)
        //print(dictionaryDebug)
        let params = ["user":dictUser]
        
        let jsonSerializer = httpManager.responseSerializer
        
        let requestSerializer = AFJSONRequestSerializer()
        requestSerializer.setValue("application/json", forHTTPHeaderField:"Content-Type")
        requestSerializer.setValue("application/json", forHTTPHeaderField: "Accept")
        httpManager.requestSerializer = requestSerializer
        
        
        if let acceptableTypes = jsonSerializer.acceptableContentTypes //as? NSSet<NSObject>
        {
            let newSet = NSMutableSet(set: acceptableTypes)
            newSet.addObjectsFromArray(["text/html", "application/json"])
            jsonSerializer.acceptableContentTypes = newSet as Set<NSObject>
        }
      
        let editOperation = httpManager.POST(
            requestString,
            parameters: params,
            success:
            { (operation, resultObject) -> Void in
                if let result = resultObject as? [String:AnyObject]
                {
                    print(" -> Edit user result: \(result)")
                    completion?(success: true, error: nil)
                }
                else
                {
                    print(" -> failed to edit user...")
                    completion?(success: false, error: nil)
                }
                
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            
        })
            { (operation, responseError) -> Void in
    
                if let errorString = operation.responseString
                {
                    print("\n ->failure string in edit uer: \n \(errorString) \n")
                }
                
                
                print("\n -> Edit user Error: \(responseError)")
                
    
            completion?(success: false, error: responseError)
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
        
        editOperation?.start()
    }
    
    func loginWith(userName:String, password:String, completion:networkResult)
    {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        let requestString:String = "\(serverURL)" + "\(loginUserUrlPart)"
        let params = ["username":userName, "password":password]
        
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
        
        loginOperation?.start()
        
    }
    
    //MARK: Languages & Countries
    
    func loadLanguages(completion:((languages:[Language]?, error:NSError?) -> ())?)
    {
        let languagesUrlString = serverURL + getLanguagesUrlPart
        
        let langOperation = httpManager.GET(languagesUrlString,
            parameters: nil,
            success: { (operation, responseObject) -> Void in
                
                let bgQueue = dispatch_queue_create("languages.queue", DISPATCH_QUEUE_SERIAL)
                dispatch_async(bgQueue, { () -> Void in
                    
                    if let languagesDict = responseObject["GetLanguagesResult"] as? [[String:AnyObject]],  languages = ObjectsConverter.convertToLanguages(languagesDict)
                    {
                        completion?(languages:languages, error:nil)
                    }
                    else
                    {
                        let anError = NSError(domain: "LanguagesError", code: -409, userInfo: [NSLocalizedDescriptionKey:"Could not convert data to langages"])
                        completion?(languages: nil, error:anError)
                    }
                })
                
                
                
            })/*failure*/
            { (operation, responseError) -> Void in
                
                completion?(languages:nil, error: responseError)
                
        }
        
        langOperation?.start()
    }
    
    func loadCountries(completion:((countries:[Country]?, error:NSError?) ->())?)
    {
        let countriesUrlString = serverURL + getCountriesUrlPart
        
        let countriesOp = httpManager.GET(countriesUrlString,
            parameters: nil,
            success: { (operation, responseObject) -> Void in
            
            let bgQueue = dispatch_queue_create("countries.queue", DISPATCH_QUEUE_SERIAL)
            dispatch_async(bgQueue, { () -> Void in
                
                if let countriesDicts = responseObject["GetCountriesResult"] as? [[String:AnyObject]], countries = ObjectsConverter.convertToCountries(countriesDicts)
                {
                    completion?(countries: countries, error: nil)
                }
                else
                {
                    let anError = NSError(domain: "CountriesError", code: -409, userInfo: [NSLocalizedDescriptionKey:"Could not convert data to countries"])
                    completion?(countries: nil, error:anError)
                }
                
            })
        })
                { (operation, responseError) -> Void in
            
            completion?(countries:nil, error: responseError)
        }
            
        countriesOp?.start()
    }
 
    
    //MARK: Elements
    func loadAllElements(completion:networkResult)
    {
        if let tokenString = DataSource.sharedInstance.user?.token as? String
        {
            //let testUserId = DataSource.sharedInstance.user?.userId
            let params = [tokenKey:tokenString]
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            let requestString = "\(serverURL)" + "\(getElementsUrlPart)"
            let requestOperation = httpManager.GET(
                requestString,
                parameters:params,
                success:
                { (operation, responseObject) -> Void in
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    let bgQueue = dispatch_queue_create("ElementsCompletionQueue", DISPATCH_QUEUE_SERIAL)
                   
                    dispatch_async(bgQueue, { () -> Void in
                        if let dictionary = responseObject as? [String:AnyObject],
                            elementsArray = dictionary["GetElementsResult"] as? [[String:AnyObject]]
                        {
                            var elements = Set<Element>()
                            for lvElementDict in elementsArray
                            {                          
                                let lvElement = Element(info: lvElementDict)
                                elements.insert(lvElement)
                            }
                            print("\n -> Server requester loaded \(elements.count) elements.. ")
                            
                            completion(Array(elements),nil)
                        }
                        else
                        {
                            completion(nil, NSError(domain: "com.Origami.WrongDataFormet.Error", code: -4321, userInfo: [NSLocalizedDescriptionKey:"Could not process response feom server while querying all attaches"]))
                        }
                    })
            },
                failure:
                { (operation, responseError) -> Void in
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                completion(nil, responseError)
            })
            
            requestOperation.start()
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
            let bgQueue = dispatch_queue_create("submit sueue", DISPATCH_QUEUE_SERIAL)
            dispatch_async(bgQueue, { [unowned self] () -> Void in
                
//            })
//            NSOperationQueue().addOperationWithBlock({ [unowned self]() -> Void in
                let elementDict = element.toDictionary()
           
                let postString = serverURL + addElementUrlPart + "?token=" + "\(tokenString)"
                let params = ["element":elementDict]
                
                let requestSerializer = AFJSONRequestSerializer()
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
                
                postOperation?.start()
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
            
            let bgQueue = dispatch_queue_create("edit_sueue", DISPATCH_QUEUE_SERIAL)
            dispatch_async(bgQueue, { () -> Void in

                let editUrlString = "\(serverURL)" + "\(editElementUrlPart)" + "?token=" + "\(userToken)"
                var elementDict = element.toDictionary()
                if let archDateString = elementDict["ArchDate"] as? String
                {
                    if archDateString == kWrongEmptyDate
                    {
                        NSLog(" -> Archive date of element to pass: \n \(archDateString)\n <---<")
                        elementDict["ArchDate"] = "/Date(0)/"
                    }
                    
//                    if archDateString == "/Date(0)/"
//                    {
//                        elementDict["ArchDate"] = nil
//                    }
                }
                let params = ["element":elementDict]
                let debugDescription = params.description
                NSLog("Sending editElement params: \n \(debugDescription) \n")
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
                        // afnetworking returns here in main thread
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                       completonClosure(success: true, error: nil)
                    },
                    failure: { (operation, error) -> Void in
                        // afnetworking returns here in main thread
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
                
                editRequestOperation?.start()
            })
        }
    }
    
    func setElementWithId(elementId:NSNumber, favourite isFavourite:Bool, completion completionClosure:(success:Bool, error:NSError?)->())
    {
        if let userToken = DataSource.sharedInstance.user?.token as? String
        {
            
            NSOperationQueue().addOperationWithBlock({ () -> Void in
                
                let requestString = "\(serverURL)" + "\(favouriteElementUrlPart)" + "?elementId=" + "\(elementId.integerValue)" + "&token=" + "\(userToken)"
                var requestError:NSError?
                
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
                        }
                        else
                        {
                            requestError = error
                        }
                        
                       
                        completionClosure(success: false, error: requestError)
                        
                })
                
                editRequestOperation?.start()
            })
            return
        }
        completionClosure(success: false, error: NSError(domain: "TokenError", code: -101, userInfo: [NSLocalizedDescriptionKey:"No User token found."]))
    }
    
    
    func loadPassWhomIdsForElementID(elementId:Int, completion completionClosure:(Set<NSNumber>?, NSError?)->() )
    {
        if let userToken = DataSource.sharedInstance.user?.token as? String{
            
            let requestString = "\(serverURL)" + "\(passWhomelementUrlPart)" + "?elementId=" + "\(elementId)" + "&token=" + "\(userToken)"
            
            let requestIDsOperation = AFHTTPRequestOperationManager().GET(requestString, parameters: nil, success: { (operation, result) -> Void in
                let globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)
                dispatch_async(globalQueue, { () -> Void in
                    if let resultArray = result["GetPassWhomIdsResult"] as? [NSNumber]
                    {
                        let idsSet = Set(resultArray)
                        completionClosure(idsSet, nil)
                    }
                    else
                    {
                        completionClosure(nil, NSError(domain: "Connected Contacts Error", code: -102, userInfo: [NSLocalizedDescriptionKey:"Failed to load contacts for element with id \(elementId)"]))
                    }
                })
               
            }, failure: { (operation, error) -> Void in
                let globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)
                dispatch_async(globalQueue, { () -> Void in
                    if let responseString = operation.responseString
                    {
                        completionClosure(nil, NSError(domain: "Connected Contacts Error", code: -103, userInfo: [NSLocalizedDescriptionKey: responseString]))
                    }
                    else
                    {
                        completionClosure(nil, error)
                    }
                })
            })
            
            requestIDsOperation?.start()
            
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
                    print("Success response while deleting element: \(dict) ")
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
        
        deleteOperation?.start()
    }
    
    func setElementFinished(elementId:Int, finishDate:String, completion:((success:Bool)->())?)
    {
        //SetFinished
        if let userToken = DataSource.sharedInstance.user?.token as? String
        {
            let requestString = serverURL + finishDateUrlPart + "?token=" + userToken + "&elementId=" + "\(elementId)" //+ "&date=" + "\(finishDate)"
            if let url = NSURL(string: requestString)
            {
                UIApplication.sharedApplication().networkActivityIndicatorVisible = true
                let finishStateRequest = NSMutableURLRequest(URL: url)
                finishStateRequest.HTTPMethod = "POST"
                finishStateRequest.setValue("application/json", forHTTPHeaderField: "Accept")
                finishStateRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                finishStateRequest.setValue(finishDate, forHTTPHeaderField: "date")
                
                let postFinishStateTask = NSURLSession.sharedSession().dataTaskWithRequest(finishStateRequest, completionHandler: {[weak self] (aData:NSData?, response:NSURLResponse?, anError:NSError?) -> Void in
                    
                    if let error = anError
                    {
                        NSLog(" Error Setting finish Date for element:   \n \(error.description)")
                        completion?(success:false)
                    }
                    
                    if let data = aData
                    {
                        if data.length > 0
                        {
                            //var errorParsing:NSError?
                            if let weakSelf = self, completionBlock = completion
                            {
                                weakSelf.handleResponseWithData(data, completion: completionBlock)
                                return
                            }
                            
                        }
                    }
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                })
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                    postFinishStateTask.resume()
                })
                
            }
        }
        else
        {
            completion?(success:false)
        }
    }
    
    private func handleResponseWithData(data:NSData, completion:((success:Bool) -> ()) )
    {
        do{
            if let jsonResponse = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as? [String:AnyObject]
            {
                if jsonResponse.isEmpty
                {
                    completion(success:true)
                }
                print("\n Set Finish Date response: \(jsonResponse)")
            }
            else if let stringFromData = NSString(data: data, encoding: NSUTF8StringEncoding)
            {
                let range =  stringFromData.rangeOfString("String was not recognized as a valid DateTime.")
                print("\(range)")
                if range.location != Int.max
                {
                    completion(success:false)
                }
                else
                {
                    completion(success: true)
                }
            }
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            
        }
        catch let error as NSError  {
            print(error.description)
            completion(success:false)
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            //throw error
        }
        catch {
            print("\n -> Did catch unknown error...")
        }

    }
    
    func setElementFinishState(elementId:Int, finishState:Int, completion:((success:Bool)->())?)
    {
        //SetFinishState
        
        if let userToken = DataSource.sharedInstance.user?.token as? String
        {
            let requestString = serverURL + finishStateUrlPart + "?token=" + userToken + "&elementId=" + "\(elementId)" + "&finishState=" + "\(finishState)"
            if let url = NSURL(string: requestString)
            {
             
                let finishStateRequest = NSMutableURLRequest(URL: url)
                finishStateRequest.HTTPMethod = "POST"
                
                let postFinishStateTask = NSURLSession.sharedSession().dataTaskWithRequest(finishStateRequest, completionHandler: { (responseData, urlResponse, pesponseError) -> Void in
                
                    if let aData = responseData
                    {
                        do{
                            if let jsonResponse = try NSJSONSerialization.JSONObjectWithData(aData, options: NSJSONReadingOptions.AllowFragments) as? [String:AnyObject] {
                                if jsonResponse.isEmpty {
                                    completion?(success:true)
                                    return
                                }
                                
                                completion?(success:false)
                            }
                        }
                        catch let error as NSError
                        {
                            print("\(error)")
                            completion?(success:false)
                        }
                        catch{
                            completion?(success:false)
                        }
                    }
                    
                })
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                   postFinishStateTask.resume()
                })
            }
            else
            {
                completion?(success: false)
            }
        }
        else
        {
            completion?(success:false)
        }
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
                { (operation, result) -> Void in
                    
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), { () -> Void in
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
                        completion(nil, lvError)
                    }
                    else
                    {
                        completion(nil, requestError)
                    }
            }
            
            messagesOp?.start()
            return
        }
        
        completion(nil, NSError(domain: "TokenError", code: -101, userInfo: [NSLocalizedDescriptionKey:"No User token found."]))
        
    }
    
    func sendMessage(message:Message, toElement elementId:NSNumber, completion:networkResult?)
    {
        print(" -> sendMessage Called.")
        //POST
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        if let tokenString = DataSource.sharedInstance.user?.token as? String
        {
            let postUrlString =  "\(serverURL)" + "\(sendMessageUrlPart)" + "?token=" + "\(tokenString)" + "&elementId=" + "\(elementId.integerValue)"
            print("sending message to element: \(elementId)")
            if let messageToSend = message.textBody
            {
                
                let params = NSDictionary(dictionary: ["msg":messageToSend])
                let serializer = AFJSONRequestSerializer();
                
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
                            print("\r - Error Sending Message: \r \(responseString) ");
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
                
                messageSendOp?.start()
                
                return
            }
            return
        }
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        completion?(nil, noUserTokenError)
        
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
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                        if let aResponse = response as? [NSObject:AnyObject], newMessageInfos = aResponse["GetNewMessagesResult"] as? [[String:AnyObject]]
                        {
                            if let completionBlock = completion
                            {
                                if let messagesArray = ObjectsConverter.convertToMessages(newMessageInfos)
                                {
                                    print("loaded new Messages")
                                    
                                    completionBlock(messages: messagesArray, error: nil)
                                }
                                else
                                {
                                    //print("loaded empty messages")
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
                print("-> Error while loading last messages:\(error)")
                
            })
            
            lastMessagesOperation?.start()
            return
        }
        
        if let completionBlock = completion
        {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            completionBlock(messages:nil, error:noUserTokenError)
        }
    }
    
    //MARK: Attaches
    func loadAttachesListForElementId(elementId:Int, completion:networkResult?)
    {
        //"GetElementAttaches?elementId={elementId}&token={token}"
        //NSString *urlString = [NSString stringWithFormat:@"%@GetElementAttaches?elementId=%@&token=%@", BasicURL, elementId, _currentUser.token];
        if let userToken = DataSource.sharedInstance.user?.token as? String
        {
            let requestString = "\(serverURL)" + getElementAttachesUrlPart + "?elementId=" + "\(elementId)" + "&token=" + userToken
            
            let requestOperation = httpManager.GET(requestString,
                parameters: nil,
                success: {  (operation, result) -> Void in
                    
                    if let attachesArray = result["GetElementAttachesResult"] as? [[String:AnyObject]] //array of dictionaries
                    {
                        NSOperationQueue().addOperationWithBlock({/* [weak self]*/() -> Void in

                                if let attaches = ObjectsConverter.converttoAttaches(attachesArray)
                                {
                                   dispatch_async(dispatch_get_main_queue(),{ () -> Void in
                                    completion?(attaches, nil)
                                    })
                                }
                                else
                                {
                                    
                                    dispatch_async(dispatch_get_main_queue(),{ () -> Void in
                                       completion?(nil,nil)
                                    })
                            }

                        })
                    }
                    else
                    {
                        let lvError = NSError(domain: "Attachment error", code: -45, userInfo: [NSLocalizedDescriptionKey:"Failed to convert recieved attaches data"])
                        completion?(nil, lvError)
                    }
                    
            },
                failure: { (operation, error) -> Void in
                
                    if let responseString = operation.responseString
                    {
                        print("-> Failure while loading attachesList: \(responseString)")
                    }
                    
                    
                    print("-> Failure while loading attachesList: \(error)")
                    
                    completion?(nil, error)
            })
            
           
            requestOperation?.start()
            
            
           
            return
        }
        
        completion?(nil, noUserTokenError)

    }
    
    func loadDataForAttach(attachId:NSNumber, completion completionClosure:((attachFileData:NSData?, error:NSError?)->())? )
    {
        if let userToken = DataSource.sharedInstance.user?.token as? String
        {
            let requestString = serverURL + getAttachFileUrlPart + "?fileId=" + "\(attachId)" + "&token=" + userToken
            if let requestURL = NSURL(string: requestString)
            {
                let fileDataRequest = NSMutableURLRequest(URL: requestURL)
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
//                                print("Empty response for Attach File id = \(attachId)")
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
//                                    print("ERROR: Could not convert response to NSData object")
//                                    let convertingError = NSError(domain: "File loading failure", code: -1003, userInfo: [NSLocalizedDescriptionKey:"Failed to convert response."])
//                                    completionClosure(attachFileData: nil, error: convertingError)
//                                }
//                            }
//                        }
//                        else
//                        {
//                            //error
//                            print("ERROR: Could not convert to array of integers object.")
//                            let arrayConvertingError = NSError(domain: "File loading failure", code: -1004, userInfo: [NSLocalizedDescriptionKey:"Failed to read response."])
//                            completionClosure(attachFileData: nil, error: arrayConvertingError)
//                        }
//                    }
//                    else
//                    {
//                        print(" ERROR: \(jsonReadingError)")
//                        let convertingError = NSError (domain: "File loading failure", code: -1002, userInfo: [NSLocalizedDescriptionKey: "Could not process response."])
//                        completionClosure(attachFileData: nil, error: convertingError)
//                    }
//
//                }
//                else
//                {
//                    print("No response data..")
//                    completionClosure(attachFileData: NSData(), error: nil)
//                }
                
                let fileTask = NSURLSession.sharedSession().dataTaskWithRequest(fileDataRequest, completionHandler: { (responseData:NSData?, urlResponse:NSURLResponse?, responseError:NSError?) -> Void
                    
                    in
                    
                    if let anError = responseError
                    {
                        completionClosure?(attachFileData: nil, error: anError)
                    }
                    else if let synchroData = responseData
                    {
                        if synchroData.length > 0
                        {
                            do{
                                if let responseDict = try NSJSONSerialization.JSONObjectWithData(synchroData, options: NSJSONReadingOptions.AllowFragments ) as? [String:AnyObject]
                                {
                                    if let arrayOfIntegers = responseDict["GetAttachedFileResult"] as? [Int]
                                    {
                                        if arrayOfIntegers.isEmpty
                                        {
                                            print("Empty response for Attach File id = \(attachId)")
                                            completionClosure?(attachFileData: NSData(), error: nil)
                                        }
                                        else
                                        {
                                            if let lvData = NSData.dataFromIntegersArray(arrayOfIntegers)
                                            {
                                                completionClosure?(attachFileData: lvData, error: nil)
                                            }
                                            else
                                            {
                                                //error
                                                print("ERROR: Could not convert response to NSData object")
                                                let convertingError = NSError(domain: "File loading failure", code: -1003, userInfo: [NSLocalizedDescriptionKey:"Failed to convert response."])
                                                completionClosure?(attachFileData: nil, error: convertingError)
                                            }
                                        }
                                    }
                                    else
                                    {
                                        //error
                                        print("ERROR: Could not convert to array of integers object.")
                                        let arrayConvertingError = NSError(domain: "File loading failure", code: -1004, userInfo: [NSLocalizedDescriptionKey:"Failed to read response."])
                                        completionClosure?(attachFileData: nil, error: arrayConvertingError)
                                    }
                                }
//                                else
//                                {
//                                    print(" ERROR: \(jsonReadingError)")
//                                    let convertingError = NSError (domain: "File loading failure", code: -1002, userInfo: [NSLocalizedDescriptionKey: "Could not process response."])
//                                    completionClosure?(attachFileData: nil, error: convertingError)
//                                }

                                
                            }
                            catch{
                                
                            }
                            

                        }
                    }
                    else
                    {
                        print("No response data..")
                        completionClosure?(attachFileData: NSData(), error: nil)
                    }

                })
                
                fileTask.resume()
            }
            
        }
        else
        {
            completionClosure?(attachFileData: nil, error: noUserTokenError)
        }
    }
        //attach file to element
    func attachFile(file:MediaFile, toElement elementId:NSNumber, completion completionClosure:((success:Bool, attachId:NSNumber?, error:NSError?)->())? ){
        /*
        
        NSString *photoUploadURL = [NSString stringWithFormat:@"%@AttachFileToElement?elementId=%@&fileName=%@&token=%@", BasicURL, elementId, fileName, _currentUser.token];
        
        NSMutableURLRequest *mutableRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:photoUploadURL]];
        [mutableRequest setHTTPMethod:@"POST"];
        
        [mutableRequest setHTTPBody:fileData];
        */
        
        if let userToken = DataSource.sharedInstance.user?.token
        {
            let attachedFileDataLength = file.data.length
            print("\n -> attaching \"\(attachedFileDataLength)\" bytes...")
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            let postURLstring = "\(serverURL)" + attachToElementUrlPart + "?elementId=" + "\(elementId)" + "&fileName=" + "\(file.name)" + "&token=" + "\(userToken)" as NSString
            let postURL = NSURL(string: postURLstring as String)
            let mutableRequest = NSMutableURLRequest(URL: postURL!)
            mutableRequest.HTTPMethod = "POST"
            mutableRequest.HTTPBody = file.data
            
            let dataTask = NSURLSession.sharedSession().dataTaskWithRequest(mutableRequest, completionHandler: { (responseData:NSData?, response:NSURLResponse?, responseError:NSError?) -> Void in
                
                if let error = responseError
                {
                    print("\(error)")
                    completionClosure?(success: false, attachId:nil, error: error)
                    return
                }
                
                guard let data = responseData where data.length > 0  else
                {
                    completionClosure?(success: false, attachId: nil, error: nil)
                    return
                }
                
                let optionReading = NSJSONReadingOptions.AllowFragments
                
                do{
                    if let responseDict = try NSJSONSerialization.JSONObjectWithData(data, options: optionReading) as? [String:AnyObject] {
                        print("Success sending file to server: \n \(responseDict)")
                        if let attachID = responseDict["AttachFileToElementResult"] as? NSNumber
                        {
                            completionClosure?(success: true, attachId:attachID ,error: nil)
                        }
                    }
                    
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                
                }
                catch let error as NSError{
                    completionClosure?(success: false, attachId:nil ,error: error)
                     UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                }
                catch{
                    completionClosure?(success: false, attachId:nil ,error: nil)
                     UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                }
                
                
                
            })
            
            dataTask.resume()
            
            return
        }
        
        completionClosure?(success: false,  attachId:nil, error: noUserTokenError)
    }
        //remove attached file from element attaches
    func unAttachFile(name:String, fromElement elementId:Int, completion completionClosure:((success:Bool, error:NSError?)->() )?) {
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
            
            let requestString = "\(serverURL)" + unAttachFileUrlPart + "?elementId=" + "\(elementId)" + "&fileName=" + "\(name)" + "&token=" + "\(userToken)"
            let requestOperation = httpManager.GET(requestString,
                parameters: nil,
                success: { (operation, result) -> Void in
                    if let response = result["RemoveFileFromElementResult"] as? [NSObject:AnyObject]
                    {
                        print("\n --- Successfully unattached file from element: \(response)")
                    }
                   
                    completionClosure?(success: true, error: nil)
            },
                failure: { (operation, error) -> Void in
                    if let errorString = operation.responseString {
                        let lvError = NSError(domain: "Attachment Error", code: -44, userInfo: [NSLocalizedDescriptionKey:errorString])
                        
                            completionClosure?(success: false, error: lvError)
                        
                        
                    }
                    else {
                        
                        completionClosure?(success: false, error: error)
                        
                    }
            })
            
            requestOperation?.start()
            return
        }
        
        if  completionClosure != nil
        {
            completionClosure!(success: false, error: noUserTokenError)
        }
    }
    
    
    //MARK: Avatars
    func loadAvatarDataForUserName(loginName:String, completion:((avatarData:NSData?, error:NSError?) ->())? )
    {
        
        let userAvatarRequestURLString = serverURL + "GetPhoto?username=" + loginName
        if let requestURL = NSURL(string: userAvatarRequestURLString)
        {
            let mutableRequest = NSMutableURLRequest(URL: requestURL)
            mutableRequest.timeoutInterval = 30.0
            mutableRequest.HTTPMethod = "GET"
            
            let sessionTask = NSURLSession.sharedSession().dataTaskWithRequest(mutableRequest, completionHandler: { (responseData, response, responseError) -> Void in
                
                if let anError = responseError
                {
                    print("\(anError)")
                    completion?(avatarData: nil, error: anError)
                    return
                }
                
                
                if let responseBytes = responseData
                {

                    do{
                        if let jsonObject = try NSJSONSerialization.JSONObjectWithData(responseBytes, options: NSJSONReadingOptions.MutableContainers) as? [String:AnyObject]
                        {
                            if let response = jsonObject["GetPhotoResult"] as? [Int]
                            {
//                                var ints = [Int]()
//                                for aNumber in response
//                                {
//                                    ints.append(aNumber.integerValue)
//                                }
                                if let aData = NSData.dataFromIntegersArray(response)
                                {
                                    completion?(avatarData: aData, error: nil)
                                }
                                else
                                {
                                    completion?(avatarData: nil, error: nil)
                                }
                            }
                            
                        }
                        else
                        {
                            completion?(avatarData: nil, error: nil)
                        }

                    }catch let error as NSError{
                        completion?(avatarData: nil, error: error)
                    }
                    catch{
                       completion?(avatarData: nil, error: nil)
                    }
                }
                
                
            })
            
            sessionTask.resume()
        }
        
    }
    
    func uploadUserAvatarBytes(data:NSData, completion completionBlock:((response:[NSObject:AnyObject]?, error:NSError?)->())? )
    {
        /*
        NSData *imageData = UIImagePNGRepresentation(photo);
        NSInteger postLength = imageData.length;
        NSLog(@"uploadNewAvatar: Sending %ld bytes", (long)postLength);
        NSString *photoUploadURL = [NSString stringWithFormat:@"%@SetPhoto?token=%@", BasicURL, _currentUser.token];
        
        NSMutableURLRequest *mutableRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:photoUploadURL]];
        [mutableRequest setHTTPMethod:@"POST"];
        
        [mutableRequest setHTTPBody:imageData];
        
        [NSURLConnection sendAsynchronousRequest:mutableRequest
        queue:[NSOperationQueue currentQueue]
        completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
        {
        if (completionBlock)
        {
        if (data)
        {
        
        NSDictionary *responseDict = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        if (responseDict)
        {
        completionBlock(responseDict, nil);
        }
        else
        {
        NSError *lvError = [NSError errorWithDomain:@"ImageUploading failure" code:NSKeyValueValidationError userInfo:@{NSLocalizedDescriptionKey:@"Wrong request format"} ];
        completionBlock(nil, lvError);
        }
        }
        else if (connectionError)
        {
        NSLog(@"Eror sending photo: %@", connectionError);
        completionBlock(nil, connectionError);
        }
        }
        }];
        
        */
        
        if data.length == 0
        {
            let error = NSError(domain: "Origami.emptyData.Error", code: -605, userInfo: [NSLocalizedDescriptionKey : "Recieved empty data to upload."])
            completionBlock?(response: nil, error: error)
            return
        }
        
        if let userToken = DataSource.sharedInstance.user?.token as? String
        {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            let requestString = serverURL + "SetPhoto" + "?token=" + userToken
            if let url = NSURL(string: requestString)
            {
                let mutableRequest = NSMutableURLRequest(URL: url)
                mutableRequest.HTTPMethod = "POST"
                mutableRequest.HTTPBody = data
                
                let bgQueue = NSOperationQueue()
                NSURLConnection.sendAsynchronousRequest(mutableRequest, queue: bgQueue, completionHandler: { (response, responseData, responseError) -> Void in
                    
                    if let respError = responseError
                    {
                        completionBlock?(response: nil,error: respError)
                    }
                    else if let respData = responseData
                    {
                        do{
                            if let dataObject = try NSJSONSerialization.JSONObjectWithData(respData, options: NSJSONReadingOptions.AllowFragments) as? [String:AnyObject]
                            {
                                print("-> user avatar uploading result: \(dataObject)")
                                completionBlock?(response: dataObject, error: nil)
                            }
                            else
                            {
                                let errorReading = NSError(domain: "com.Origami.jsonCasting.Error", code: -5432, userInfo: [NSLocalizedDescriptionKey: "Failed to parse \"uploadUserAvatarBytes\" response"])
                                completionBlock?(response: nil, error: errorReading)
                            }
                            
                            
                        }catch let error as NSError{
                            completionBlock?(response: nil, error: error)
                        } catch{
                            completionBlock?(response: nil, error: nil)
                        }
                       
                    }
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                })
            }
            else
            {
                let error = NSError (domain: "Origami.internal", code: -606, userInfo: [NSLocalizedDescriptionKey: "Could not create URL for image uploading request"])
                completionBlock?(response: nil,error: error)
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            }
        }
        else
        {
            completionBlock?(response: nil, error: noUserTokenError)
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
                success: { (operation, result) -> Void in
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
            
            contactsRequestOp?.start()
            return
        }
        
        completionClosure?(contacts: nil, error: noUserTokenError)
        
    }
    
    func passElement(elementId:NSNumber, toContact contactId:NSNumber, forDeletion delete:Bool, completion completionClosure:(success:Bool, error: NSError?) -> ())
    {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        let elementIdInteger = (delete) ? elementId.integerValue * -1 : elementId.integerValue
        let rightElementId = NSNumber(integer: elementIdInteger)
        
        if let userToken = DataSource.sharedInstance.user?.token as? String
        {
            let requestString = serverURL + passElementUrlPart + "?token=" + userToken + "&elementId=" + "\(rightElementId)" + "&userPassTo=" + "\(contactId)"
            
            let serializer = AFJSONRequestSerializer()
            
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
                    print("\n ->passElement Response from server: \(resultDict)")
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
            
            requestOp?.start()
            return
        }
        
        completionClosure(success: false, error: noUserTokenError)
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    
    
    
    func passElement(elementId : Int, toSeveratContacts contactIDs:Set<Int>, completion completionClosure:((succeededIDs:[Int], failedIDs:[Int])->())?)
    {
        guard let token = DataSource.sharedInstance.user?.token as? String else
        {
            print(" -> no user token")
            completionClosure?(succeededIDs: [], failedIDs: Array(contactIDs))
            return
        }
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
       
        var failedIDs = [Int]()
        var succededIDs = [Int]()
        let contactIDsCount = contactIDs.count
        var completedRequestsCount:Int = 0
        
        for lvUserID in contactIDs
        {
            let addSrtingURL = serverURL + passElementUrlPart + "?token=" + token + "&elementId=" + "\(elementId)" + "&userPassTo=" + "\(lvUserID)"
            
            if let addUrl = NSURL(string: addSrtingURL)
            {
                let request:NSMutableURLRequest = NSMutableURLRequest(URL: addUrl)
                request.HTTPMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                
                
                let dataTask = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: {(responseData, urlResponse, responseError) -> Void in
                    if let _ = responseError
                    {
                        failedIDs.append(lvUserID)
                    }
                    else if let data = responseData
                    {
                        do{
                            if let dict = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as? [String:AnyObject]
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
                            
                            completedRequestsCount = completedRequestsCount + 1
                        }
                        catch{
                            failedIDs.append(lvUserID)
                            completedRequestsCount = completedRequestsCount + 1
                        }
                    }
                    
                    
                    
                    if completedRequestsCount == contactIDsCount
                    {
                        completionClosure?(succeededIDs: succededIDs, failedIDs: failedIDs)
                    }

                })
                
                dataTask.resume()
            }
            else
            {
                failedIDs.append(lvUserID)
            }
        }
        
        NSOperationQueue.mainQueue().addOperationWithBlock{ () -> Void in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            print("succeeded contact ids: \(succededIDs)")
            completionClosure?(succeededIDs: succededIDs, failedIDs: failedIDs)
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
                success: { (operation, result) -> Void in
                    NSOperationQueue().addOperationWithBlock({ () -> Void in
                        if let completionBlock = completion
                        {
                            if let lvContactsArray = result["GetAllContactsResult"] as? [[String:AnyObject]]
                            {
                                let convertedContacts = ObjectsConverter.convertToContacts(lvContactsArray)
                                
                                //print("Loaded all contacts:\(convertedContacts)")
                                
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
            
            contactsRequestOp?.start()
            return
        }
        
        if let completionBlock = completion
        {
            completionBlock(contacts: nil, error: noUserTokenError)
        }

    }
    
    func toggleContactFavourite(contactId:Int, completion:((success:Bool, error:NSError?)->())?)
    {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        if let userToken = DataSource.sharedInstance.user?.token as? String
        {
            let favUrlString = serverURL + favContactURLPart + "?token=" + userToken + "&contactId=" + "\(contactId)"
            
            let favOperation = httpManager.GET(favUrlString, parameters: nil, success: { (operation, response) -> Void in
                if let _ = response as? [String:AnyObject]
                {
                    if let completionBlock = completion
                    {
                        completionBlock(success: true, error: nil)
                    }
                }
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            }, failure: { (operation, error) -> Void in
                if let completionBlock = completion
                {
                    completionBlock(success: false, error: error)
                }
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            })
            
            favOperation?.start()
            return
        }
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        if let completionBlock = completion
        {
            completionBlock(success: false, error: noUserTokenError)
        }
    }
    
    func removeMyContact(contactId:Int, completion:((success:Bool, error:NSError?)->())?)
    {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        if let userToken = DataSource.sharedInstance.user?.token as? String
        {
            let removeUrlString = serverURL + "RemoveContact" + "?token=" + userToken + "&contactId=" + "\(contactId)"
            let removeContactOperation = httpManager.GET(removeUrlString, parameters: nil, success: { (operation, response) -> Void in
                if let _ = response as? [String:AnyObject]
                {
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    if let completionBlock = completion
                    {
                        completionBlock(success: true, error: nil)
                    }
                }
                }, failure: { (operation, error) -> Void in
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    if let completionBlock = completion
                    {
                        completionBlock(success: false, error: error)
                    }
            })
            
            removeContactOperation?.start()
            return
        }
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        if let completionBlock = completion
        {
            completionBlock(success: false, error: noUserTokenError)
        }
    }
    
    func addToMyContacts(contactId:Int, completion:((success:Bool, error:NSError?)->())?)
    {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        if let userToken = DataSource.sharedInstance.user?.token as? String
        {
            let addUrlString = serverURL + "AddContact" + "?token=" + userToken + "&contactId=" + "\(contactId)"
            let addContactOperation = httpManager.GET(addUrlString, parameters: nil, success: { (operation, response) -> Void in
                if let _ = response as? [String:AnyObject]
                {
                    if let completionBlock = completion
                    {
                        completionBlock(success: true, error: nil)
                    }
                }
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                }, failure: { (operation, error) -> Void in
                    if let completionBlock = completion
                    {
                        completionBlock(success: false, error: error)
                    }
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            })
            
            addContactOperation?.start()
            return
        }
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        if let completionBlock = completion
        {
            completionBlock(success: false, error: noUserTokenError)
        }
    }
}
