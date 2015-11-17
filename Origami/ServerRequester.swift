//
//  ServerRequester.swift
//  Origami
//
//  Created by CloudCraft on 08.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

typealias messagesTuple = (chat:[Message], service:[Message])

class ServerRequester: NSObject, NSURLSessionTaskDelegate, NSURLSessionDataDelegate
{
    
    static let urlCreatingError = NSError(domain: "URL-Error", code: -102, userInfo: [NSLocalizedDescriptionKey:"Could not create valid URL for request."])
    
    typealias networkResult = (AnyObject?,NSError?) -> ()
    typealias sessionRequestCompletion = (NSData?, NSURLResponse?, NSError?) -> ()
    
    typealias messagesCompletionBlock = (messages:TypeAliasMessagesTuple?, error:NSError?) -> ()
    let httpManager:AFHTTPSessionManager// = AFHTTPSessionManager()
    var urlSession:NSURLSession!
    let objectsConverter = ObjectsConverter()
    
    override init() {
        
        let policy = AFSecurityPolicy(pinningMode: .Certificate)
        policy.allowInvalidCertificates = true
        policy.validatesDomainName = false
        self.httpManager = AFHTTPSessionManager(baseURL: NSURL(string: serverURL))
       // AFHTTPSessionManager(baseURL: <#T##NSURL?#>, sessionConfiguration: <#T##NSURLSessionConfiguration?#>)
        self.httpManager.securityPolicy = policy
        
        super.init()
        
        self.urlSession =  NSURLSession(configuration: NSURLSessionConfiguration.ephemeralSessionConfiguration(), delegate: self, delegateQueue: nil)
    }
    
    lazy var datatasksForPassElementRequest = [Int:NSURLSessionDataTask]()
    
    
    //MARK: User
    func registerNewUser(firstName:String, lastName:String, userName:String, completion:(success:Bool, error:NSError?) ->() )
    {
        let requestString:String = "\(serverURL)" + "\(registerUserUrlPart)"
        let parametersToRegister = [firstNameKey:firstName, lastNameKey:lastName, loginNameKey:userName]
        
        let dataTask = httpManager.GET(requestString,
            parameters: parametersToRegister,
            success:
            { (task, responseObject) -> Void in
            
                completion(success: true, error: nil)
                
            },
            failure: { (task, responseError) -> Void in
                
            completion(success: false, error: responseError)
                
        })
        
        dataTask?.resume()
    }
    
