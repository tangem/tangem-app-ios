//
//  ExpressPendingTransactionRecord.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

struct ExpressPendingTransactionRecord: Codable, Equatable {
    let userWalletId: String
    let expressTransactionId: String
    let transactionType: TransactionType
    let transactionHash: String
    let sourceTokenTxInfo: TokenTxInfo
    let destinationTokenTxInfo: TokenTxInfo
    let feeString: String
    let provider: Provider
    let date: Date
    let externalTxId: String?
    let externalTxURL: String?

    // Flag for hide transaction from UI. But keep saving in the storage
    var isHidden: Bool
    var transactionStatus: PendingExpressTransactionStatus

    var fee: Decimal {
        convertToDecimal(feeString)
    }
}

extension ExpressPendingTransactionRecord {
    struct TokenTxInfo: Codable, Equatable {
        let tokenItem: TokenItem
        let blockchainNetwork: BlockchainNetwork
        let amountString: String
        let isCustom: Bool

        var amount: Decimal {
            convertToDecimal(amountString)
        }
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

        init(id: String, name: String, iconURL: URL?, type: ProviderType) {
            self.id = id
            self.name = name
            self.iconURL = iconURL
            self.type = type
        }

        init(provider: ExpressProvider) {
            id = provider.id
            name = provider.name
            iconURL = provider.imageURL
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

private func convertToDecimal(_ str: String) -> Decimal {
    let cleanedStr = str.replacingOccurrences(of: ",", with: ".")
    let locale = Locale(identifier: "en-US")
    return Decimal(string: cleanedStr, locale: locale) ?? 0
}
