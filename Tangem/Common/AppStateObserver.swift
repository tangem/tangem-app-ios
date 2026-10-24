//
//  AppStateObserver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import UIKit

final class AppStateObserver {
    private let notificationCenter: NotificationCenter
    private var task: Task<Void, Never>?

    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
    }

    deinit {
        task?.cancel()
    }

    func start(onChange: @escaping @MainActor (_ isInBackground: Bool) -> Void) {
        task?.cancel()

        task = Task { @MainActor [notificationCenter] in
            await withTaskGroup(of: Void.self) { group in
                group.addTask { @MainActor in
                    for await _ in notificationCenter.notifications(named: UIApplication.didEnterBackgroundNotification) {
                        onChange(true)
                    }
                }

                group.addTask { @MainActor in
                    for await _ in notificationCenter.notifications(named: UIApplication.willEnterForegroundNotification) {
                        onChange(false)
                    }
                }
            }
        }
    }
}
