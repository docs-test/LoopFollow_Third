//
//  AppDelegate.swift
//  LoopFollow
//
//  Created by Jon Fawcett on 6/1/20.
//  Copyright © 2020 Jon Fawcett. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications
import EventKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let notificationCenter = UNUserNotificationCenter.current()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        LogManager.shared.log(category: .general, message: "App started")
        LogManager.shared.cleanupOldLogs()

        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        notificationCenter.requestAuthorization(options: options) {
            (didAllow, error) in
            if !didAllow {
                LogManager.shared.log(category: .general, message: "User has declined notifications")
            }
        }

        let store = EKEventStore()
        store.requestCalendarAccess { (granted, error) in
            if !granted {
                LogManager.shared.log(category: .calendar, message: "Failed to get calendar access: \(String(describing: error))")
                return
            }
        }

        let action = UNNotificationAction(identifier: "OPEN_APP_ACTION", title: "Open App", options: .foreground)
        let category = UNNotificationCategory(identifier: "loopfollow.background.alert", actions: [action], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])

        UNUserNotificationCenter.current().delegate = self

        // Ensure ViewControllerManager is initialized
        _ = ViewControllerManager.shared

        _ = BLEManager.shared

        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        if UserDefaultsRepository.alertAppInactive.value {
            AlarmSound.setSoundFile(str: "Alarm_Buzzer")
            AlarmSound.playTerminated()
        }
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // set "prevent screen lock" to ON when the app is started for the first time
        if !UserDefaultsRepository.screenlockSwitchState.exists {
            UserDefaultsRepository.screenlockSwitchState.value = true
        }

        // set the "prevent screen lock" option when the app is started
        // This method doesn't seem to be working anymore. Added to view controllers as solution offered on SO
        UIApplication.shared.isIdleTimerDisabled = UserDefaultsRepository.screenlockSwitchState.value

        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentCloudKitContainer(name: "LoopFollow")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.actionIdentifier == "OPEN_APP_ACTION" {
            if let window = window {
                window.rootViewController?.dismiss(animated: true, completion: nil)
                window.rootViewController?.present(MainViewController(), animated: true, completion: nil)
            }
        }
        completionHandler()
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        completionHandler(.alert)
    }
}
