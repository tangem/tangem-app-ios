//
//  BackgroundTaskWrapper.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import OSLog
import UIKit

/// Lightweight wrapper for the RAII-like lifetime management of iOS background tasks created
/// using `UIApplication.beginBackgroundTask(withName:expirationHandler:)` system API.
/// Based on https://developer.apple.com/forums/thread/729335
public final class BackgroundTaskWrapper {
    public typealias ExpirationHandler = () -> Void

    /// TangemFoundation sits below TangemLogger, so lifecycle messages go straight to the unified log.
    private static let logger = os.Logger(subsystem: "com.tangem.os.logger", category: "BackgroundTask")

    private let taskName: String
    private var expirationHandler: ExpirationHandler?
    private var taskIdentifier: UIBackgroundTaskIdentifier
    private let criticalSection = OSAllocatedUnfairLock()

    public init(
        taskName: String = BackgroundTaskWrapper.makeTaskName(),
        expirationHandler: ExpirationHandler? = nil
    ) {
        self.taskName = taskName
        self.expirationHandler = expirationHandler
        taskIdentifier = .invalid
        start()
    }

    deinit {
        finish(isExpired: false)
    }

    public func finish() {
        finish(isExpired: false)
    }

    private func start() {
        let taskName = taskName
        taskIdentifier = UIApplication.shared.beginBackgroundTask(withName: taskName) { [weak self] in
            self?.finish(isExpired: true)
        }
        Self.logger.info("Background task '\(taskName, privacy: .public)' started")
    }

    private func finish(isExpired: Bool) {
        let taskName = taskName

        criticalSection {
            guard taskIdentifier != .invalid else {
                return
            }

            UIApplication.shared.endBackgroundTask(taskIdentifier)
            taskIdentifier = .invalid

            if isExpired {
                expirationHandler?()
            }

            expirationHandler = nil

            if isExpired {
                Self.logger.warning("Background task '\(taskName, privacy: .public)' has expired")
            } else {
                Self.logger.info("Background task '\(taskName, privacy: .public)' finished normally")
            }
        }
    }
}

// MARK: - Convenience extensions

public extension BackgroundTaskWrapper {
    static func makeTaskName() -> String {
        return String(describing: type(of: self)) + "_" + UUID().uuidString
    }
}
