//
//  WCSelectedBlockchainItem.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI
import BlockchainSdk

struct WCSelectedBlockchainItem: Identifiable, Hashable {
    let id: UUID = .init()
    let name: String
    let tokenTypeName: String
    let currencySymbol: String
    let state: WCSelectBlockchainItemState
    let tokenIconInfo: TokenIconInfo?
    let dataSourceBlockchain: Blockchain
}

extension WCSelectedBlockchainItem {
    init(from requestBlockchain: WCRequestBlockchainItem, tokenItemMapper: TokenItemMapper?, tokenIconInfoBuilder: TokenIconInfoBuilder) {
        dataSourceBlockchain = requestBlockchain.blockchain
        name = requestBlockchain.blockchain.displayName
        tokenTypeName = requestBlockchain.blockchain.tokenTypeName ?? ""
        currencySymbol = requestBlockchain.blockchain.currencySymbol
        state = requestBlockchain.state

        guard
            let tokenItemMapper,
            let tokenItem = tokenItemMapper.mapToTokenItem(
                id: requestBlockchain.blockchain.coinId,
                name: requestBlockchain.blockchain.coinDisplayName,
                symbol: requestBlockchain.blockchain.currencySymbol,
                network: .init(
                    networkId: requestBlockchain.blockchain.networkId,
                    contractAddress: nil,
                    decimalCount: requestBlockchain.blockchain.decimalCount
                )
            )
        else {
            tokenIconInfo = nil
            return
        }

        tokenIconInfo = tokenIconInfoBuilder.build(from: tokenItem, isCustom: false)
    }
}
