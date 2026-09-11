//
//  TransactionHistoryRecordsMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import TangemFoundation
import TangemAppDatabase

enum TransactionHistoryRecordsMapper {
    // MARK: Domain to record: Express exchange transactions

    static func mapToExpressExchangeTransactionRecord(
        _ transaction: ExchangeTransaction,
        ownerAddress: String
    ) -> ExpressExchangeTransactionRecord {
        let fromCurrency = transaction.from.currency
        let toCurrency = transaction.to.currency
        let refundCurrency = transaction.refund?.currency
        let fromNetwork = fromCurrency.network
        let toNetwork = toCurrency.network
        let refundNetwork = refundCurrency?.network

        return ExpressExchangeTransactionRecord(
            id: transaction.txId,
            ownerAddress: ownerAddress,
            providerID: transaction.providerId,
            // The funds are sent on the `from` network, so both the sender and the payin addresses belong to it
            // (therefore we use `fromNetwork` for both here).
            fromAddress: TransactionHistoryAddressNormalizer.normalize(transaction.fromAddress, networkID: fromNetwork),
            payInAddress: TransactionHistoryAddressNormalizer.normalize(transaction.payIn.address, networkID: fromNetwork),
            payInExtraId: transaction.payIn.extraId,
            payOutAddress: TransactionHistoryAddressNormalizer.normalize(transaction.payOut.address, networkID: toNetwork),
            status: transaction.status.rawValue,
            rateType: transaction.rateType?.rawValue,
            externalTxID: transaction.externalTx?.id,
            externalTxURL: transaction.externalTx?.url?.absoluteString,
            payInHash: transaction.payIn.hash,
            payOutHash: transaction.payOut.hash,
            fromNetwork: fromNetwork,
            fromContract: TransactionHistoryAddressNormalizer.normalize(fromCurrency.contractAddress, networkID: fromNetwork),
            fromAmount: transaction.from.amount.stringValue,
            fromDecimals: transaction.from.decimals,
            fromActualAmount: transaction.from.actualAmount?.stringValue,
            toNetwork: toNetwork,
            toContract: TransactionHistoryAddressNormalizer.normalize(toCurrency.contractAddress, networkID: toNetwork),
            toAmount: transaction.to.amount.stringValue,
            toDecimals: transaction.to.decimals,
            toActualAmount: transaction.to.actualAmount?.stringValue,
            refundAddress: TransactionHistoryAddressNormalizer.normalize(transaction.refund?.address, networkID: refundNetwork),
            refundExtraId: transaction.refund?.extraId,
            refundNetwork: refundNetwork,
            refundContractAddress: TransactionHistoryAddressNormalizer.normalize(
                refundCurrency?.contractAddress,
                networkID: refundNetwork
            ),
            createdAt: transaction.createdAt,
            updatedAt: transaction.updatedAt
        )
    }

    static func mapToTransactionHistoryIndexRecords(_ transaction: ExchangeTransaction) -> [TransactionHistoryIndexRecord] {
        let entityType = TransactionHistoryIndexRecord.Values.EntityType.expressExchange
        let entityID = transaction.txId
        let dateTime = transaction.createdAt
        let toCurrency = transaction.to.currency

        var records: [TransactionHistoryIndexRecord] = []

        if let fromAddress = transaction.fromAddress {
            let fromCurrency = transaction.from.currency

            records.append(
                makeIndexRecord(
                    entityType: entityType,
                    entityID: entityID,
                    address: fromAddress,
                    network: fromCurrency.network,
                    contract: fromCurrency.contractAddress,
                    dateTime: dateTime
                )
            )
        }

        records.append(
            makeIndexRecord(
                entityType: entityType,
                entityID: entityID,
                address: transaction.payOut.address,
                network: toCurrency.network,
                contract: toCurrency.contractAddress,
                dateTime: dateTime
            )
        )

        if let refund = transaction.refund, let refundCurrency = refund.currency {
            records.append(
                makeIndexRecord(
                    entityType: entityType,
                    entityID: entityID,
                    address: refund.address,
                    network: refundCurrency.network,
                    contract: refundCurrency.contractAddress,
                    dateTime: dateTime
                )
            )
        }

        return records
    }

    // MARK: Domain to record: Express onramp transactions

