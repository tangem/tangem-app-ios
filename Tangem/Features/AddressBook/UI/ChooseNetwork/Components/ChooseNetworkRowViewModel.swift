//
//  ChooseNetworkRowViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

struct ChooseNetworkRowViewModel: Identifiable {
    let blockchain: BSDKBlockchain
    let isSelected: Bool
    let onTap: () -> Void

    var id: String { blockchain.networkId }
}
