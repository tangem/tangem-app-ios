//
//  CollectiblesBuybackSentReporter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol CollectiblesBuybackSentReporter {
    func report(buybackID: String, txHash: String) async throws
}
