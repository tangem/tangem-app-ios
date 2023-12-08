//
//  ExpressPendingTransactionRecord+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension ExpressPendingTransactionRecord {
    enum CodingKeys: CodingKey {
        case userWalletId
        case expressTransactionId
        case transactionType
        case transactionHash
        case sourceTokenTxInfo
        case destinationTokenTxInfo
        case fee
        case provider
        case date
        case externalTxId
        case externalTxURL
    }

    init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<ExpressPendingTransactionRecord.CodingKeys> = try decoder.container(keyedBy: ExpressPendingTransactionRecord.CodingKeys.self)

        userWalletId = try container.decode(String.self, forKey: ExpressPendingTransactionRecord.CodingKeys.userWalletId)
        expressTransactionId = try container.decode(String.self, forKey: ExpressPendingTransactionRecord.CodingKeys.expressTransactionId)
        transactionType = try container.decode(ExpressPendingTransactionRecord.TransactionType.self, forKey: ExpressPendingTransactionRecord.CodingKeys.transactionType)
        transactionHash = try container.decode(String.self, forKey: ExpressPendingTransactionRecord.CodingKeys.transactionHash)
        sourceTokenTxInfo = try container.decode(ExpressPendingTransactionRecord.TokenTxInfo.self, forKey: ExpressPendingTransactionRecord.CodingKeys.sourceTokenTxInfo)
        destinationTokenTxInfo = try container.decode(ExpressPendingTransactionRecord.TokenTxInfo.self, forKey: ExpressPendingTransactionRecord.CodingKeys.destinationTokenTxInfo)
        provider = try container.decode(ExpressPendingTransactionRecord.Provider.self, forKey: ExpressPendingTransactionRecord.CodingKeys.provider)
        date = try container.decode(Date.self, forKey: ExpressPendingTransactionRecord.CodingKeys.date)
        externalTxId = try container.decodeIfPresent(String.self, forKey: ExpressPendingTransactionRecord.CodingKeys.externalTxId)
        externalTxURL = try container.decodeIfPresent(String.self, forKey: ExpressPendingTransactionRecord.CodingKeys.externalTxURL)

        if #unavailable(iOS 15) {
            let feeStr = try container.decode(String.self, forKey: ExpressPendingTransactionRecord.CodingKeys.fee)
            self.fee = Decimal(string: feeStr) ?? 0
        } else {
            fee = try container.decode(Decimal.self, forKey: ExpressPendingTransactionRecord.CodingKeys.fee)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container: KeyedEncodingContainer<ExpressPendingTransactionRecord.CodingKeys> = encoder.container(keyedBy: ExpressPendingTransactionRecord.CodingKeys.self)

        try container.encode(userWalletId, forKey: ExpressPendingTransactionRecord.CodingKeys.userWalletId)
        try container.encode(expressTransactionId, forKey: ExpressPendingTransactionRecord.CodingKeys.expressTransactionId)
        try container.encode(transactionType, forKey: ExpressPendingTransactionRecord.CodingKeys.transactionType)
        try container.encode(transactionHash, forKey: ExpressPendingTransactionRecord.CodingKeys.transactionHash)
        try container.encode(sourceTokenTxInfo, forKey: ExpressPendingTransactionRecord.CodingKeys.sourceTokenTxInfo)
        try container.encode(destinationTokenTxInfo, forKey: ExpressPendingTransactionRecord.CodingKeys.destinationTokenTxInfo)
        try container.encode(provider, forKey: ExpressPendingTransactionRecord.CodingKeys.provider)
        try container.encode(date, forKey: ExpressPendingTransactionRecord.CodingKeys.date)
        try container.encodeIfPresent(externalTxId, forKey: ExpressPendingTransactionRecord.CodingKeys.externalTxId)
        try container.encodeIfPresent(externalTxURL, forKey: ExpressPendingTransactionRecord.CodingKeys.externalTxURL)

        if #unavailable(iOS 15) {
            try container.encode("\(self.fee)", forKey: ExpressPendingTransactionRecord.CodingKeys.fee)
        } else {
            try container.encode(fee, forKey: ExpressPendingTransactionRecord.CodingKeys.fee)
        }
    }
}

extension ExpressPendingTransactionRecord.TokenTxInfo {
    enum CodingKeys: CodingKey {
        case tokenItem
        case blockchainNetwork
        case amount
        case isCustom
    }

    init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<ExpressPendingTransactionRecord.TokenTxInfo.CodingKeys> = try decoder.container(keyedBy: ExpressPendingTransactionRecord.TokenTxInfo.CodingKeys.self)

        tokenItem = try container.decode(TokenItem.self, forKey: ExpressPendingTransactionRecord.TokenTxInfo.CodingKeys.tokenItem)
        blockchainNetwork = try container.decode(BlockchainNetwork.self, forKey: ExpressPendingTransactionRecord.TokenTxInfo.CodingKeys.blockchainNetwork)
        isCustom = try container.decode(Bool.self, forKey: ExpressPendingTransactionRecord.TokenTxInfo.CodingKeys.isCustom)

        if #unavailable(iOS 15) {
            let str = try container.decode(String.self, forKey: ExpressPendingTransactionRecord.TokenTxInfo.CodingKeys.amount)
            self.amount = Decimal(string: str) ?? 0
        } else {
            amount = try container.decode(Decimal.self, forKey: ExpressPendingTransactionRecord.TokenTxInfo.CodingKeys.amount)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container: KeyedEncodingContainer<ExpressPendingTransactionRecord.TokenTxInfo.CodingKeys> = encoder.container(keyedBy: ExpressPendingTransactionRecord.TokenTxInfo.CodingKeys.self)

        try container.encode(tokenItem, forKey: ExpressPendingTransactionRecord.TokenTxInfo.CodingKeys.tokenItem)
        try container.encode(blockchainNetwork, forKey: ExpressPendingTransactionRecord.TokenTxInfo.CodingKeys.blockchainNetwork)
        try container.encode(isCustom, forKey: ExpressPendingTransactionRecord.TokenTxInfo.CodingKeys.isCustom)

        if #unavailable(iOS 15) {
            try container.encode("\(self.amount)", forKey: ExpressPendingTransactionRecord.TokenTxInfo.CodingKeys.amount)
        } else {
            try container.encode(amount, forKey: ExpressPendingTransactionRecord.TokenTxInfo.CodingKeys.amount)
        }
    }
}
