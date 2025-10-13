//
//  CryptoAccountsWalletModelsManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation

protocol CryptoAccountsWalletModelsManager {
    var cryptoAccountModelWithWalletPublisher: AnyPublisher<[CryptoAccountsWallet], Never> { get }
}

struct CryptoAccountsWallet {
    let wallet: String
    let accounts: [CryptoAccountsWalletAccount]
}

struct CryptoAccountsWalletAccount {
    let account: any BaseAccountModel
    let walletModels: [any WalletModel]
}

extension [AccountModel] {
    var cryptoAccountModels: [any CryptoAccountModel] {
        flatMap { accountModel in
            switch accountModel {
            case .standard(.single(let cryptoAccountModel)):
                return [cryptoAccountModel]
            case .standard(.multiple(let cryptoAccountModels)):
                return cryptoAccountModels
            default:
                return []
            }
        }
    }
}