    func editUser(userToEdit:User, completion:((success:Bool, error:NSError?) -> ())? )
    {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        let requestString:String = "\(serverURL)" + "\(editUserUrlPart)"
        let dictUser = userToEdit.toDictionary()
        
        //debug birthday
        let dictionaryDebug = NSDictionary(dictionary: dictUser)
        print("birthday sending: \((dictionaryDebug["BirthDay"] as! String).dateFromServerDateString())")
        let params = ["user":dictUser]
        
        let jsonSerializer = httpManager.responseSerializer
        
        let requestSerializer = AFJSONRequestSerializer()
        requestSerializer.setValue("application/json", forHTTPHeaderField:"Content-Type")
        requestSerializer.setValue("application/json", forHTTPHeaderField: "Accept")
        httpManager.requestSerializer = requestSerializer
        
        
        if let acceptableTypes = jsonSerializer.acceptableContentTypes as? Set<String>
        {
            var newSet = acceptableTypes//NSMutableSet(set: acceptableTypes)
            newSet.unionInPlace( Set(["text/html", "application/json"]) )
            jsonSerializer.acceptableContentTypes = newSet as Set<NSObject>
        }
      
        let editTask = httpManager.POST(
            requestString,
            parameters: params,
            success:
            { (task, resultObject) -> Void in
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
                
                print("\n -> Edit user Error: \(responseError)")
                
            completion?(success: false, error: responseError)
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
        
        editTask?.resume()
    }
    
    func loginWith(userName:String, password:String, completion:networkResult?)
    {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        let requestString:String = "\(serverURL)" + "\(loginUserUrlPart)" + "?username=" + userName + "&password=" + password
        //let params = ["username":userName, "password":password]
        
        guard let loginURL = NSURL(string: requestString) else {
            completion?(nil, NSError(domain: "com.Origami.UrlFormat.error", code: -1020, userInfo: [NSLocalizedDescriptionKey : "Could not validate url for login."]))
            return
        }
        
        let loginRequest = NSMutableURLRequest(URL: loginURL, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringCacheData, timeoutInterval: 30.0)
        loginRequest.setValue("application-json", forHTTPHeaderField: "Accept")
        loginRequest.setValue("application-json", forHTTPHeaderField: "Content-Type")
        
        let completionClosure :sessionRequestCompletion =  { (responseData, urlResponse, responseError) -> Void in
            
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            
            if let anError = responseError
            {
                completion?(nil, anError)
                return
            }
            
            if let aData = responseData
            {
                //print("\(aData.description)")
                
                do{
                    var userToReturn:User?
                    
                    if let jsonDict = try NSJSONSerialization.JSONObjectWithData(aData, options: .MutableLeaves) as? [String:AnyObject]
                    {
                        if let userDict = jsonDict["LoginResult"] as? [String:AnyObject]
                        {
                            userToReturn = User()
                            if let _ = userToReturn
                            {
                                do {
                                    try userToReturn!.setInfo(userDict)
                                }
                                catch let error as InternalDiagnosticError {
                                    print("Error while setting User Info: \(error)")
                                    
                                    completion?(nil, NSError(domain: "com.Origami.DataError", code: -1032, userInfo: [NSLocalizedDescriptionKey:"Could not setup logged user info."]))
                                    return
                                }
                            }
                        }
                    }
                    
                    if let aUser = userToReturn
                    {
                        completion?(aUser,nil)
                    }
                    else
                    {
                        completion?(nil, NSError(domain: "com.Origami.DataError", code: -1032, userInfo: [NSLocalizedDescriptionKey:"Could not parse logged user data."]))
                    }
                }
                catch let jsonError as NSError{
                    
                    //try to handle error response string from server
                    var shouldProceedError = false
                    
                    if let errorResponseString = String(data: aData, encoding: NSUTF8StringEncoding)
                    {
                        completion?(nil, NSError(domain: "com.Origami.ServerResponse", code: -1037, userInfo: [NSLocalizedDescriptionKey:errorResponseString]))
                        return
                    }
                    
                    do{
                        if let errorMessage = try NSJSONSerialization.JSONObjectWithData(aData, options: .MutableLeaves) as? String
                        {
                            completion?(nil, NSError(domain: "com.Origami.ServerResponse", code: -1034, userInfo: [NSLocalizedDescriptionKey:errorMessage]))
                        }
                    }
                    catch let jsonToStringError as NSError{
                        completion?(nil, jsonToStringError)
                    }
                    catch{
                        shouldProceedError = true
                    }
                    
                    if shouldProceedError{
                        completion?(nil, jsonError)
                    }
                }
                catch{
                    completion?(nil, NSError(domain: "com.Origami.ExceprionError", code: -1033, userInfo: [NSLocalizedDescriptionKey:"UnknownExceptionError"]))
                }
            }
        }
        
        self.performGETqueryWithURL(loginURL, onQueue:nil, completion: completionClosure)
    }
    
    //MARK: Languages & Countries
    
    func loadLanguages(completion:((languages:[Language]?, error:NSError?) -> ())?)
    {
        let languagesUrlString = serverURL + getLanguagesUrlPart
        

        
        guard let url = NSURL(string: languagesUrlString) else
        {
            completion?(languages: nil, error:OrigamiError.PreconditionFailure(message: "Could not create valid url for request") as NSError)
            return
        }
        
        let completionCountriesClosure :sessionRequestCompletion = {(data, response, error) in
            do{
                if let
                    dataRecieved = data ,
                    responseObject = try NSJSONSerialization.JSONObjectWithData(dataRecieved, options: .MutableContainers) as? [String:AnyObject],
                    languageDicts = responseObject["GetLanguagesResult"] as? [[String:AnyObject]],
                    languageObjects = ObjectsConverter.convertToLanguages(languageDicts)
                {
                    completion?(languages:languageObjects, error:nil)
                }
                else
                {
                    completion?(languages: nil, error: OrigamiError.NotFoundError(message: "Could not get countries from server.") as NSError)
                }
            }
            catch let errorJSON
            {
                completion?(languages: nil, error: errorJSON as NSError)
            }
        }
        
        self.performGETqueryWithURL(url, onQueue: nil, priority: 0.5, completion: completionCountriesClosure)

        
        
        
        
//        let langOperation = httpManager.GET(languagesUrlString,
//            parameters: nil,
//            success: { (operation, responseObject) -> Void in
//                
//                let bgQueue = dispatch_queue_create("languages.queue", DISPATCH_QUEUE_SERIAL)
//                dispatch_async(bgQueue, { () -> Void in
//                    
//                    if let languagesDict = responseObject["GetLanguagesResult"] as? [[String:AnyObject]],  languages = ObjectsConverter.convertToLanguages(languagesDict)
//                    {
//                        completion?(languages:languages, error:nil)
//                    }
//                    else
//                    {
//                        let anError = NSError(domain: "LanguagesError", code: -409, userInfo: [NSLocalizedDescriptionKey:"Could not convert data to langages"])
//                        completion?(languages: nil, error:anError)
//                    }
//                })
//                
//                
//                
//            })/*failure*/
//            { (operation, responseError) -> Void in
//                print(responseError)
//                completion?(languages:nil, error: responseError)
//                
//            }
//        
//        langOperation?.resume()
    }
    
    func loadCountries(completion:((countries:[Country]?, error:NSError?) ->())?)
    {
        let countriesUrlString = serverURL + getCountriesUrlPart
        
        guard let url = NSURL(string: countriesUrlString) else
        {
            completion?(countries:nil, error:OrigamiError.PreconditionFailure(message: "Could not create valid url for request") as NSError)
            return
        }
        
        let completionCountriesClosure :sessionRequestCompletion = {(data, response, error) in
            do{
                if let
                    dataRecieved = data ,
                    responseObject = try NSJSONSerialization.JSONObjectWithData(dataRecieved, options: .MutableContainers) as? [String:AnyObject],
                    countryDicts = responseObject["GetCountriesResult"] as? [[String:AnyObject]],
                    countryObjects = ObjectsConverter.convertToCountries(countryDicts)
                {
                    completion?(countries:countryObjects, error:nil)
                }
                else
                {
                    completion?(countries: nil, error: OrigamiError.NotFoundError(message: "Could not get countries from server.") as NSError)
                }
            }
            catch let errorJSON
            {
                completion?(countries: nil, error: errorJSON as NSError)
            }
        }
        
        self.performGETqueryWithURL(url, onQueue: nil, priority: 0.5, completion: completionCountriesClosure)
        
//        return
//        
//        let countriesOp = httpManager.GET(countriesUrlString,
//            parameters: nil,
//            success: { (operation, responseObject) -> Void in
//            
//            let bgQueue = dispatch_queue_create("countries.queue", DISPATCH_QUEUE_SERIAL)
//            dispatch_async(bgQueue, { () -> Void in
//                
//                if let countriesDicts = responseObject["GetCountriesResult"] as? [[String:AnyObject]], countries = ObjectsConverter.convertToCountries(countriesDicts)
//                {
//                    completion?(countries: countries, error: nil)
//                }
//                else
//                {
//                    let anError = NSError(domain: "CountriesError", code: -409, userInfo: [NSLocalizedDescriptionKey:"Could not convert data to countries"])
//                    completion?(countries: nil, error:anError)
//                }
//                
//            })
//        })
//                { (operation, responseError) -> Void in
//                    
//            print(responseError)
//            completion?(countries:nil, error: responseError)
//        }
//            
//        countriesOp?.resume()
    }
 
    
    //MARK: Elements
    func loadAllElements(completion:networkResult?)
    {
        guard let tokenString = DataSource.sharedInstance.user?.token else {
            completion?(nil,noUserTokenError)
            return
        }
        
        let allElementsRequestString = "\(serverURL)" + "\(getElementsUrlPart)" + "?token=" + tokenString
        
        guard let requestURL = NSURL(string: allElementsRequestString) else {
            
            completion?(nil, nil)
            return
        }
        
        print(" -> Starting to load all elements ...")
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        let mutableRequest = NSMutableURLRequest(URL: requestURL)
        mutableRequest.setValue("application-json", forHTTPHeaderField: "Accept")
        
        let completionHandler:sessionRequestCompletion = {(responseData, urlResponse, responseError) in
            
        
            if let anError = responseError {
                completion?(nil, anError)
                return
            }
            
            if let aData = responseData
            {
                do{
                    if let serverResponseJson = try NSJSONSerialization.JSONObjectWithData(aData, options: NSJSONReadingOptions.MutableLeaves) as? [String:[[String:AnyObject]]], elementsArray = serverResponseJson["GetElementsResult"]
                    {
                        var elements = [Element]()
                        for lvElementDict in elementsArray
                        {
                            let lvElement = Element()
                            lvElement.setInfo(lvElementDict)
                            
                            elements.append(lvElement)
                        }
                        
                        print("\n -> Server requester loaded \(elements.count) elements ... ")
                        ObjectsConverter.sortElementsByElementId(&elements)
//                        //debug
//                        print("sortedElements: \(elements.count)")
//                        for anElement in elements
//                        {
//                            print("ElementID: \(anElement.elementId!), rootId: \(anElement.rootElementId)")
//                        }
                        completion?(elements,nil)
                    }
                    else
                    {
                        completion?(nil, NSError(domain: "com.Origami.WrongDataFormet.Error", code: -4321, userInfo: [NSLocalizedDescriptionKey:"Could not process response feom server while querying all attaches"]))
                    }
                }
                catch{
                    completion?(nil, NSError(domain: "com.Origami.JSONparsingError.", code: -3844, userInfo: [NSLocalizedDescriptionKey: "target JSON object could not be parsed as target data structure."]))
                }
            }
        }
        
        let targetQueue = getBackgroundQueue_DEFAULT()
        
        self.performGETqueryWithURL(requestURL, onQueue: targetQueue, completion: completionHandler)
        
    }
    
    
    func submitNewElement(element:Element, completion:networkResult)
    {
        guard let tokenString = DataSource.sharedInstance.user?.token else {
            
            completion(nil,noUserTokenError)
            return
        }
        
        let bgQueue = dispatch_queue_create("submit sueue", DISPATCH_QUEUE_SERIAL)
        dispatch_async(bgQueue) { [unowned self] () -> Void in
            
        let elementDict = element.toDictionary()
        print(" Submitting new element to server: \n")
        print(elementDict)
        print("\n<--")
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
                    completion(nil, error)

        })
        
        postOperation?.resume()
        }//end of bg queue
    }
    
