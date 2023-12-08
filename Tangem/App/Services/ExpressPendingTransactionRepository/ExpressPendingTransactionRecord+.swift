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

        userWalletId = try container.decode(String.self, forKey: .userWalletId)
        expressTransactionId = try container.decode(String.self, forKey: .expressTransactionId)
        transactionType = try container.decode(ExpressPendingTransactionRecord.TransactionType.self, forKey: .transactionType)
        transactionHash = try container.decode(String.self, forKey: .transactionHash)
        sourceTokenTxInfo = try container.decode(ExpressPendingTransactionRecord.TokenTxInfo.self, forKey: .sourceTokenTxInfo)
        destinationTokenTxInfo = try container.decode(ExpressPendingTransactionRecord.TokenTxInfo.self, forKey: .destinationTokenTxInfo)
        provider = try container.decode(ExpressPendingTransactionRecord.Provider.self, forKey: .provider)
        date = try container.decode(Date.self, forKey: .date)
        externalTxId = try container.decodeIfPresent(String.self, forKey: .externalTxId)
        externalTxURL = try container.decodeIfPresent(String.self, forKey: .externalTxURL)

        if #unavailable(iOS 15) {
            let feeStr = try container.decode(String.self, forKey: .fee)
            self.fee = Decimal(string: feeStr) ?? 0
        } else {
            fee = try container.decode(Decimal.self, forKey: .fee)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container: KeyedEncodingContainer<ExpressPendingTransactionRecord.CodingKeys> = encoder.container(keyedBy: ExpressPendingTransactionRecord.CodingKeys.self)

        try container.encode(userWalletId, forKey: .userWalletId)
        try container.encode(expressTransactionId, forKey: .expressTransactionId)
        try container.encode(transactionType, forKey: .transactionType)
        try container.encode(transactionHash, forKey: .transactionHash)
        try container.encode(sourceTokenTxInfo, forKey: .sourceTokenTxInfo)
        try container.encode(destinationTokenTxInfo, forKey: .destinationTokenTxInfo)
        try container.encode(provider, forKey: .provider)
        try container.encode(date, forKey: .date)
        try container.encodeIfPresent(externalTxId, forKey: .externalTxId)
        try container.encodeIfPresent(externalTxURL, forKey: .externalTxURL)

        if #unavailable(iOS 15) {
            try container.encode("\(self.fee)", forKey: .fee)
        } else {
            try container.encode(fee, forKey: .fee)
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

        tokenItem = try container.decode(TokenItem.self, forKey: .tokenItem)
        blockchainNetwork = try container.decode(BlockchainNetwork.self, forKey: .blockchainNetwork)
        isCustom = try container.decode(Bool.self, forKey: .isCustom)

        if #unavailable(iOS 15) {
            let str = try container.decode(String.self, forKey: .amount)
            self.amount = Decimal(string: str) ?? 0
        } else {
            amount = try container.decode(Decimal.self, forKey: .amount)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container: KeyedEncodingContainer<ExpressPendingTransactionRecord.TokenTxInfo.CodingKeys> = encoder.container(keyedBy: ExpressPendingTransactionRecord.TokenTxInfo.CodingKeys.self)

        try container.encode(tokenItem, forKey: .tokenItem)
        try container.encode(blockchainNetwork, forKey: .blockchainNetwork)
        try container.encode(isCustom, forKey: .isCustom)

        if #unavailable(iOS 15) {
            try container.encode("\(self.amount)", forKey: .amount)
        } else {
            try container.encode(amount, forKey: .amount)
        }
    }
}
