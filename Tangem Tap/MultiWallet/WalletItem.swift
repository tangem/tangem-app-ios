//
//  WalletItem.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemSdk

struct WalletItemModel: Identifiable {
    var id = UUID()
    let hasTransactionInProgress: Bool
    let isLoading: Bool
    let loadingError: String?
    let name: String
    let fiatBalance: String
    let balance: String
    let rate: String
    var amountType: Amount.AmountType = .coin
    let blockchain: Blockchain

    static let `default` = WalletItemModel(id: UUID(), hasTransactionInProgress: false, isLoading: false, loadingError: nil, name: "", fiatBalance: "", balance: "", rate: "", amountType: .coin, blockchain: .bitcoin(testnet: false))
}

extension WalletItemModel {
    init(from balanceViewModel: BalanceViewModel, rate: String, blockchain: Blockchain) {
        hasTransactionInProgress = balanceViewModel.hasTransactionInProgress
        isLoading = balanceViewModel.isLoading
        loadingError = balanceViewModel.loadingError
        name = balanceViewModel.name
        balance = balanceViewModel.balance
        fiatBalance = balanceViewModel.fiatBalance
        self.rate = rate
        self.blockchain = blockchain
        self.amountType = .coin
    }
    
    init(from balanceViewModel: BalanceViewModel,
         tokenBalanceViewModel: TokenBalanceViewModel,
         rate: String,
         blockchain: Blockchain) {
        hasTransactionInProgress = balanceViewModel.hasTransactionInProgress
        isLoading = balanceViewModel.isLoading
        loadingError = balanceViewModel.loadingError
        name = tokenBalanceViewModel.name
        balance = tokenBalanceViewModel.balance
        fiatBalance = tokenBalanceViewModel.fiatBalance
        self.rate = rate
        self.blockchain = blockchain
        self.amountType = .token(value: tokenBalanceViewModel.token)
    }
}

enum WalletItem: Codable, Hashable {
    case blockchain(Blockchain)
    case token(Token)
    
    var blockchain: Blockchain? {
        if case let .blockchain(blockchain) = self {
            return blockchain
        }
        return nil
    }
    
    var token: Token? {
        if case let .token(token) = self {
            return token
        }
        return nil
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let blockchain = try? container.decode(Blockchain.self) {
            self = .blockchain(blockchain)
        } else if let token = try? container.decode(Token.self) {
            self = .token(token)
        } else {
            throw TangemSdkError.decodingFailed
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .blockchain(let blockhain):
            try container.encode(blockhain)
        case .token(let token):
            try container.encode(token)
        }
    }
}
