//
//  AppDatabase+Initializable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAppDatabase

// MARK: - Initializable protocol conformance

extension AppDatabase: Initializable {
    func initialize() {
        AppDatabaseDropUtil.dropIfScheduled()

        if FeatureProvider.isAvailable(.transactionHistoryV2) {
            prepare()
        }
    }
}
