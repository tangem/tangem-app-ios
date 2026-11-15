//
//  SellCryptoUtility.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

struct SellCryptoUtility {
    @Injected(\.sellService) private var sellService: SellService

    private let blockchain: Blockchain
    private let address: String
    private let amountType: Amount.AmountType
    private let userWalletId: UserWalletId

    init(tokenItem: TokenItem, address: String, userWalletId: UserWalletId) {
        self.init(blockchain: tokenItem.blockchain, address: address, amountType: tokenItem.amountType, userWalletId: userWalletId)
    }

    init(blockchain: Blockchain, address: String, amountType: Amount.AmountType, userWalletId: UserWalletId) {
        self.blockchain = blockchain
        self.address = address
        self.amountType = amountType
        self.userWalletId = userWalletId
    }

    var sellAvailable: Bool {
        switch amountType {
        case .coin:
            return sellService.canSell(blockchain.currencySymbol, amountType: amountType, blockchain: blockchain)
        case .token(let token):
            return sellService.canSell(token.symbol, amountType: amountType, blockchain: blockchain)
        case .reserve, .feeResource:
            return false
        }
    }

    var sellURL: URL? {
        switch amountType {
        case .coin:
            return sellService.getSellUrl(
                currencySymbol: blockchain.currencySymbol,
                amountType: amountType,
                blockchain: blockchain,
                walletAddress: address,
                userWalletId: userWalletId
            )
        case .token(let token):
            return sellService.getSellUrl(
                currencySymbol: token.symbol,
                amountType: amountType,
                blockchain: blockchain,
                walletAddress: address,
                userWalletId: userWalletId
            )
        case .reserve, .feeResource:
            return nil
        }
    }

    func extractSellCryptoRequest(from data: String) -> SellCryptoRequest? {
        sellService.extractSellCryptoRequest(from: data, amountType: amountType, blockchain: blockchain, userWalletId: userWalletId)
    }
}
