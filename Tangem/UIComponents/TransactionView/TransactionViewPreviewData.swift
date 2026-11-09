//
//  TransactionViewPreviewData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if DEBUG

import Foundation

enum TransactionViewPreviewData {
    static let figmaViewModels1: [TransactionViewModel] = [
        TransactionViewModel(
            hash: UUID().uuidString,
            index: 0,
            interactionAddress: .user("33BdfS...ga2B"),
            timeFormatted: "10:45",
            amount: "−0.500913 BTC",
            value: "−0.500913",
            currencyCode: "BTC",
            isOutgoing: true,
            transactionType: .operation(name: "Sending"),
            status: .inProgress,
            isFromYieldContract: false,
            isTangemPayCounterparty: false
        ),
        TransactionViewModel(
            hash: UUID().uuidString,
            index: 0,
            interactionAddress: .contract("33BdfS...ga2B"),
            timeFormatted: "10:45",
            amount: "+0.500913 BTC",
            value: "+0.500913",
            currencyCode: "BTC",
            isOutgoing: false,
            transactionType: .swap,
            status: .inProgress,
            isFromYieldContract: false,
            isTangemPayCounterparty: false
        ),
        TransactionViewModel(
            hash: UUID().uuidString,
            index: 0,
            interactionAddress: .contract("33BdfS...ga2B"),
            timeFormatted: "10:45",
            amount: "+0.500913 BTC",
            value: "+0.500913",
            currencyCode: "BTC",
            isOutgoing: false,
            transactionType: .approve,
            status: .inProgress,
            isFromYieldContract: false,
            isTangemPayCounterparty: false
        ),
        TransactionViewModel(
            hash: UUID().uuidString,
            index: 0,
            interactionAddress: .contract("33BdfS...ga2B"),
            timeFormatted: "10:45",
            amount: "+0.500913 BTC",
            value: "+0.500913",
            currencyCode: "BTC",
            isOutgoing: false,
            transactionType: .swap,
            status: .inProgress,
            isFromYieldContract: false,
            isTangemPayCounterparty: false
        ),
    ]

    static let figmaViewModels2: [TransactionViewModel] = [
        TransactionViewModel(
            hash: UUID().uuidString,
            index: 0,
            interactionAddress: .user("33BdfS...ga2B"),
            timeFormatted: "10:45",
            amount: "−0.500913 BTC",
            value: "−0.500913",
            currencyCode: "BTC",
            isOutgoing: true,
            transactionType: .operation(name: "Sending"),
            status: .confirmed,
            isFromYieldContract: false,
            isTangemPayCounterparty: false
        ),
        TransactionViewModel(
            hash: UUID().uuidString,
            index: 0,
            interactionAddress: .contract("33BdfS...ga2B"),
            timeFormatted: "10:45",
            amount: "+0.500913 BTC",
            value: "+0.500913",
            currencyCode: "BTC",
            isOutgoing: false,
            transactionType: .approve,
            status: .confirmed,
            isFromYieldContract: false,
            isTangemPayCounterparty: false
        ),
        TransactionViewModel(
            hash: UUID().uuidString,
            index: 0,
            interactionAddress: .contract("33BdfS...ga2B"),
            timeFormatted: "10:45",
            amount: "+0.500913 BTC",
            value: "+0.500913",
            currencyCode: "BTC",
            isOutgoing: false,
            transactionType: .swap,
            status: .failed,
            isFromYieldContract: false,
            isTangemPayCounterparty: false
        ),
    ]
}

#endif // DEBUG
