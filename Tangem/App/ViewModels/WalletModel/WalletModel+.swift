//
//  WalletModel+.swift
//  Tangem
//
//  Created by Andrew Son on 04/09/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemStaking

extension WalletModel: Equatable {
    static func == (lhs: WalletModel, rhs: WalletModel) -> Bool {
        lhs.id == rhs.id
    }
}

extension WalletModel {
    struct Id: Hashable, Identifiable, Equatable {
        var id: Int { hashValue }

        let blockchainNetwork: BlockchainNetwork
        let amountType: Amount.AmountType
    }
}

extension WalletModel: Identifiable {
    var id: Int {
        Id(blockchainNetwork: blockchainNetwork, amountType: amountType).id
    }
}

extension WalletModel: Hashable {
    func hash(into hasher: inout Hasher) {
        let id = Id(blockchainNetwork: blockchainNetwork, amountType: amountType)
        hasher.combine(id)
    }
}

extension WalletModel {
    enum TransactionHistoryState: CustomStringConvertible {
        case notSupported
        case notLoaded
        case loading
        case loaded(items: [TransactionRecord])
        case error(Error)

        var description: String {
            switch self {
            case .notSupported:
                return "TransactionHistoryState.notSupported"
            case .notLoaded:
                return "TransactionHistoryState.notLoaded"
            case .loading:
                return "TransactionHistoryState.loading"
            case .loaded(let items):
                return "TransactionHistoryState.loaded with items: \(items.count)"
            case .error(let error):
                return "TransactionHistoryState.error with \(error.localizedDescription)"
            }
        }
    }

    enum StakingState: Hashable {
        case notSupported
        case loading
        case error
        case availableToStake
        case staked(balance: StakingBalanceInfo)
    }
}

// MARK: - CustomStringConvertible protocol conformance

extension WalletModel: CustomStringConvertible {
    var description: String {
        objectDescription(
            self,
            userInfo: [
                "name": name,
                "isMainToken": isMainToken,
                "tokenItem": "\(tokenItem.name) (\(tokenItem.networkName))",
            ]
        )
    }
}