    func editElement(element:Element, completion completionClosure:(success:Bool, error:NSError?) -> () )
    {
        guard let userToken = DataSource.sharedInstance.user?.token else {
            completionClosure(success: false, error: noUserTokenError)
            return
        }
        

        let editUrlString = "\(serverURL)" + "\(editElementUrlPart)" + "?token=" + "\(userToken)"
        
        guard let editRequestURL = NSURL(string: editUrlString) else
        {
            completionClosure(success: false, error: OrigamiError.NotFoundError(message: "Could Not Create Valid URL for request.") as NSError)
            return
        }
        
        
        
        let editRequest = NSMutableURLRequest(URL: editRequestURL)
        editRequest.HTTPMethod = "POST"
        editRequest.setValue("application/json", forHTTPHeaderField:"Content-Type")
        editRequest.timeoutInterval = 15.0
        
        var elementDict = element.toDictionary()
        if let archDateString = elementDict["ArchDate"] as? String
        {
            if archDateString ==  "/Date(0+0000)/"
            {
                NSLog(" -> Archive date of element to pass: \n \(archDateString)\n <---<")
                elementDict["ArchDate"] = "/Date(0)/"
            }
        }
        
        let params = ["element":elementDict]
        
        let serializator = AFJSONRequestSerializer()
        do
        {
            let request = try serializator.requestBySerializingRequest(editRequest, withParameters: params)
            
            let editDataTask = NSURLSession.sharedSession().dataTaskWithRequest(request) { (dataResponse, urlResponse, errorResponse) -> Void in
                
                guard let data = dataResponse else
                {
                    if let error = errorResponse
                    {
                        completionClosure(success: false, error: error)
                        return
                    }
                    completionClosure(success: false, error: OrigamiError.UnknownError as NSError)
                    return
                }
                
                if data.length == 0
                {
                    completionClosure(success: true, error: nil)
                    return
                }
                
                do
                {
                    if let serverNormalResponseObject = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as? [String:AnyObject]
                    {
                        guard let resultObject = serverNormalResponseObject["EditElementResult"]  as? [String:AnyObject]else
                        {
                            //normal success response
                            completionClosure(success: true, error: nil)
                            return
                        }
                        
                        print("EditElement Server Response:")
                        print(resultObject)
                        completionClosure(success: true, error: OrigamiError.UnknownError as NSError)
                    }
                }
                catch let jsonParsingError
                {
                    if let serverReadableError = String(data: data, encoding: NSUTF8StringEncoding)
                    {
                        completionClosure(success: false, error: OrigamiError.NotFoundError(message: serverReadableError) as NSError)
                        return
                    }
                    
                    completionClosure(success: false, error: jsonParsingError as NSError)
                }
                
            }// end of editDataTask block
            
            editDataTask.resume()
            return
        }
        catch let error
        {
            print("Could not create request for editing an element. :")
            print(error)
            
            completionClosure(success:false, error: error as NSError)
            return
        }
    }
    
    func setElementWithId(elementId:NSNumber, favourite isFavourite:Bool, completion completionClosure:(success:Bool, error:NSError?)->())
    {
        guard let userToken = DataSource.sharedInstance.user?.token else
        {
            completionClosure(success: false, error: noUserTokenError)
            return
        }
        
        let requestString = "\(serverURL)" + "\(favouriteElementUrlPart)" + "?elementId=" + "\(elementId.integerValue)" + "&token=" + "\(userToken)"
        
        let requestSerializer = AFJSONRequestSerializer()
        requestSerializer.timeoutInterval = 15.0
        requestSerializer.setValue("application/json", forHTTPHeaderField:"Content-Type")
        requestSerializer.setValue("application/json", forHTTPHeaderField: "Accept")
        httpManager.requestSerializer = requestSerializer
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        let editRequestOperation = httpManager.POST(requestString,
            parameters: nil,
            success: { (operation, resultObject) -> Void in
                
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                completionClosure(success: true, error: nil)
            },
            failure: { (operation, error) -> Void in
                
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
               
                completionClosure(success: false, error: error)
                
        })
        
        editRequestOperation?.resume()
        
    }
    
    
    func loadPassWhomIdsForElementID(elementId:Int, completion completionClosure:((Set<Int>?, NSError?)->())? )
    {
        guard let userToken = DataSource.sharedInstance.user?.token else {
            completionClosure?(nil, NSError(domain: "TokenError", code: -101, userInfo: [NSLocalizedDescriptionKey:"No User token found."]))
            return
        }
        
        let requestString = "\(serverURL)" + "\(passWhomelementUrlPart)" + "?elementId=" + "\(elementId)" + "&token=" + "\(userToken)"
        
        guard let urlForRequest = NSURL(string: requestString) else {
            completionClosure?(nil, ServerRequester.urlCreatingError)
            return
        }
    
        let request = NSMutableURLRequest(URL: urlForRequest)
        request.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringCacheData
        request.setValue("application-json", forHTTPHeaderField: "Accept")
        
        let requestTask = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: { (responseData, urlResponse, responseError) -> Void in
            
            if let error = responseError
            {
                completionClosure?(nil, error)
                return
            }
            
            if let aData = responseData
            {
                do{
                    if let responseValue = try NSJSONSerialization.JSONObjectWithData(aData, options: .MutableContainers) as? [String:AnyObject]
                    {
                        if let arrayOfIDs = responseValue["GetPassWhomIdsResult"] as? [Int]
                        {
                            let aSet = Set(arrayOfIDs)
                            print(aSet)
                            if let comp = completionClosure
                            {
                                comp(aSet, nil)
                            }
                        }
                    }
                }
                catch let jsonError as NSError {
                    completionClosure?(nil, jsonError)
                }
                catch{
                    completionClosure?(nil, NSError(domain: "com.Origami.UnknownError.", code: -1030, userInfo: [NSLocalizedDescriptionKey:"Unknown exception during parsing server response"]))
                }
            }
        })
        
