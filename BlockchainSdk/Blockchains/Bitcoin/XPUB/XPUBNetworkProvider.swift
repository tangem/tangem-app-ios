//
//  XPUBNetworkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct XPUBStateChecker {
    let xpub: String
    let networkProvider: XPUBNetworkProvider
}

protocol XPUBNetworkProvider {
    func getInfo(xpub: String) async throws -> XPUBInfo
}
