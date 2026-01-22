//
//  CachedPendingTransactionRecord.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct CachedPendingTransactionRecord {
    let hash: String
    let source: String
    let destination: String
    let amount: CachedAmount
    let fee: CachedFee
    let date: Date
    let isIncoming: Bool
    let transactionType: CachedTransactionType
    let transactionParams: CachedTransactionParams?

    public init(pendingTransactionRecord: PendingTransactionRecord) {
        hash = pendingTransactionRecord.hash
        source = pendingTransactionRecord.source
        destination = pendingTransactionRecord.destination
        amount = CachedAmount(amount: pendingTransactionRecord.amount)
        fee = CachedFee(amount: CachedAmount(amount: pendingTransactionRecord.fee.amount))
        date = pendingTransactionRecord.date
        isIncoming = pendingTransactionRecord.isIncoming
        transactionType = CachedTransactionType(from: pendingTransactionRecord.transactionType)
        transactionParams = CachedTransactionParams(
            transactionParams: pendingTransactionRecord.transactionParams
        )
    }

    var pendingTransactionRecord: PendingTransactionRecord {
        PendingTransactionRecord(
            hash: hash,
            source: source,
            destination: destination,
            amount: amount.amount,
            fee: fee.fee,
            date: date,
            isIncoming: isIncoming,
            transactionType: transactionType.transactionType,
            transactionParams: transactionParams?.transactionParams
        )
    }
}

extension CachedPendingTransactionRecord {
    enum CachedTransactionType: Codable {
        case transfer
        case operation
        case stake(target: String?)

        init(from transactionType: PendingTransactionRecord.TransactionType) {
            switch transactionType {
            case .transfer:
                self = .transfer
            case .operation:
                self = .operation
            case .stake(let target):
                self = .stake(target: target)
            }
        }

        var transactionType: PendingTransactionRecord.TransactionType {
            switch self {
            case .transfer: .transfer
            case .operation: .operation
            case .stake(let target): .stake(target: target)
            }
        }
    }

    struct CachedAmount: Codable {
        public enum AmountType: Codable {
            case coin
            case token(value: Token)
            case reserve
            case feeResource(FeeResourceType)

            init(from amountType: Amount.AmountType) {
                switch amountType {
                case .coin: self = .coin
                case .token(let token): self = .token(value: token)
                case .reserve: self = .reserve
                case .feeResource(let feeResourceType): self = .feeResource(feeResourceType)
                }
            }

            var amountType: Amount.AmountType {
                switch self {
                case .coin: .coin
                case .token(let token): .token(value: token)
                case .reserve: .reserve
                case .feeResource(let feeResourceType): .feeResource(feeResourceType)
                }
            }
        }

        let type: AmountType
        let currencySymbol: String
        var value: Decimal
        let decimals: Int

        init(amount: Amount) {
            type = AmountType(from: amount.type)
            currencySymbol = amount.currencySymbol
            value = amount.value
            decimals = amount.decimals
        }

        var amount: Amount {
            Amount(type: type.amountType, currencySymbol: currencySymbol, value: value, decimals: decimals)
        }
    }

    struct CachedFee: Codable {
        let amount: CachedAmount

        var fee: Fee {
            Fee(amount.amount, parameters: nil)
        }
    }

    enum CachedTransactionParams: Codable {
        case ethereum(CachedEthereumTransactionParams)

        init?(transactionParams: TransactionParams?) {
            switch transactionParams {
            case let params as EthereumTransactionParams:
                guard let cachedParams = CachedEthereumTransactionParams(transactionParams: params) else { return nil }
                self = .ethereum(cachedParams)
            default:
                return nil
            }
        }

        var transactionParams: TransactionParams {
            switch self {
            case .ethereum(let cachedEthereumTransactionParams):
                cachedEthereumTransactionParams.transactionParams
            }
        }
    }

    struct CachedEthereumTransactionParams: Codable {
        let data: Data?
        let nonce: Int?

        init?(transactionParams: TransactionParams?) {
            guard let params = transactionParams as? EthereumTransactionParams else { return nil }
            data = params.data
            nonce = params.nonce
        }

        var transactionParams: EthereumTransactionParams {
            EthereumTransactionParams(data: data, nonce: nonce)
        }
    }
}

extension CachedPendingTransactionRecord: Codable {}
