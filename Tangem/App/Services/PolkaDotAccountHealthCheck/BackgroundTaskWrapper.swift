//
//  BackgroundTaskWrapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

/// Lightweight wrapper for RAII-like iOS background task lifetime management.
/// Based on https://developer.apple.com/forums/thread/729335
final class BackgroundTaskWrapper {
    typealias ExpirationHandler = () -> Void

    private let taskName: String
    private var expirationHandler: ExpirationHandler?
    private var taskIdentifier: UIBackgroundTaskIdentifier

    init(
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

    func finish() {
        finish(isExpired: false)
    }

    private func start() {
        taskIdentifier = UIApplication.shared.beginBackgroundTask(withName: taskName) { [weak self] in
            self?.finish(isExpired: true)
        }
    }

    private func finish(isExpired: Bool) {
        guard taskIdentifier != .invalid else {
            return
        }

        UIApplication.shared.endBackgroundTask(taskIdentifier)
        taskIdentifier = .invalid

        if isExpired {
            expirationHandler?()
        }

        expirationHandler = nil
    }
}

// MARK: - Convenience extensions

private extension BackgroundTaskWrapper {
    static func makeTaskName() -> String {
        return String(describing: type(of: self)) + "_" + UUID().uuidString
    }
}
