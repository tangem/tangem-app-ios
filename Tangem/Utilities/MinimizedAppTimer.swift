//
//  MinimizedAppTimer.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import UIKit

class MinimizedAppTimer {
    var elapsed: Bool {
        guard let lastTimeEnteredBackground else {
            return false
        }

        return Date().timeIntervalSince(lastTimeEnteredBackground) >= interval
    }

    private let interval: TimeInterval
    private var lastTimeEnteredBackground: Date?

    init(interval: TimeInterval) {
        self.interval = interval
    }

    func start() {
        lastTimeEnteredBackground = Date()
    }

    func stop() {
        lastTimeEnteredBackground = nil
    }
}
