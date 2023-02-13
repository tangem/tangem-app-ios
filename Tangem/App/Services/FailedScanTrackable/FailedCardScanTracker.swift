//
//  ScanCardObserver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

class FailedCardScanTracker: EmailDataCollector, FailedScanTrackable {
    var dataForEmail: String {
        "----------\n" + DeviceInfoProvider.info()
    }

    var attachment: Data? {
        FileLogger().logData
    }

    var shouldDisplayAlert: Bool {
        numberOfFailedAttempts >= 2
    }

    private(set) var numberOfFailedAttempts: Int = 0

    func resetCounter() {
        numberOfFailedAttempts = 0
    }

    func recordFailure() {
        numberOfFailedAttempts += 1
    }
}