    static func mapToExpressOnrampTransactionRecord(
        _ transaction: OnrampTransaction,
        ownerAddress: String
    ) -> ExpressOnrampTransactionRecord {
        let toCurrency = transaction.to.currency
        let toNetwork = toCurrency.network

        return ExpressOnrampTransactionRecord(
            id: transaction.txId,
            ownerAddress: ownerAddress,
            providerID: transaction.providerId,
            payOutAddress: TransactionHistoryAddressNormalizer.normalize(transaction.payOut.address, networkID: toNetwork),
            status: transaction.status.rawValue,
            externalTxID: transaction.externalTx?.id,
            externalTxURL: transaction.externalTx?.url?.absoluteString,
            payOutHash: transaction.payOut.hash,
            fromCurrency: transaction.from.currencyCode,
            fromAmount: transaction.from.amount.stringValue,
            toNetwork: toNetwork,
            toContract: TransactionHistoryAddressNormalizer.normalize(toCurrency.contractAddress, networkID: toNetwork),
            toAmount: transaction.to.amount?.stringValue,
            toDecimals: transaction.to.decimals,
            toActualAmount: transaction.to.actualAmount?.stringValue,
            failReason: transaction.failReason,
            paymentMethod: transaction.paymentMethod,
            countryCode: transaction.countryCode,
            createdAt: transaction.createdAt,
            updatedAt: transaction.updatedAt
        )
    }

    static func mapToTransactionHistoryIndexRecords(_ transaction: OnrampTransaction) -> [TransactionHistoryIndexRecord] {
        let toCurrency = transaction.to.currency

        // Only the payout leg has an address, therefore we only create a single index record for it
        return [
            makeIndexRecord(
                entityType: TransactionHistoryIndexRecord.Values.EntityType.expressOnramp,
                entityID: transaction.txId,
                address: transaction.payOut.address,
                network: toCurrency.network,
                contract: toCurrency.contractAddress,
                dateTime: transaction.createdAt
            ),
        ]
    }

    // MARK: Record to domain: Express exchange/onramp transactions

    static func mapToTransactionHistoryExpressExtraInfo(
        _ infos: [TransactionHistoryIndexInfoRecord]
    ) -> [TransactionHistoryExpressExtraInfo] {
        return infos.compactMap { info in
            do {
                return try mapToTransactionHistoryExpressExtraInfo(info)
            } catch {
                // A single malformed record shouldn't prevent the remaining ones from being mapped,
                // therefore only log the error w/o throwing it
                TransactionHistoryLogger.warning("Skipping malformed transaction history record \(info.indexRecord.entityID): \(error)")

                return nil
            }
        }
    }

    private static func mapToTransactionHistoryExpressExtraInfo(
        _ info: TransactionHistoryIndexInfoRecord
    ) throws -> TransactionHistoryExpressExtraInfo {
        let indexRecord = info.indexRecord

        switch indexRecord.entityType {
        case TransactionHistoryIndexRecord.Values.EntityType.expressExchange:
            guard let records = info.exchangeTransaction else {
                throw "Missing exchange transaction \(indexRecord.entityID) referenced by an index record"
            }

            return .exchange(try mapToExchangeTransactionInfo(records))

        case TransactionHistoryIndexRecord.Values.EntityType.expressOnramp:
            guard let records = info.onrampTransaction else {
                throw "Missing onramp transaction \(indexRecord.entityID) referenced by an index record"
            }

            return .onramp(try mapToOnrampTransactionInfo(records))

        default:
            throw "Unknown entity type \(indexRecord.entityType) of an index record for entity \(indexRecord.entityID)"
        }
    }

    private static func mapToExchangeTransactionInfo(
        _ records: TransactionHistoryIndexInfoRecord.ExchangeRecords
    ) throws -> ExchangeTransactionInfo {
        let transaction = try mapToExchangeTransaction(records.transaction)
        let provider = try records.provider.map(TransactionHistoryAuxDataMapper.mapToExpressProvider)
        let cryptoCurrencies = mapToCryptoCurrencies([
            records.fromCryptoCurrency,
            records.toCryptoCurrency,
            records.refundCryptoCurrency,
        ])

        return ExchangeTransactionInfo(
            transaction: transaction,
            provider: provider,
            cryptoCurrencies: cryptoCurrencies
        )
    }

    private static func mapToOnrampTransactionInfo(
        _ records: TransactionHistoryIndexInfoRecord.OnrampRecords
    ) throws -> OnrampTransactionInfo {
        let transaction = try mapToOnrampTransaction(records.transaction)
        let provider = try records.provider.map(TransactionHistoryAuxDataMapper.mapToExpressProvider)
        let fiatCurrency = try records.fiatCurrency.map(TransactionHistoryAuxDataMapper.mapToOnrampFiatCurrency)
        let cryptoCurrencies = mapToCryptoCurrencies([records.cryptoCurrency])

        return OnrampTransactionInfo(
            transaction: transaction,
            provider: provider,
            fiatCurrency: fiatCurrency,
            cryptoCurrencies: cryptoCurrencies
        )
    }

