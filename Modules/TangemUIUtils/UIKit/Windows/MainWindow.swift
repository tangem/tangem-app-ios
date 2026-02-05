//
//  MainWindow.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import UIKit

/// Type-marker used to correctly identify one and only main window of the application.
/// - Note: Used in UIApplication.topViewController property as filtering predicate.
public final class MainWindow: UIWindow {
    override public func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)

        if motion == .motionShake {
            NotificationCenter.default.post(
                name: Notification.Name.deviceDidShakeNotification,
                object: nil
            )
        }
    }
}

public extension Notification.Name {
    static let deviceDidShakeNotification = Self(rawValue: "deviceDidShakeNotification")
}
