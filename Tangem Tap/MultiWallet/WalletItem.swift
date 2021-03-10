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
import SwiftUI

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
    
    var currencySymbol: String {
        if amountType == .coin {
            return blockchain.currencySymbol
        } else if let token = amountType.token {
            return token.symbol
        }
        return ""
    }
    
    var walletItem: WalletItem {
        if case let .token(token) = amountType {
            return .token(token)
        }
        
        return .blockchain(blockchain)
    }
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
    
    @ViewBuilder var imageView: some View {
        switch self {
        case .token(let token):
            CircleImageView(name: token.name, color: token.color)
        case .blockchain(let blockchain):
            if let image = blockchain.imageName {
                Image(image)
            } else {
                CircleImageView(name: blockchain.displayName,
                                color: Color.tangemTapGrayLight4)
            }
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let blockchain = try? container.decode(Blockchain.self) {
            self = .blockchain(blockchain)
        } else if let token = try? container.decode(Token.self) {
            self = .token(token)
        } else {
            throw BlockchainSdkError.decodingFailed
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