    private static func mapToExchangeTransaction(_ record: ExpressExchangeTransactionRecord) throws -> ExchangeTransaction {
        let externalTx = try mapToExternalTxInfo(id: record.externalTxID, urlString: record.externalTxURL)
        let fromAmount = try TransactionHistoryValueMapper.decimal(fromString: record.fromAmount)
        let toAmount = try TransactionHistoryValueMapper.decimal(fromString: record.toAmount)
        let toActualAmount = try TransactionHistoryValueMapper.decimal(fromString: record.toActualAmount)

        let from = ExpressHistoryAsset(
            currency: ExpressCurrency(contractAddress: record.fromContract, network: record.fromNetwork),
            amount: fromAmount,
            actualAmount: nil, // The `from` side of an exchange has no actual amount, hence nothing to restore here
            decimals: record.fromDecimals
        )

        let to = ExpressHistoryAsset(
            currency: ExpressCurrency(contractAddress: record.toContract, network: record.toNetwork),
            amount: toAmount,
            actualAmount: toActualAmount,
            decimals: record.toDecimals
        )

        return ExchangeTransaction(
            txId: record.id,
            providerId: record.providerID,
            status: ExpressTransactionStatus(rawValue: record.status) ?? .unknown,
            rateType: record.rateType.flatMap(ExpressProviderRateType.init(rawValue:)),
            externalTx: externalTx,
            fromAddress: record.fromAddress,
            payIn: PayInInfo(address: record.payInAddress, extraId: record.payInExtraId, hash: record.payInHash),
            payOut: PayOutInfo(address: record.payOutAddress, hash: record.payOutHash),
            refund: mapToRefundInfo(record),
            from: from,
            to: to,
            createdAt: record.createdAt,
            updatedAt: record.updatedAt,
            payTill: nil, // This field is not used in the tx history, so it is not persisted and always restored as `nil`
            averageDuration: nil // This field is not used in the tx history, so it is not persisted and always restored as `nil`
        )
    }

    private static func mapToOnrampTransaction(_ record: ExpressOnrampTransactionRecord) throws -> OnrampTransaction {
        let externalTx = try mapToExternalTxInfo(id: record.externalTxID, urlString: record.externalTxURL)
        let fromAmount = try TransactionHistoryValueMapper.decimal(fromString: record.fromAmount)
        let toAmount = try TransactionHistoryValueMapper.decimal(fromString: record.toAmount)
        let toActualAmount = try TransactionHistoryValueMapper.decimal(fromString: record.toActualAmount)

        let to = OnrampHistoryCryptoAsset(
            currency: ExpressCurrency(contractAddress: record.toContract, network: record.toNetwork),
            amount: toAmount,
            actualAmount: toActualAmount,
            decimals: record.toDecimals
        )

        return OnrampTransaction(
            txId: record.id,
            providerId: record.providerID,
            status: OnrampTransactionStatus(rawValue: record.status) ?? .unknown,
            failReason: record.failReason,
            externalTx: externalTx,
            payOut: PayOutInfo(address: record.payOutAddress, hash: record.payOutHash),
            from: OnrampHistoryFiatAsset(currencyCode: record.fromCurrency, amount: fromAmount),
            to: to,
            paymentMethod: record.paymentMethod,
            countryCode: record.countryCode,
            createdAt: record.createdAt,
            updatedAt: record.updatedAt
        )
    }

    private static func mapToExternalTxInfo(id: String?, urlString: String?) throws -> ExternalTxInfo? {
        guard let id else {
            return nil
        }

        return ExternalTxInfo(id: id, url: try TransactionHistoryValueMapper.url(fromString: urlString))
    }

    private static func mapToRefundInfo(_ record: ExpressExchangeTransactionRecord) -> RefundInfo? {
        guard let address = record.refundAddress else {
            return nil
        }

        let currency: ExpressCurrency? = if let network = record.refundNetwork, let contractAddress = record.refundContractAddress {
            ExpressCurrency(contractAddress: contractAddress, network: network)
        } else {
            nil
        }

        return RefundInfo(address: address, extraId: record.refundExtraId, currency: currency)
    }

    private static func mapToCryptoCurrencies(_ records: [CryptoCurrencyRecord?]) -> [ExpressCurrency: TokenItem] {
        return records
            .compactMap(\.self)
            .reduce(into: [:]) { partialResult, record in
                do {
                    let currency = ExpressCurrency(contractAddress: record.contractAddress, network: record.networkID)
                    partialResult[currency] = try TransactionHistoryAuxDataMapper.mapToTokenItem(record)
                } catch {
                    // A single malformed crypto currency shouldn't prevent the entire transaction from being mapped,
                    // therefore only log the error w/o throwing it
                    TransactionHistoryLogger.warning("Skipping malformed crypto currency \(record.networkID): \(error)")
                }
            }
    }

    // MARK: Domain to record: Shared helpers

    private static func makeIndexRecord(
        entityType: String,
        entityID: String,
        address: String,
        network: String,
        contract: String,
        dateTime: Date
    ) -> TransactionHistoryIndexRecord {
        return TransactionHistoryIndexRecord(
            entityType: entityType,
            entityID: entityID,
            address: TransactionHistoryAddressNormalizer.normalize(address, networkID: network),
            network: network,
            contract: TransactionHistoryAddressNormalizer.normalize(contract, networkID: network),
            dateTime: dateTime
        )
    }
}
