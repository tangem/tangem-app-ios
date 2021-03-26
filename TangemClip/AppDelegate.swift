//
//  AppDelegate.swift
//  TangemClip
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import UIKit
import TangemSdkClips

let clipsLogger = ClipsLogger()

class ClipsLogger {
    @Published var logs = ""
    
    var counter = 0
    func log(_ message: String) {
        counter += 1
        logs.append("\n\(counter). \(message)")
    }
}

class Logger: TangemSdkLogger {
    private let fileManager = FileManager.default
    
    var scanLogFileData: Data? {
        try? Data(contentsOf: scanLogsFileUrl)
    }
    
    private var scanLogsFileUrl: URL {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("scanLogs.txt")
    }
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss:SSS"
        return formatter
    }()
    
    private var isRecordingLogs: Bool = false
    
    init() {
        try? fileManager.removeItem(at: scanLogsFileUrl)
    }
    
    func log(_ message: String, level: Log.Level) {
        let formattedMessage = "\(self.dateFormatter.string(from: Date())): \(message)\n"
        let messageData = formattedMessage.data(using: .utf8)!
        if let handler = try? FileHandle(forWritingTo: scanLogsFileUrl) {
            handler.seekToEndOfFile()
            handler.write(messageData)
            handler.closeFile()
        } else {
            try? messageData.write(to: scanLogsFileUrl)
        }
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        clipsLogger.log("did finish launching with options: \(launchOptions)")
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        clipsLogger.log("Configuration for connecting session: \(options.urlContexts)")
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        clipsLogger.log("Open url: \(url) with options: \(options)")
        return true
    }
    
    func application(_ application: UIApplication, didUpdate userActivity: NSUserActivity) {
        clipsLogger.log("Application did update user activity with type: \(userActivity.activityType)")
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

