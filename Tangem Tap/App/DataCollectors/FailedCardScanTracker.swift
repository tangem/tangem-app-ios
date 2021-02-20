//
//  ScanCardObserver.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

class FailedCardScanTracker: EmailDataCollector {
    
    var logger: Logger
    
    var dataForEmail: String {
        "----------\n" + DeviceInfoProvider.info()
    }
    
    var attachment: Data? {
        logger.scanLogFileData
    }
    
    var shouldDisplayAlert: Bool {
        numberOfFailedAttempts >= 2
    }
    
    private var numberOfFailedAttempts: Int = 0
    
    init(logger: Logger) {
        self.logger = logger
    }
    
    func resetCounter() {
        numberOfFailedAttempts = 0
    }
    
    func recordFailure() {
        numberOfFailedAttempts += 1
    }
}
