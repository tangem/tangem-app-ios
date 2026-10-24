//
//  CollectiblesPurchaseSentReporter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol CollectiblesPurchaseSentReporter {
    func report(txID: String, txHash: String) async throws -> CollectiblesPurchaseStatus
}
