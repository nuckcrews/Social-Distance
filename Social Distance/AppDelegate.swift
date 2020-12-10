//
//  AppDelegate.swift
//  Social Distance
//
//  Created by Nick Crews on 4/26/20.
//  Copyright © 2020 People. Love. Change. All rights reserved.
//

import UIKit
import FirebaseMessaging
import FirebaseInstanceID
import FirebaseDatabase
import FirebaseAuth
import FirebaseDynamicLinks
import Firebase
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    static let NOTIFICATION_URL = "https://fcm.googleapis.com/fcm/send"
    static let SERVERKEY = "AAAAhTItlho:APA91bHtrMdXn2Ueui90vCe3MFveGFoaY2c7XNnjVxpA4P7sAMQxTGyHtSMX1yNM328RSQWenzbPR0x3X6cpBhN52rVKbYJFmyEZ82WowMNxN11SJB3vxVlJS7e_HOVk617QhzdEw8NS"
    static var DEVICEID = String()
    static var fcmTOKEN = String()
    let gcmMessageIDKey = "gcm.message_id"
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        application.applicationIconBadgeNumber = 0
        return true
    }

    // MARK: UISceneSession Lifecycle
    @available(iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    @available(iOS 13.0, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    // MARK: UISceneSession Lifecycle
    func connectToFCM()
    {
        Messaging.messaging().shouldEstablishDirectChannel = true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        if Auth.auth().currentUser?.uid != nil && MYUUID != nil {
            stopLive()
        }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
//        print("set timer")
//        Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(self.terminateApp), userInfo: nil, repeats: false)
    }
    
    var tim: Timer?
    func applicationWillResignActive(_ application: UIApplication) {
           //     print("set timer")
        // 600
      //  tim = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(self.terminateApp), userInfo: nil, repeats: false)
    }
    
    @objc func terminateApp() {
        let notificationCenter = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent() // Содержимое уведомления
        content.title = "Session Expired"
        content.body = "Your distance monitoring session has expired. Open to restart your session."
        content.sound = UNNotificationSound.default
        content.badge = 1
        let date = Date(timeIntervalSinceNow: 2)
        let triggerDate = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute,.second,], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let req = UNNotificationRequest(identifier: "term", content: content, trigger: trigger)
        notificationCenter.add(req) { (error) in
            if let error = error {
                print(error.localizedDescription)
            }
        }
        
        exit(-1)
        //UIControl().sendAction(#selector(NSXPCConnection.suspend),to: UIApplication.shared, for: nil)
    }
    
    
    func stopLive() {
        let ref = Database.database().reference().child("actives").child(MYUUID!.uuidString)
        ref.removeValue()
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
      // If you are receiving a notification message while your app is in the background,
      // this callback will not be fired till the user taps on the notification launching the application.
      // TODO: Handle data of notification

      // With swizzling disabled you must let Messaging know about the message, for Analytics
      // Messaging.messaging().appDidReceiveMessage(userInfo)

      // Print message ID.
      if let messageID = userInfo[gcmMessageIDKey] {
        print("Message ID: \(messageID)")
      }
        application.applicationIconBadgeNumber = 1
      // Print full message.
      print(userInfo)
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
      // If you are receiving a notification message while your app is in the background,
      // this callback will not be fired till the user taps on the notification launching the application.
      // TODO: Handle data of notification

      // With swizzling disabled you must let Messaging know about the message, for Analytics
      // Messaging.messaging().appDidReceiveMessage(userInfo)

      // Print message ID.
      if let messageID = userInfo[gcmMessageIDKey] {
        print("Message ID: \(messageID)")
      }
        
        application.applicationIconBadgeNumber = 1

      // Print full message.
      print(userInfo)

      completionHandler(UIBackgroundFetchResult.newData)
    }
    // [END receive_message]
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
      print("Unable to register for remote notifications: \(error.localizedDescription)")
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
      let handled = DynamicLinks.dynamicLinks().handleUniversalLink(userActivity.webpageURL!) { (dynamiclink, error) in
        // ...
      }

      return handled
    }
    
    @available(iOS 9.0, *)
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
      return application(app, open: url,
                         sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
                         annotation: "")
    }

    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
      if let dynamicLink = DynamicLinks.dynamicLinks().dynamicLink(fromCustomSchemeURL: url) {
        // Handle the deep link. For example, show the deep-linked content or
        // apply a promotional offer to the user's account.
        // ...
        return true
      }
      return false
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
         UIApplication.shared.applicationIconBadgeNumber = 0
        if tim != nil {
            tim?.invalidate()
        }
    }
    func applicationDidBecomeActive(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    

}

    // [START ios_10_message_handling]
@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {

      // Receive displayed notifications for iOS 10 devices.
      func userNotificationCenter(_ center: UNUserNotificationCenter,
                                  willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo

        // With swizzling disabled you must let Messaging know about the message, for Analytics
         Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("present one")
          print("Message ID: \(messageID)")
        }

        // Print full message.
        print(userInfo)

        // Change this to your preferred presentation option
        completionHandler([.alert, .badge, .sound])
      }

      func userNotificationCenter(_ center: UNUserNotificationCenter,
                                  didReceive response: UNNotificationResponse,
                                  withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("this one")
          print("Message ID: \(messageID)")
        }

        // Print full message.
        print(userInfo)

        completionHandler()
      }
    
}
    // [END ios_10_message_handling]
extension AppDelegate : MessagingDelegate {      // [START refresh_token]
      func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")
      //  AppDelegate.fcmTOKEN = fcmToken

        let dataDict:[String: String] = ["token": fcmToken]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
      }
      // [END refresh_token]
      // [START ios_10_data_message]
      // Receive data messages on iOS 10+ directly from FCM (bypassing APNs) when the app is in the foreground.
      // To enable direct data messages, you can set Messaging.messaging().shouldEstablishDirectChannel to true.
      func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("Received data message: \(remoteMessage.appData)")
      }
    
    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
        var newToken: String?
            InstanceID.instanceID().instanceID { (result, error) in
            if let error = error {
                print("Error fetching remote instange ID: \(error)")
            } else if let result = result {
                print("Remote instance ID token: \(result.token)")
                newToken = result.token
            }
        }
        if (newToken != nil) {
            AppDelegate.DEVICEID = newToken!
            connectToFCM()
            
        }
        
    }

    
      // [END ios_10_data_message]
    }





