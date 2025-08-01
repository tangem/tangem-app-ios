//
//  WCRequestDetailsInput.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct WCRequestDetailsInput {
    let builder: WCRequestDetailsBuilder
    let rawTransaction: String?
    let simulationResult: BlockaidChainScanResult?
    let backAction: () -> Void
}

extension WCRequestDetailsInput: Equatable {
    static func == (lhs: WCRequestDetailsInput, rhs: WCRequestDetailsInput) -> Bool {
        lhs.builder == rhs.builder
    }
}
