//
//  OverlayContentContainerAppLifecycleHelper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt

protocol OverlayContentContainerAppLifecycleHelperDelegate: AnyObject {
    func currentProgress(for appLifecycleHelper: OverlayContentContainerAppLifecycleHelper) -> CGFloat
    func appLifecycleHelperDidTriggerExpand(_ appLifecycleHelper: OverlayContentContainerAppLifecycleHelper)
    func appLifecycleHelperDidTriggerCollapse(_ appLifecycleHelper: OverlayContentContainerAppLifecycleHelper)
}

final class OverlayContentContainerAppLifecycleHelper {
    weak var delegate: OverlayContentContainerAppLifecycleHelperDelegate?

    private var notificationCenter: NotificationCenter { .default }
    private var didBind = false
    private var bag: Set<AnyCancellable> = []

    func observeLifecycleIfNeeded() {
        if didBind {
            return
        }

        notificationCenter
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .withWeakCaptureOf(self)
            .sink { object, note in
                object.onDidBecomeActive()
            }
            .store(in: &bag)

        didBind = true
    }

    private func onDidBecomeActive() {
        guard let delegate else {
            return
        }

        // Prevents the overlay from getting stuck in an intermediate state if the drag gesture
        // is interrupted in the middle by sending the app to the background
        if delegate.currentProgress(for: self) >= 0.5 {
            delegate.appLifecycleHelperDidTriggerExpand(self)
        } else {
            delegate.appLifecycleHelperDidTriggerCollapse(self)
        }
    }
}
