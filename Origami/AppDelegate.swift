
//
//  AppDelegate.swift
//  Origami
//
//  Created by CloudCraft on 02.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate
{

    var window: UIWindow?
    
    var rootViewController:UIViewController = UIViewController()
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        UINavigationBar.appearance().setTitleVerticalPositionAdjustment(2.0, forBarMetrics: UIBarMetrics.LandscapePhone)
        //let _ = ObjectsConverter()
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
       
    }

    func applicationDidEnterBackground(application: UIApplication) {
        DataSource.sharedInstance.localDatadaseHandler?.savePrivateContext({ (error) -> () in
            guard let errorSaving = error else
            {
                print(" applicationDidEnterBackground -> privateCOntext saving  OK")
                return
            }
            print(" applicationDidEnterBackground -> privateCOntext saving error: \n \(errorSaving)")
        })
    
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        DataSource.sharedInstance.localDatadaseHandler?.savePrivateContext({ (error) -> () in
            guard let errorSaving = error else
            {
                print(" applicationDidEnterBackground -> privateCOntext saving  OK")
                return
            }
            print(" applicationDidEnterBackground -> privateCOntext saving error: \n \(errorSaving)")
        })
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
         let string = deviceToken.description
        
        print(" -> recieved device token for PUSHes:\n \(string)")
    }
    
    @available(iOS 8.0, *)
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        application.registerForRemoteNotifications()
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print(" -> Failed to register fot PUSHes : \n\(error)")
    }    
}

