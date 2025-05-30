//
//  WCNetworkSelectorInput.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct WCNetworkSelectorInput {
    let blockchains: [WCSelectedBlockchainItem]
    let requiredBlockchainNames: [String]
    let onSelectCompete: ([BlockchainNetwork]) -> Void
    let backAction: () -> Void
}

extension WCNetworkSelectorInput: Equatable {
    static func == (lhs: WCNetworkSelectorInput, rhs: WCNetworkSelectorInput) -> Bool {
        lhs.blockchains == rhs.blockchains
    }
}
