//
//  ExpressPendingTransactionRecord.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSwapping

struct ExpressPendingTransactionRecord: Codable, Equatable {
    let userWalletId: String
    let expressTransactionId: String
    let transactionType: TransactionType
    let transactionHash: String
    let sourceTokenTxInfo: TokenTxInfo
    let destinationTokenTxInfo: TokenTxInfo
    let fee: Decimal
    let provider: Provider
    let date: Date
    let externalTxId: String?
    let externalTxURL: String?
}

extension ExpressPendingTransactionRecord {
    struct TokenTxInfo: Codable, Equatable {
        let tokenItem: TokenItem
        let blockchainNetwork: BlockchainNetwork
        let amount: Decimal
        let isCustom: Bool
    }

    enum TransactionType: String, Codable, Equatable {
        case send
        case swap

        static func type(from expressType: ExpressTransactionType) -> TransactionType {
            switch expressType {
            case .send: return .send
            case .swap: return .swap
            }
        }
    }

    struct Provider: Codable, Equatable {
        let id: String
        let name: String
        let iconURL: URL?
        let type: ProviderType

        init(provider: ExpressProvider) {
            id = provider.id.rawValue
            name = provider.name
            iconURL = provider.url
            type = .type(from: provider.type)
        }
    }

    enum ProviderType: String, Codable, Equatable {
        case cex
        case dex

        static func type(from type: ExpressProviderType) -> ProviderType {
            switch type {
            case .dex: return .dex
            case .cex: return .cex
            }
        }
    }
}
