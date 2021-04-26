//
//  SceneDelegate.swift
//  TangemClip
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import UIKit
import SwiftUI

class ClipsLogger: TangemSdkLogger {
    private let fileManager = FileManager.default
    
    var scanLogFileData: Data? {
        try? Data(contentsOf: scanLogsFileUrl)
    }
    
    var logs: String {
        let emptyLogs = "Failed to retreive logs"
        guard
            let data = scanLogFileData,
            let lgs = String(data: data, encoding: .utf8)
        else {
            return emptyLogs
        }
        
        return lgs
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

let clipsLogger = ClipsLogger()

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    let assembly = Assembly()
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        let contentView = MainView(viewModel: assembly.getMainViewModel())


        if let activity = connectionOptions.userActivities.first {
            clipsLogger.log("Scene will connect to session with activity: \(activity). Type: \(activity.activityType). Webpage url: \(activity.webpageURL)", level: .debug)
            handleActivity(activity)
            scene.userActivity = activity
        }
        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }
    
    func scene(_ scene: UIScene, willContinueUserActivityWithType userActivityType: String) {
        guard let activity = scene.userActivity else { return }
        clipsLogger.log("Scene will continue user activity: \(activity). Type: \(activity.activityType). Webpage url: \(activity.webpageURL)", level: .debug)
        handleActivity(activity)
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        handleActivity(userActivity)
        clipsLogger.log("Scene will continue user activity: \(userActivity). Type: \(userActivity.activityType). Webpage url: \(userActivity.webpageURL)", level: .debug)
        scene.userActivity = userActivity
    }
    
    private func handleActivity(_ activity: NSUserActivity) {
        // Get URL components from the incoming user activity
        guard activity.activityType == NSUserActivityTypeBrowsingWeb,
              let incomingURL = activity.webpageURL,
              incomingURL.absoluteString != "https://example.com"
        else { return }
        
        let link = incomingURL.absoluteString
        let batch = incomingURL.lastPathComponent
        assembly.updateAppClipCard(with: batch, fullLink: link)
    }

}

