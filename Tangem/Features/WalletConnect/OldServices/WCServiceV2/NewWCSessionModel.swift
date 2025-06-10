//
//  NewWCSessionModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk
import ReownWalletKit

struct WCConnectionRequestModel {
    let selectedNetworks: [BlockchainSdk.Blockchain]
    let availableToSelectNetworks: [BlockchainSdk.Blockchain]
    let notAddedNetworks: [BlockchainSdk.Blockchain]
    let sessionNamespaces: [String: SessionNamespace]
}

extension WCConnectionRequestModel {
    init(
        selectedNetworks: [WalletConnectUtils.Blockchain],
        availableToSelectNetworks: [WalletConnectUtils.Blockchain],
        notAddedNetworks: [WalletConnectUtils.Blockchain],
        sessionNamespaces: [String: SessionNamespace]
    ) {
        self.selectedNetworks = selectedNetworks.compactMap { WCUtils.makeBlockchain(from: $0) }
        self.availableToSelectNetworks = availableToSelectNetworks.compactMap { WCUtils.makeBlockchain(from: $0) }
        self.notAddedNetworks = notAddedNetworks.compactMap { WCUtils.makeBlockchain(from: $0) }
        self.sessionNamespaces = sessionNamespaces
    }
}
