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

struct WalletItemViewModel: Identifiable {
    var id = UUID()
    let state: WalletModel.State
    let hasTransactionInProgress: Bool
    let name: String
    let fiatBalance: String
    let balance: String
    let rate: String
    var amountType: Amount.AmountType = .coin
    let blockchain: Blockchain

    static let `default` = WalletItemViewModel(id: UUID(), state: .created, hasTransactionInProgress: false, name: "", fiatBalance: "", balance: "", rate: "", amountType: .coin, blockchain: .bitcoin(testnet: false))
}

extension WalletItemViewModel {
    init(from balanceViewModel: BalanceViewModel, rate: String, blockchain: Blockchain) {
        hasTransactionInProgress = balanceViewModel.hasTransactionInProgress
        state = balanceViewModel.state
        name = balanceViewModel.name
        if name == "" {
            
        }
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
        state = balanceViewModel.state
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
    case token(Token, Blockchain)
    
    var blockchain: Blockchain? {
        if case let .blockchain(blockchain) = self {
            return blockchain
        }
        return nil
    }
    
    var token: Token? {
        if case let .token(token, _) = self {
            return token
        }
        return nil
    }
    
    var tokenItem: (Blockchain, Token)? {
        if case let .token(token, blockchain) = self {
            return (blockchain, token)
        }
        return nil
    }
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        if let blockchain = try? container.decode(Blockchain.self) {
            self = .blockchain(blockchain)
        } else if let token = try? container.decode(Token.self),
                  let blockchain = try? container.decode(Blockchain.self){
            self = .token(token, blockchain)
        } else {
            throw BlockchainSdkError.decodingFailed
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        switch self {
        case .blockchain(let blockhain):
            try container.encode(blockhain)
        case .token(let token, let blockchain):
            try container.encode(token)
            try container.encode(blockchain)
        }
    }
}
