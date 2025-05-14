//
//  WCConnectionRequestModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk
import ReownWalletKit

struct WCConnectionRequestModel {
    let userWalletModelId: String
    let selectedNetworks: [BlockchainSdk.Blockchain]
    let availableToSelectNetworks: [BlockchainSdk.Blockchain]
    let notAddedNetworks: [BlockchainSdk.Blockchain]
    let sessionNamespaces: [String: SessionNamespace]
    let connect: () async throws -> Void
    let cancel: () -> Void
}

extension WCConnectionRequestModel {
    init(
        userWalletModelId: String,
        requestData: [WCConnectionRequestData],
        sessionNamespaces: [String: SessionNamespace],
        connect: @escaping () async throws -> Void,
        cancel: @escaping () -> Void
    ) {
        self.userWalletModelId = userWalletModelId
        selectedNetworks = requestData.compactMap(\.selectedBlockchain).compactMap { WCUtils.makeBlockchain(from: $0) }
        availableToSelectNetworks = requestData.compactMap(\.availableToSelectBlockchain).compactMap { WCUtils.makeBlockchain(from: $0) }
        notAddedNetworks = requestData.compactMap(\.notAddedBlockchain).compactMap { WCUtils.makeBlockchain(from: $0) }
        self.sessionNamespaces = sessionNamespaces
        self.connect = connect
        self.cancel = cancel
    }
}
