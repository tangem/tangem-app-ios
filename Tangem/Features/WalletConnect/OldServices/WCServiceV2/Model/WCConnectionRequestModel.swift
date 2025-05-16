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
    let blockchains: [WCRequestBlockchainItem]
    let connect: (() async throws -> Void)?
    let cancel: (() -> Void)?
}

extension WCConnectionRequestModel {
    init(
        userWalletModelId: String,
        requestData: [WCConnectionRequestDataItem]? = nil,
        connect: (() async throws -> Void)? = nil,
        cancel: (() -> Void)? = nil
    ) {
        self.userWalletModelId = userWalletModelId
        blockchains = requestData?.compactMap {
            if let blockchain = WCUtils.makeBlockchain(from: $0.blockchainData.wcBlockchain) {
                return .init(blockchain: blockchain, state: $0.blockchainData.state)
            } else {
                return nil
            }
        } ?? []
        self.connect = connect
        self.cancel = cancel
    }
}