        let bgLowQueue:dispatch_queue_t?
        if #available (iOS 8.0, *)
        {
            bgLowQueue = dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)
        }
        else
        {
            bgLowQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)
        }
        if let ourQueue = bgLowQueue
        {
            dispatch_async(ourQueue, { () -> Void in
                requestTask.resume()
            })
        }
    }
    
    func deleteElement(elementID:Int, completion closure:(deleted:Bool, error:NSError?) ->())
    {
        // "DeleteElement?elementId={elementId}&token={token}" POST
        let token = DataSource.sharedInstance.user!.token! as String
        
        let deleteString = serverURL + deleteElementUrlPart + "?token=" + token + "&elementId=" + "\(elementID)"
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        let deleteOperation = httpManager.POST(deleteString,
            parameters: nil,
            success: { (task, responseObject) -> Void in
                if let dict = responseObject as? [String:AnyObject]
                {
                    print("Success response while deleting element: \(dict) ")
                }
                closure(deleted: true, error: nil)
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }) { (task, failureError) -> Void in      /*...failure closure...*/
            
            
                closure(deleted: false, error: failureError)
            
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
        
        deleteOperation?.resume()
    }
    
    func setElementFinished(elementId:Int, finishDate:String, completion:((success:Bool)->())?)
    {
        //SetFinished
        guard let userToken = DataSource.sharedInstance.user?.token else {
            completion?(success:false)
            return
        }
        
        let requestString = serverURL + finishDateUrlPart + "?token=" + userToken + "&elementId=" + "\(elementId)" + "&date=" + "\(finishDate)"
        
        print("\nSending finish date: \(finishDate)  to element: \(elementId)")
        
        guard let url = NSURL(string: requestString) else
        {
            completion?(success:false)
            return
        }
        
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            let finishStateRequest = NSMutableURLRequest(URL: url)
            print(url.absoluteString)
            finishStateRequest.HTTPMethod = "POST"
            finishStateRequest.setValue("application/json", forHTTPHeaderField: "Accept")
            finishStateRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let postFinishStateTask = NSURLSession.sharedSession().dataTaskWithRequest(finishStateRequest, completionHandler: {[weak self] (aData:NSData?, response:NSURLResponse?, anError:NSError?) -> Void in
                
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                
                if let error = anError
                {
                    NSLog(" Error Setting finish Date for element:   \n \(error.description)")
                    completion?(success:false)
                }
                
                if let data = aData
                {
                    if data.length > 0
                    {
                        if let weakSelf = self
                        {
                            if let completionBlock = completion
                            {
                                weakSelf.handleResponseWithData(data, completion: completionBlock)
                                return
                            }
                        }
                        else{
                            
                        }
                    }
                }
           
                })
            
            //start network query
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                postFinishStateTask.resume()
            })
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
            
            if let serverResponseString = NSString(data: data, encoding: NSUTF8StringEncoding) as? String
            {
                print("-->\n Error from Server: \n \(serverResponseString)\n<-")
            }
        }
        catch {
            print("\n -> Did catch unknown error...")
        }

    }
    
    func setElementFinishState(elementId:Int, finishState:Int, completion:((success:Bool)->())?)
    {
        //SetFinishState
        
        if let userToken = DataSource.sharedInstance.user?.token// as? String
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
    func loadAllMessages(completion: ((messages:(chat: [Message], service:[Message])?, error:NSError?) -> ())?)
    {
        guard let tokenString = DataSource.sharedInstance.user?.token else
        {
            completion?(messages:nil, error:noUserTokenError)
            return
        }
        
        let urlString = "\(serverURL)" + "\(getAllMessagesPart)" + "?token=" + "\(tokenString)"
        
        guard let urlAllMessages = NSURL(string: urlString) else
        {
            completion?(messages: nil, error: OrigamiError.PreconditionFailure(message: "Could not create valid URL for request") as NSError)
            return
        }
        
        self.performGETqueryWithURL(urlAllMessages, onQueue: nil, priority: 0.6) { (data, response, error) -> () in
            guard let recievedData = data else
            {
                if let errorRecieved = error
                {
                    completion?(messages: nil, error: errorRecieved)
                    return
                }
                
                completion?(messages: nil, error: OrigamiError.NotFoundError(message: "Error while requesting all messages.") as NSError )
                return
            }
            
            
            do
            {
                if let
                    responseObject = try NSJSONSerialization.JSONObjectWithData(recievedData, options: .MutableLeaves) as? [String:[[String:AnyObject]]],
                    messageInfos = responseObject["GetMessagesResult"],
                    messages = ObjectsConverter.convertToMessages(messageInfos)
                {
                    completion?(messages:messages, error:nil)
                }
                else
                {
                    completion?(messages: nil, error: OrigamiError.UnknownError as NSError)
                }
            }
            catch let jsonError
            {
                completion?(messages: nil, error: jsonError as NSError)
            }
            
        }
        
        
        
//        let messagesOp = httpManager.GET(urlString,
//            parameters: nil,
//            success:
//            { (operation, result) -> Void in
//                
//                dispatch_async(getBackgroundQueue_UTILITY(), { () -> Void in
//                    if let
//                        lvResultDict = result as? [String:AnyObject],
//                        messageDictsArray = lvResultDict["GetMessagesResult"] as? [[String:AnyObject]],
//                        messagesArray = ObjectsConverter.convertToMessages(messageDictsArray)
//                    {
//                        completion?(messages:messagesArray, error:nil)
//                    }
//                })
//               
//            })
//            { /*failure closure*/(task, requestError) -> Void in
//                completion?(messages:nil, error:requestError)
//        }
//        
//        messagesOp?.resume()
    }
    
    func sendMessage(message:String, toElement elementId:Int, completion:networkResult?)
    {
        print(" -> sendMessage Called.")
        //POST
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        guard let tokenString = DataSource.sharedInstance.user?.token else {
            completion?(nil, noUserTokenError)
            return
        }
        
        let postUrlString =  "\(serverURL)" + "\(sendMessageUrlPart)" + "?token=" + "\(tokenString)" + "&elementId=" + "\(elementId)"// + "&msg=" + message
        
        httpManager.requestSerializer = AFJSONRequestSerializer()
        
        let messagePostTask = httpManager.POST(postUrlString,
            parameters: ["msg":message],
            success: { (task, responseObject) in
            
                dispatch_async(getBackgroundQueue_DEFAULT()) { () -> Void in
                    print(responseObject)
                    completion?(responseObject, nil)
                }
            
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            }) /*failure block -> */ { (task, responseError) in
            
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                completion?(nil, responseError)
        }
        
        messagePostTask?.resume()
    }
    
    
    func loadNewMessages(completion:messagesCompletionBlock?)
    {
        guard let userToken = DataSource.sharedInstance.user?.token else
        {
            if let completionBlock = completion
            {
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                completionBlock(messages:nil, error:noUserTokenError)
            }
            return
        }
        
        let newMessagesURLString = serverURL + getNewMessagesUrlPart + "?token=" + userToken
        
        guard let lastMessagesRequestURL = NSURL(string: newMessagesURLString) else {
            completion?(messages: nil, error:ServerRequester.urlCreatingError)
            return
        }
        
        let messagesRequest = NSMutableURLRequest(URL: lastMessagesRequestURL)
        
        let messagesTask = NSURLSession.sharedSession().dataTaskWithRequest(messagesRequest) { (responseData, urlResponse, responseError)  in
            
            if let error = responseError
            {
                completion?(messages:nil, error:error)
                return
            }
            
            //else
            if let recievedData = responseData
            {
                do
                {
                    if let messagesInfo = try NSJSONSerialization.JSONObjectWithData(recievedData, options: .MutableLeaves) as? [String:[[String:AnyObject]]]
                    {
                        //convert to messages and return completion block
                        
                        if let newMessageInfos = messagesInfo["GetNewMessagesResult"]
                        {
                            if let messagesArrayTuple = ObjectsConverter.convertToMessages(newMessageInfos)
                            {
                                print("\n -> loaded new Messages")
                                
                                completion?(messages: TypeAliasMessagesTuple(messagesTuple:messagesArrayTuple), error: nil)
                            }
                            else
                            {
                                //print("loaded empty messages: \(newMessageInfos)")
                                completion?(messages: nil, error: nil)
                            }
                            return
                        }
                        completion?(messages:nil, error:nil)
                        return
                    }
                    else
                    {
                        //return completion with failed convertation error
                        completion?(messages:nil, error:nil)
                    }
                }
                catch let jsonParsingError as NSError
                {
                    
                    guard let responseString = NSString(data: recievedData, encoding: NSUTF8StringEncoding) else
                    {
                        completion?(messages: nil, error: jsonParsingError)
                       return
                    }
                    print(" ERROR WHILE LOADING LAST MESSAGES: \n \(responseString)")
                    
                    if responseString == "\"You are not valid user! Sorry!\""
                    {
                        DataSource.sharedInstance.user?.token = nil
                        completion?(messages: nil, error: noUserTokenError)
                        return
                    }
                    
                    completion?(messages:nil, error:NSError(domain: "com.Origami.LastMessagesQueryError", code: -201, userInfo: [NSLocalizedDescriptionKey:responseString]))
                }
                catch{
                    
                }
            }
            else
            {
                completion?(messages:nil, error:nil)
            }
            
        }
        
        
        messagesTask.resume()
    }
    
    /**
    Loads all messages, which are new to current device
    - Parameter messageId: last(highest) message id stored on device
    - Parameter completion: completion block containing message tuple or error if query fails or no new messages loaded.
    */
    func loadNewMessagesWithLastMessageID(messageId:Int, completion:( (TypeAliasMessagesTuple?, error:NSError?) ->() )?)
    {
        guard let userToken = DataSource.sharedInstance.user?.token else
        {
            completion?(nil, error:noUserTokenError)
            return
        }
        
        let requestString = serverURL + getMessagesToSyncUrlPart + "?token=" + userToken + "&messageId=" + "\(messageId)"
        
        guard let requestURL = NSURL(string: requestString) else {
            completion?(nil, error:ServerRequester.urlCreatingError )
            return
        }
        
        self.performGETqueryWithURL(requestURL, onQueue: nil) { (responseData, urlResponse, responseError) -> Void in
            if let error = responseError{
                completion?(nil, error:error)
                return
            }
            
            if let aData = responseData
            {
                do{
                    if let responseDict = try NSJSONSerialization.JSONObjectWithData(aData, options: .MutableLeaves) as? [String:[[String:AnyObject]]]
                    {
                        //print(responseDict)
                        if responseDict.isEmpty
                        {
                            completion?(nil, error: nil)
                            return
                        }
                        guard let dictsArray = responseDict["GetNewMessagesExResult"] else {
                            completion?(nil, error:NSError(domain: "com.Origami.WrongDataFormat", code: -1035, userInfo: [NSLocalizedDescriptionKey:"Wrong ResponseFormat for messages syncronization query"]))
                            return
                        }
                        
                        guard let validTuple = ObjectsConverter.convertToMessages( dictsArray) else {
                            completion?(nil, error:nil)
                            return
                        }
                        
                        completion?(TypeAliasMessagesTuple(messagesTuple: validTuple), error:nil)
                        
                    }
                }
                catch let jsonError as NSError {
                    if let errorString = String(data: aData, encoding: NSUTF8StringEncoding)
                    {
                        completion?(nil, error:OrigamiError.NotFoundError(message: errorString) as NSError)
                        return
                    }
                    completion?(nil, error:jsonError)
                }
                catch{
                    completion?(nil, error:unKnownExceptionError)
                }
                return
            }
            
            completion?(nil, error:NSError(domain: "com.Origami.EmptyResponseData.Error", code: -2020, userInfo: [NSLocalizedDescriptionKey:"Empty Response data recieved."]))
        }
        
    }
    
    //MARK: Attaches
    func loadAttachesListForElementId(elementId:Int, completion:networkResult?)
    {
        if let userToken = DataSource.sharedInstance.user?.token
        {
            let requestString = "\(serverURL)" + getElementAttachesUrlPart + "?elementId=" + "\(elementId)" + "&token=" + userToken
            if let attachURL = NSURL(string: requestString)
            {
                self.performGETqueryWithURL(attachURL, onQueue: nil, priority: 0.7, completion: { (responseData, response, error) -> () in
                    if let anError = error
                    {
                        completion?(nil, anError)
                        return
                    }
                    
                    if let aData = responseData
                    {
                        do{
                            if let attachInfo = try NSJSONSerialization.JSONObjectWithData(aData, options: NSJSONReadingOptions.MutableContainers) as? [String:AnyObject]
                            {
                                if !attachInfo.isEmpty
                                {
                                    if let arrayOfDictionaries = attachInfo["GetElementAttachesResult"] as? [[String:AnyObject]]
                                    {
                                        guard !arrayOfDictionaries.isEmpty else
                                        {
                                            completion?(nil, nil)
                                            return
                                        }
                                        
                                        var attachesArray = [AttachFile]()
                                        for aDict in arrayOfDictionaries
                                        {
                                            if let anAttach = ObjectsConverter.convertSingleAttachInfoToAttach(aDict), attachNameString = anAttach.fileName
                                            {
                                                if attachNameString.containsString("/")
                                                {
                                                    anAttach.fileName = attachNameString.stringByReplacingOccurrencesOfString("/", withString:"-")
                                                }
                                                // stringByReplacingOccurencesOfString("/", withString:"-")
                                                attachesArray.append(anAttach)
                                            }
                                        }
                                        
                                        if attachesArray.isEmpty
                                        {
                                            completion?(nil,nil)
                                        }
                                        else
                                        {
                                            completion?(attachesArray , nil)
                                        }
                                    }
                                }
                                else
                                {
                                    completion?(nil, NSError(domain: "com.Origami.EmptyResponse", code: -1043, userInfo: [NSLocalizedDescriptionKey:"Recieved empty attaches Info for elementId:\(elementId)"]))
                                }
                            }
                        }
                        catch let jsonError as NSError {
                            completion?(nil, jsonError)
                        }
                        catch{
                            completion?(nil, unKnownExceptionError)
                        }
                    }
                    else
                    {
                        completion?(nil, NSError(domain: "com.Origami.NoResponseData", code: -1044, userInfo: [NSLocalizedDescriptionKey:"an Empty Server Response."]))
                    }

                })
                
                return
            }
       
            completion?(nil, ServerRequester.urlCreatingError)
            return
            
        }
        
        completion?(nil, noUserTokenError)

    }
    
    func loadDataForAttach(attachId:Int, completion:((attachFileData:NSData?, error:NSError?)->())? ) throws -> NSURLSessionDataTask
    {
        guard let userToken = DataSource.sharedInstance.user?.token else
        {
            completion?(attachFileData: nil, error: noUserTokenError)
            throw noUserTokenError
        }
        
        let requestString = serverURL + getAttachFileUrlPart + "?fileId=" + "\(attachId)" + "&token=" + userToken
        
        guard let requestURL = NSURL(string: requestString) else
        {
            throw OrigamiError.PreconditionFailure(message: "Could not create URL from resuested string.")
        }
            
        let fileDataRequest = NSMutableURLRequest(URL: requestURL)
        fileDataRequest.HTTPMethod = "GET"
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        let fileTask = self.urlSession.dataTaskWithRequest(fileDataRequest, completionHandler: { (responseData:NSData?, urlResponse:NSURLResponse?, responseError:NSError?) -> Void
            
            in
            
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            
            guard let _ = DataSource.sharedInstance.pendingAttachFileDataDownloads[attachId]
            else
            {
                completion?(attachFileData: nil, error: NSError(domain: "", code: -3021, userInfo: [NSLocalizedDescriptionKey:"Attach download operation was cancelled"]))
                return
            }
            
            if let anError = responseError
            {
                completion?(attachFileData: nil, error: anError)
            }
            else if let synchroData = responseData
            {
                if synchroData.length > 0
                {
                   
                    
                    do{
                        if let responseDict = try NSJSONSerialization.JSONObjectWithData(synchroData, options: NSJSONReadingOptions.AllowFragments ) as? [String:AnyObject]
                        {
                            guard let _ = responseDict["GetAttachedFileResult"] else
                            {
                                completion?(attachFileData: nil, error: NSError(domain: "", code: -2003, userInfo: [NSLocalizedDescriptionKey:"Attach Data Not Found"]))
                                return
                            }
                            
                            if let arrayOfIntegers = responseDict["GetAttachedFileResult"] as? [Int]
                            {
                                if arrayOfIntegers.isEmpty
                                {
                                    print("Empty response for Attach File id = \(attachId)")
                                    completion?(attachFileData: nil, error: nil)
                                }
                                else
                                {
                                    if let lvData = NSData.dataFromIntegersArray(arrayOfIntegers)
                                    {
                                        completion?(attachFileData: lvData, error: nil)
                                        print("Fullsize image data for attach: \(lvData.length) bytes")
                                    }
                                    else
                                    {
                                        //error
                                        print("ERROR: Could not convert response to NSData object")
                                        let convertingError = NSError(domain: "File loading failure", code: -1003, userInfo: [NSLocalizedDescriptionKey:"Failed to convert response."])
                                        completion?(attachFileData: nil, error: convertingError)
                                    }
                                }
                            }
                            else
                            {
                                //error
                                print("ERROR: Could not convert to array of integers object.")
                                
                              
                                let arrayConvertingError = NSError(domain: "File loading failure", code: -1004, userInfo: [NSLocalizedDescriptionKey:"Failed to read response."])
                                completion?(attachFileData: nil, error: arrayConvertingError)
                              
                            }
                        }
                    }
                    catch let jsonError as NSError
                    {
                        if let complete = completion
                        {
                            complete(attachFileData: nil, error: jsonError)
                        }
                    }
                    catch{
                        if let complete = completion
                        {
                            complete(attachFileData: nil, error: unKnownExceptionError)
                        }
                        
                    }
                    

                }
            }
            else
            {
                print("No response data..")
                completion?(attachFileData: NSData(), error: nil)
            }
            
        })
            
        return fileTask
        
    }
        //attach file to element
    func attachFile(file:MediaFile, toElement elementId:NSNumber, completion completionClosure:((success:Bool, attachId:Int?, error:ErrorType?)->())? )
    {
        guard let userToken = DataSource.sharedInstance.user?.token else
        {
            completionClosure?(success: false,  attachId:nil, error: noUserTokenError)
            return
        }
        
        let postURLstring = "\(serverURL)" + attachToElementUrlPart + "?elementId=" + "\(elementId)" + "&fileName=" + "\(file.name)" + "&token=" + "\(userToken)"
        
        guard let postURL = NSURL(string: postURLstring) else
        {
            completionClosure?(success: false, attachId: nil, error: OrigamiError.PreconditionFailure(message: "Could not create url for attach uploading request"))
            return
        }
        
        let attachedFileDataLength = file.data.length
        print("\n -> attaching \"\(attachedFileDataLength)\" bytes...")
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        let mutableRequest = NSMutableURLRequest(URL: postURL)
        mutableRequest.HTTPMethod = "POST"
        mutableRequest.HTTPBody = file.data
        
        
        let config = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        config.HTTPMaximumConnectionsPerHost = 1
        
        let session = NSURLSession(configuration: config, delegate: self, delegateQueue: nil)

        
        let dataTask = session.dataTaskWithRequest(mutableRequest, completionHandler: { (responseData:NSData?, response:NSURLResponse?, responseError:NSError?) -> Void in
            
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            
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
            
            do
            {
                if let responseDict = try NSJSONSerialization.JSONObjectWithData(data, options: optionReading) as? [String:AnyObject] {
                    print("Success sending file to server: \n \(responseDict)")
                    if let attachID = responseDict["AttachFileToElementResult"] as? Int
                    {
                        completionClosure?(success: true, attachId:attachID ,error: nil)
                    }
                    else
                    {
                        completionClosure?(success: false, attachId: nil, error: OrigamiError.NotFoundError(message: "attachId was not found after successfull file uploading"))
                    }
                }
            }
            catch let error
            {
                completionClosure?(success: false, attachId:nil , error: error)
            }
        })
        
        let bgQueue = getBackgroundQueue_DEFAULT()
        
        dispatch_async(bgQueue) { () -> Void in
            dataTask.resume()
        }
            

        
        
       
    }
        //remove attached file from element attaches
    func unAttachFile(name:String, fromElement elementId:Int, completion completionClosure:((success:Bool, error:NSError?)->())? )
    {
        
        if let userToken = DataSource.sharedInstance.user?.token// as? String
        {
            print("\n -> unattaching from elementId: \(elementId)\n")
            let requestString = "\(serverURL)" + unAttachFileUrlPart + "?elementId=" + "\(elementId)" + "&fileName=" + "\(name)" + "&token=" + "\(userToken)"
            print("uAttach Request String: \(requestString)")
            let requestOperation = httpManager.GET(requestString,
                parameters: nil,
                success: { (operation, result) -> Void in
                    if let response = result["RemoveFileFromElementResult"] as? [NSObject:AnyObject]
                    {
                        print("\n --- Successfully unattached file from element: \(response)")
                    }
                    print(result)
                   
                    completionClosure?(success: true, error: nil)
            },
                failure: { (operation, error) -> Void in
                 completionClosure?(success: false, error: error)
            })
            
            requestOperation?.resume()
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
            var bgQueue:dispatch_queue_t?
            if #available (iOS 8.0,*)
            {
                bgQueue = dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)
            }
            else
            {
                bgQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
            }
            
            let completionClosure:sessionRequestCompletion = { (responseData, urlResponse, responseError) -> () in
                if let anError = responseError
                {
                    print("\(anError)")
                    completion?(avatarData: nil, error: anError)
                    return
                }
                
                
                if let responseBytes = responseData
                {
                    do
                    {
                        if let jsonObject = try NSJSONSerialization.JSONObjectWithData(responseBytes, options: NSJSONReadingOptions.MutableContainers) as? [String:AnyObject]
                        {
                            if let response = jsonObject["GetPhotoResult"] as? [Int]
                            {
                                if response.isEmpty
                                {
                                    completion?(avatarData: nil, error: nil)
                                }
                                else if let aData = NSData.dataFromIntegersArray(response)
                                {
                                    completion?(avatarData: aData, error: nil)
                                }
                                else
                                {
                                    completion?(avatarData: nil, error: nil)
                                }
                            }
                            else{
                                print("Avatar Request Response: \(jsonObject)")
                                completion?(avatarData: nil, error: nil)
                            }
                        }
                        else
                        {
                            completion?(avatarData: nil, error: nil)
                        }
                        
                    }
                    catch let error as NSError
                    {
                        completion?(avatarData: nil, error: error)
                    }
                    catch
                    {
                        completion?(avatarData: nil, error: unKnownExceptionError)
                    }
                }
            }
            
            self.performGETqueryWithURL(requestURL, onQueue: bgQueue, completion: completionClosure)
        }
        
    }
    
    func uploadUserAvatarBytes(data:NSData, completion completionBlock:((response:[NSObject:AnyObject]?, error:ErrorType?)->())? )
    {
        if data.length == 0
        {
            let error = NSError(domain: "Origami.emptyData.Error", code: -605, userInfo: [NSLocalizedDescriptionKey : "Recieved empty data to upload."])
            completionBlock?(response: nil, error: error)
            return
        }
        
        guard let userToken = DataSource.sharedInstance.user?.token else {
             completionBlock?(response: nil, error: noUserTokenError)
            return
        }
        
        let requestString = serverURL + "SetPhoto" + "?token=" + userToken
        
        guard  let url = NSURL(string: requestString) else
        {
            let error = NSError (domain: "Origami.internal", code: -606, userInfo: [NSLocalizedDescriptionKey: "Could not create URL for image uploading request"])
            completionBlock?(response: nil,error: error)
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            return
        }
    
        let mutableRequest = NSMutableURLRequest(URL: url)
        mutableRequest.HTTPMethod = "POST"
        mutableRequest.HTTPBody = data
        
        
        let bgQueue = NSOperationQueue()
        bgQueue.maxConcurrentOperationCount = 1
    
        let config = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        config.HTTPMaximumConnectionsPerHost = 1
        
        let session = NSURLSession(configuration: config, delegate: self, delegateQueue: nil)
        
        
        let imageUploadTask = session.uploadTaskWithRequest(mutableRequest, fromData: data) { (responseData, urlResponse, responseError) -> Void in
            
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
                        if let anErrorString = String(data: respData, encoding: NSUTF8StringEncoding)
                        {
                            completionBlock?(response: nil, error: OrigamiError.NotFoundError(message: anErrorString) as NSError)
                            return
                        }
                        let errorReading = NSError(domain: "com.Origami.jsonCasting.Error", code: -5432, userInfo: [NSLocalizedDescriptionKey: "Failed to parse \"uploadUserAvatarBytes\" response"])
                        completionBlock?(response: nil, error: errorReading)
                    }
                }
                catch let error as NSError
                {
                    completionBlock?(response: nil, error: error)
                }
                catch
                {
                    completionBlock?(response: nil, error: unKnownExceptionError)
                }
                
            }
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
       
        imageUploadTask.taskDescription = "uploadImageFor: current user"
        
        
        bgQueue.addOperationWithBlock({ () -> Void in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            imageUploadTask.resume()
        })
    }
    
    //MARK: Contacts
    
    /** 
    
    Queries server for contacts and  on completion or timeout returns  array of contacts or error
    
        - Precondition: No Parameters. The function detects all that it needs from DataSource
        - parameter completion: A caller may specify wether it wants or not to recieve data on completion - an optional var for contacts array and optional var for error handling
        - returns: Void
    */
    func downloadMyContacts(completion completionClosure:((contacts:[Contact]?, error:NSError?) -> () )? = nil )
    {
        guard let userToken = DataSource.sharedInstance.user?.token else
        {
            completionClosure?(contacts: nil, error: noUserTokenError)
            return
        }
        
        let requestString = /*serverURL +*/ myContactsURLPart + "?token=" + userToken
            
            let contactsRequestOp = httpManager.GET(requestString,
                parameters: nil,
                success: { (operation, result) -> Void in
                    
                NSOperationQueue().addOperationWithBlock({ _ in
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
                    completion(contacts:nil, error:requestError)
                }
            })
            
            contactsRequestOp?.resume()
        
    }
    
    func passElement(elementId:NSNumber, toContact contactId:NSNumber, forDeletion delete:Bool, completion completionClosure:(success:Bool, error: NSError?) -> ())
    {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        let elementIdInteger = (delete) ? elementId.integerValue * -1 : elementId.integerValue
        let rightElementId = NSNumber(integer: elementIdInteger)
        
        if let userToken = DataSource.sharedInstance.user?.token //as? String
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
                 
                dispatch_async(getBackgroundQueue_SERIAL()) {
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    if let resultDict = result as? [String:AnyObject]
                    {
                        print("\n ->passElement Response from server: \(resultDict)")
                        completionClosure(success: true, error: nil)
                        return
                    }
                    let parsingError = NSError(domain: "Request reading error", code: -503, userInfo: [NSLocalizedDescriptionKey:"Failed to parse response from server."])
                    completionClosure(success: false, error: parsingError)
                }
            
            },
                failure: { (operation, requestError) -> Void in

                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    completionClosure(success: false, error: requestError)
            })
            
            requestOp?.resume()
            return
        }
        
        completionClosure(success: false, error: noUserTokenError)
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    
    
    
    func passElement(elementId : Int, toSeveratContacts contactIDs:Set<Int>, completion completionClosure:((succeededIDs:[Int], failedIDs:[Int])->())?)
    {
        guard let token = DataSource.sharedInstance.user?.token //as? String
            else
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
                
                
                let dataTask = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: {[weak self](responseData, urlResponse, responseError) -> Void in
                    
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
                    
                    
                    print(" -> completed requests count = \(completedRequestsCount)")
                    print(" -> for ContactIDs count     = \(contactIDsCount)")
                    
                    if let weakSelf = self, let _ = weakSelf.datatasksForPassElementRequest[elementId]
                    {
                        weakSelf.datatasksForPassElementRequest[elementId] = nil
                        
                        if weakSelf.datatasksForPassElementRequest.isEmpty
                        {
                            weakSelf.performPassElementsCompletionClosure(completionClosure, withInfo: (failed: failedIDs, succeeded: succededIDs))
                        }
                    }

                })
                
                self.datatasksForPassElementRequest[elementId] = dataTask

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
    
    private func performPassElementsCompletionClosure(closure:((succeededIDs:[Int], failedIDs:[Int])->())?, withInfo info:(failed:[Int], succeeded:[Int]))
    {
        closure?(succeededIDs: info.succeeded, failedIDs: info.failed)
    }
    
    func unPassElement(elementId :Int, fromSeveralContacts contactIDs:Set<Int>, completion completionClosure:((succeededIDs:[Int], failedIDs:[Int])->())?)
    {
        self.passElement((elementId * -1), toSeveratContacts: contactIDs, completion: completionClosure)
    }
    
//    /**
//     - Returns: NSURLSessionDataTask object to be called at some point later , which also can be cancelled.
//     - Throws:
//        - if no user token found
//        - if could not create a NSURL object for request
//     */
//    func loadAllContacts(completion:((contacts:[Contact]?, error:NSError?)->())?) throws -> NSURLSessionDataTask
//    {
//        print("ServerRequester -> loadAllContacts...\n")
//        
//        guard let userToken = DataSource.sharedInstance.user?.token else
//        {
//            throw OrigamiError.PreconditionFailure(message: "No User Token.")
//        }
//        
//        let requestString = serverURL + allContactsURLPart + "?token=" + userToken
//        
//        guard let requestURL = NSURL(string: requestString) else
//        {
//            throw OrigamiError.PreconditionFailure(message: "Could not create URL for rquest")
//        }
//        
//        let allContactsRequestTask = NSURLSession.sharedSession().dataTaskWithURL(requestURL) { (responseData, urlResponse, responseError) -> Void in
//            if let error = responseError
//            {
//                completion?(contacts: nil, error: error)
//                return
//            }
//            
//            guard let rawData = responseData where rawData.length > 0 else
//            {
//                completion?(contacts: nil, error: OrigamiError.NotFoundError(message: "Recieved no response data.") as NSError)
//                return
//            }
//            
//            do
//            {
//                if let response = try NSJSONSerialization.JSONObjectWithData(rawData, options: .MutableContainers) as? [String:[[String:AnyObject]]]
//                {
//                    if let contactInfosArray = response["GetAllContactsResult"]
//                    {
//                        let convertedContactObjects = ObjectsConverter.convertToContacts(contactInfosArray)
//                        completion?(contacts: convertedContactObjects, error: nil)
//                        return
//                    }
//                   
//                    completion?(contacts: nil, error: OrigamiError.NotFoundError(message: " ") as NSError)
//                    return
//                }
//                print(" Some Shit happened")
//                
//            }
//            catch let errorJSON
//            {
//                completion?(contacts: nil, error: errorJSON as NSError)
//            }
//        }
//        
//        // task will not start until called somewhere in outer object
//        return allContactsRequestTask
//        
//    }

    
    func toggleContactFavourite(contactId:Int, completion:((success:Bool, error:NSError?)->())?)
    {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        if let userToken = DataSource.sharedInstance.user?.token //as? String
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
            
            favOperation?.resume()
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
        if let userToken = DataSource.sharedInstance.user?.token //as? String
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
            
            removeContactOperation?.resume()
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
        if let userToken = DataSource.sharedInstance.user?.token //as? String
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
            
            addContactOperation?.resume()
            return
        }
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        if let completionBlock = completion
        {
            completionBlock(success: false, error: noUserTokenError)
        }
    }
    
    /**
     Used to query for new user in ContactSearchVC
     */
    func searchForNewContactByEmail(email:String, completion:((userInfo:[String:AnyObject]?, error:ErrorType?)->())?)
    {
        let requestString = serverURL + searchContactURLPart + "?userName=" + email + "&getPhoto=" + "false"
        
        guard let requestURL = NSURL(string: requestString) else
        {
            completion?(userInfo: nil, error: OrigamiError.PreconditionFailure(message: "Could Not Create URL for request."))
            
            return
        }
        
        let urlRequest = NSMutableURLRequest(URL: requestURL)
        
        
        let userRequestTask = NSURLSession.sharedSession().dataTaskWithRequest(urlRequest) { (responseData, urlResponse, responseError) -> Void in
            
            if let error = responseError
            {
                completion?(userInfo: nil, error: error)
                return
            }
            
            if let data = responseData where data.length > 0
            {
                do
                {
                    if let responseInfo = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as? [String:[String:AnyObject]], userInfo = responseInfo["GetUserInfoResult"]
                    {
                        completion?(userInfo: userInfo, error: nil)
                    }
                    else
                    {
                        completion?(userInfo: nil, error: OrigamiError.NotFoundError(message: "Recieved Empty Search Result."))
                    }
                }
                catch let errorJSON
                {
                    completion?(userInfo: nil, error: errorJSON)
                }
            }
            else
            {
                completion?(userInfo: nil, error: OrigamiError.NotFoundError(message: "Recieved No Data from Request."))
            }
        }
        
        
        userRequestTask.resume()
        
//        NSString *requestUrlString = [NSString stringWithFormat:@"%@GetUserInfo", BasicURL];
//        
//        NSDictionary *parameters = @{@"userName":email, @"getPhoto":@"false"};
//        
//        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
//        //[manager.requestSerializer setTimeoutInterval:15];
//        
//        AFHTTPRequestOperation *requestOp = [manager GET:requestUrlString
//            parameters:parameters
//            success:^(AFHTTPRequestOperation *operation, id responseObject)
//            {
//            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
//            
//            [[[NSOperationQueue alloc] init] addOperationWithBlock:^
//            {
//            NSDictionary *response = (NSDictionary *)responseObject;
//            NSDictionary *userDict = [response objectForKey:@"GetUserInfoResult"];
//            //NSLog(@"\n --searchForContactByEmail--Success response:\n- %@",response);
//            if (completionBlock)
//            {
//            completionBlock((userDict)?userDict:@{},nil);
//            }
//            }];
//            
//            
//            
//            
//            }
//            failure:^(AFHTTPRequestOperation *operation, NSError *error)
//            {
//            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
//            //NSLog(@"\n --searchForContactByEmail Error: \n-%@", error);
//            if (completionBlock)
//            {
//            completionBlock(nil,error);
//            }
//            
//            NSString *responseString = operation.responseString;
//            if (responseString)
//            {
//            //NSLog(@"Failure response while searching contact by email: \r \n%@",responseString);
//            }
//            }];
//        
//        [requestOp start];

    }
    
    //MARK: - NSURLSession
    
    func performGETqueryWithURL(url:NSURL, onQueue:dispatch_queue_t?, priority:Float = 0.5, completion:sessionRequestCompletion)
    {
        let request = NSMutableURLRequest(URL: url)
        request.setValue("application-json", forHTTPHeaderField: "Accept")
        request.HTTPMethod = "GET"
        
        if let targetRequestQueue = onQueue
        {
            self.performRequest(request, onQueue: targetRequestQueue, priority: priority, completion: completion)
            return
        }
        self.performRequest(request, onQueue: getBackgroundQueue_DEFAULT(), priority: priority, completion: completion)
    }
    
    /**
    Single function to call which performs POST requests to network, optionaly can send data
        - e.g. images, other file types data
    - Parameter url: a NSURL object with url, containing additional parameters
    - Parameter bodyData: optional if you want to send any data to server
    - Parameter priority: target priority for datatask request . Default value is 0.5 (as Apple`s documentation says)
    - NOTE: priority value should be between 0.0 and 1.0, otherwise the default priority is used
    - Parameter onQueue: optional dispatch_queue_t object , on which the dataTask will be called to execute
    - Parameter completion: an optional closure to set the dataTask`s completionHandler
    
    */
    private func performPOSTqueryWithURL(url:NSURL, bodyData:NSData?, onQueue:dispatch_queue_t?, priority:Float = 0.5, completion:sessionRequestCompletion?)
    {
        let request = NSMutableURLRequest(URL: url)
        request.setValue("application-json", forHTTPHeaderField: "Accept")
        request.HTTPMethod = "POST"
        
        if let dataToSend = bodyData
        {
            request.HTTPBody = dataToSend
        }
        
        if let targetRequestQueue = onQueue
        {
            self.performRequest(request, onQueue: targetRequestQueue, priority: priority, completion: completion)
            return
        }
        
        self.performRequest(request, onQueue: getBackgroundQueue_DEFAULT(), completion: completion)
    }
    
    private func performRequest(urlRequest:NSURLRequest, onQueue:dispatch_queue_t, priority:Float = 0.5, completion:sessionRequestCompletion?)
    {
        if let completionBlock = completion
        {
            let dataTask = self.urlSession.dataTaskWithRequest(urlRequest, completionHandler: completionBlock)
            if #available(iOS 8.0, *)
            {
                if priority >= 0 && priority <= 1.0
                {
                    dataTask.priority = priority
                }
            }
            dispatch_async(onQueue) { _ in
                dataTask.resume()
            }
        }
        else
        {
            let dataTask = NSURLSession.sharedSession().dataTaskWithRequest(urlRequest)
            if #available(iOS 8.0, *)
            {
                if priority >= 0 && priority <= 1.0
                {
                    dataTask.priority = priority
                }
            }
            dispatch_async(onQueue) { _ in
                    dataTask.resume()
            }
        }
    }
    
    //MARK: DELEGATE
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        if let description = task.taskDescription{
            if description == "uploadImageFor: current user" {
                if totalBytesSent > 0 {
                    let progress = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
                
                    print("progress: \(progress * 100) /%")
                }
            }
        }
        else
        {
            if totalBytesSent > 0 {
                let progress = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
                
                print("progress: \(progress * 100) /%")
            }
        }
    }
    
    
    func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?)
    {
        print( "Session error: \n \(error)")
    }
    
    func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {

        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust
        {
            print(" Handling  URLSession didRecieveChallenge ....")
            let credential = NSURLCredential(forTrust: challenge.protectionSpace.serverTrust!)
            completionHandler(NSURLSessionAuthChallengeDisposition.UseCredential, credential);
            
        }
        else
        {
            
        }
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        
    }
    
}



//JSON Parsing
//func parseJSON<T where T:CustomDebugStringConvertible>(jsonObjectData:NSData, asObject: T, jsonReadingOptions:NSJSONReadingOptions, completion:(([String:AnyObject]?, NSError?) ->()))
//{
//    do{
//        var targetType = asObject.dynamicType
//       
//        
//        if let result = try NSJSONSerialization.JSONObjectWithData(jsonObjectData, options: jsonReadingOptions) as? targetType
//        {
//            completion(result, nil)
//        }
//    }
//    catch let jsonParsingError as NSError {
//        completion(nil, jsonParsingError)
//    }
//    catch{
//        completion(nil, unKnownExceptionError)
//    }
//}
