//
//  ExpressAPIMapper.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLogger

struct ExpressAPIMapper {
    let exchangeDataDecoder: ExpressExchangeDataDecoder

    // MARK: - Map to DTO

    func mapToDTOCurrency(currency: ExpressWalletCurrency) -> ExpressDTO.Currency {
        ExpressDTO.Currency(contractAddress: currency.contractAddress, network: currency.network)
    }

    // MARK: - Swap

    func mapToExpressCurrency(currency: ExpressDTO.Currency) -> ExpressCurrency {
        ExpressCurrency(contractAddress: currency.contractAddress, network: currency.network)
    }

    func mapToExpressPair(response: ExpressDTO.Swap.Pairs.Response) -> ExpressPair {
        let providers = response.providers.map { provider in
            let rates = provider.rateTypes
                .compactMap { ExpressProviderRateType(rawValue: $0) }

            return ExpressPairProvider(id: provider.providerId, rates: rates)
        }

        return ExpressPair(
            source: mapToExpressCurrency(currency: response.from),
            destination: mapToExpressCurrency(currency: response.to),
            providers: providers
        )
    }

    func mapToExpressAsset(response: ExpressDTO.Swap.Assets.Response) -> ExpressAsset {
        ExpressAsset(
            currency: ExpressCurrency(contractAddress: response.contractAddress, network: response.network),
            isExchangeable: response.exchangeAvailable,
            isOnrampable: response.onrampAvailable ?? false
        )
    }

    func mapToExpressProvider(provider: ExpressDTO.Swap.Providers.Response) -> ExpressProvider {
        ExpressProvider(
            id: .init(provider.id),
            name: provider.name,
            type: provider.type.flatMap(ExpressProviderType.init(rawValue:)) ?? .unknown,
            exchangeOnlyWithinSingleAddress: provider.exchangeOnlyWithinSingleAddress ?? false,
            imageURL: provider.imageSmall.flatMap(URL.init(string:)),
            termsOfUse: provider.termsOfUse.flatMap(URL.init(string:)),
            privacyPolicy: provider.privacyPolicy.flatMap(URL.init(string:)),
            recommended: provider.recommended,
            slippage: provider.slippage.map { $0 / 100 }
        )
    }

    func mapToExpressQuote(response: ExpressDTO.Swap.ExchangeQuote.Response) throws -> ExpressQuote {
        guard var fromAmount = Decimal(stringValue: response.fromAmount) else {
            throw ExpressAPIMapperError.mapToDecimalError(response.fromAmount)
        }

        guard var toAmount = Decimal(stringValue: response.toAmount) else {
            throw ExpressAPIMapperError.mapToDecimalError(response.toAmount)
        }

        fromAmount /= pow(10, response.fromDecimals)
        toAmount /= pow(10, response.toDecimals)

        return ExpressQuote(
            fromAmount: fromAmount,
            expectAmount: toAmount,
            allowanceContract: response.allowanceContract,
            quoteId: response.quoteId,
            txType: response.txType.flatMap { ExpressTransactionType(rawValue: $0) }
        )
    }

    func mapToExpressTransactionData(
        item: ExpressSwappableDataItem,
        request: ExpressDTO.Swap.ExchangeData.Request,
        response: ExpressDTO.Swap.ExchangeData.Response
    ) throws -> ExpressTransactionData {
        let txDetails: DecodedTransactionDetails = try exchangeDataDecoder.decode(
            txDetailsJson: response.txDetailsJson,
            signature: response.signature
        )
        ExpressLogger.info(txDetails.logDescription)

        guard request.requestId == txDetails.requestId else {
            throw ExpressAPIMapperError.requestIdNotEqual
        }

        guard request.toAddress.caseInsensitiveCompare(txDetails.payoutAddress) == .orderedSame else {
            throw ExpressAPIMapperError.payoutAddressNotEqual
        }

        // Validate payout extra id matches what we sent (case-sensitive for memos)
        if request.toExtraId != txDetails.payoutExtraId {
            throw ExpressAPIMapperError.payoutExtraIdNotEqual
        }

        guard var fromAmount = Decimal(stringValue: response.fromAmount) else {
            throw ExpressAPIMapperError.mapToDecimalError(response.fromAmount)
        }

        guard var toAmount = Decimal(stringValue: response.toAmount) else {
            throw ExpressAPIMapperError.mapToDecimalError(response.toAmount)
        }

        fromAmount /= pow(10, response.fromDecimals)
        toAmount /= pow(10, response.toDecimals)

        let txValue = try mapTxValueToDecimalValue(item: item, txValue: txDetails.txValue, txType: txDetails.txType)

        let otherNativeFee = txDetails.otherNativeFee
            .flatMap { Decimal(stringValue: $0) }
            .map { $0 / pow(10, item.source.coinCurrency.decimalCount) }

        return ExpressTransactionData(
            requestId: txDetails.requestId,
            fromAmount: fromAmount,
            toAmount: toAmount,
            expressTransactionId: response.txId,
            transactionType: txDetails.txType,
            sourceAddress: txDetails.txFrom,
            destinationAddress: txDetails.txTo,
            extraDestinationId: txDetails.txExtraId,
            txValue: txValue,
            txData: txDetails.txData,
            otherNativeFee: otherNativeFee,
            estimatedGasLimit: txDetails.gas.flatMap(Int.init),
            externalTxId: txDetails.externalTxId,
            externalTxURL: txDetails.externalTxUrl.flatMap(URL.init(string:)),
            payInAddress: txDetails.txTo
        )
    }

    func mapTxValueToDecimalValue(item: ExpressSwappableDataItem, txValue: String?, txType: ExpressTransactionType) throws -> Decimal {
        switch txType {
        case .send:
            guard let txValue, let decimalTxValue = Decimal(stringValue: txValue) else {
                throw ExpressAPIMapperError.mapToDecimalError(txValue ?? "")
            }

            // For CEX/send we have txValue amount as value which have to be sent
            return decimalTxValue / pow(10, item.source.currency.decimalCount)
        case .swap:
            if let txValue, let decimalTxValue = Decimal(stringValue: txValue) {
                // For DEX/swap we have txValue amount as coin. Because it's EVM or Solana DEX
                return decimalTxValue / pow(10, item.source.coinCurrency.decimalCount)
            }

            return .zero
        }
    }

    // MARK: - Onramp

    func mapToOnrampFiatCurrency(response: ExpressDTO.Onramp.FiatCurrency) -> OnrampFiatCurrency {
        let identity = OnrampIdentity(name: response.name, code: response.code, image: response.image.flatMap(URL.init(string:)))
        return OnrampFiatCurrency(identity: identity, precision: response.precision)
    }

    func mapToOnrampCountry(response: ExpressDTO.Onramp.Country) -> OnrampCountry {
        let identity = OnrampIdentity(name: response.name, code: response.code, image: response.image.flatMap(URL.init(string:)))
        let currency = mapToOnrampFiatCurrency(response: response.defaultCurrency)
        return OnrampCountry(identity: identity, currency: currency, onrampAvailable: response.onrampAvailable)
    }

    func mapToOnrampPaymentMethod(response: ExpressDTO.Onramp.PaymentMethod) -> OnrampPaymentMethod? {
        let method = OnrampPaymentMethod(id: response.id, name: response.name, image: response.image)

        guard OnrampPaymentMethodsFilter().isSupported(paymentMethod: method) else {
            ExpressLogger.info(
                String(
                    format: "Unsupported onramp payment method dropped: id %@, name %@",
                    response.id,
                    response.name
                )
            )
            return nil
        }

        return method
    }

    func mapToOnrampPair(response: ExpressDTO.Onramp.Pairs.Response) -> OnrampPair {
        OnrampPair(
            fiatCurrencyCode: response.fromCurrencyCode,
            currency: mapToExpressCurrency(currency: response.to),
            providers: response.providers.map { provider in
                OnrampPair.Provider(id: provider.providerId, paymentMethods: provider.paymentMethods)
            }
        )
    }

    func mapToOnrampQuote(response: ExpressDTO.Onramp.Quote.Response) throws -> OnrampQuote {
        guard var toAmount = Decimal(stringValue: response.toAmount) else {
            throw ExpressAPIMapperError.mapToDecimalError(response.toAmount)
        }

        toAmount /= pow(10, response.toDecimals)

        return OnrampQuote(
            expectedAmount: toAmount,
            nativePaymentAvailable: response.nativePaymentAvailable ?? false,
            quoteId: response.quoteId
        )
    }

    func mapToOnrampDataResult(
        request: ExpressDTO.Onramp.NativePaymentData.Request,
        response: ExpressDTO.Onramp.NativePaymentData.Response
    ) throws -> OnrampDataResult {
        let codedData: ExpressDTO.Onramp.Data.CodedData = try exchangeDataDecoder.decode(
            txDetailsJson: response.dataJson,
            signature: response.signature
        )

        guard request.requestId == codedData.requestId else {
            throw ExpressAPIMapperError.requestIdNotEqual
        }

        guard request.toAddress.caseInsensitiveCompare(codedData.toAddress) == .orderedSame else {
            throw ExpressAPIMapperError.payoutAddressNotEqual
        }

        guard var fromAmount = Decimal(stringValue: codedData.fromAmount) else {
            throw ExpressAPIMapperError.mapToDecimalError(codedData.fromAmount)
        }

        fromAmount /= pow(10, codedData.fromPrecision)

        switch response.txType {
        case .nativePayment:
            return .nativePayment(OnrampNativePaymentData(
                txId: response.txId,
                fromAmount: fromAmount,
                fromCurrencyCode: codedData.fromCurrencyCode,
                toAmount: codedData.toAmount,
                countryCode: codedData.countryCode,
                externalTxId: codedData.externalTxId,
                externalTxURL: codedData.externalTxUrl.flatMap(URL.init(string:))
            ))
        case .widget, .none:
            guard let widgetURL = codedData.widgetUrl else {
                throw ExpressAPIMapperError.widgetUrlMissing
            }

            return .widget(OnrampRedirectData(
                txId: response.txId,
                widgetURL: widgetURL,
                redirectURL: codedData.redirectUrl,
                fromAmount: fromAmount,
                fromCurrencyCode: codedData.fromCurrencyCode,
                toAmount: codedData.toAmount,
                countryCode: codedData.countryCode,
                externalTxId: codedData.externalTxId,
                externalTxURL: codedData.externalTxUrl.flatMap(URL.init(string:))
            ))
        }
    }

    func mapToOnrampRedirectData(
        item: OnrampRedirectDataRequestItem,
        request: ExpressDTO.Onramp.Data.Request,
        response: ExpressDTO.Onramp.Data.Response
    ) throws -> OnrampRedirectData {
        let codedData: ExpressDTO.Onramp.Data.CodedData = try exchangeDataDecoder.decode(
            txDetailsJson: response.dataJson,
            signature: response.signature
        )

        guard request.requestId == codedData.requestId else {
            throw ExpressAPIMapperError.requestIdNotEqual
        }

        guard var fromAmount = Decimal(stringValue: codedData.fromAmount) else {
            throw ExpressAPIMapperError.mapToDecimalError(codedData.fromAmount)
        }

        fromAmount /= pow(10, codedData.fromPrecision)

        guard let widgetURL = codedData.widgetUrl else {
            throw ExpressAPIMapperError.widgetUrlMissing
        }

        return OnrampRedirectData(
            txId: response.txId,
            widgetURL: widgetURL,
            redirectURL: codedData.redirectUrl,
            fromAmount: fromAmount,
            fromCurrencyCode: codedData.fromCurrencyCode,
            toAmount: codedData.toAmount,
            countryCode: codedData.countryCode,
            externalTxId: codedData.externalTxId,
            externalTxURL: codedData.externalTxUrl.flatMap(URL.init(string:))
        )
    }

    // MARK: - Transactions & history

    func mapToExchangeHistoryPage(response: ExpressDTO.Swap.History.Response) throws -> ExchangeHistoryPage {
        try ExchangeHistoryPage(
            records: response.items.map(mapToExchangeTransaction(record:)),
            nextCursor: response.pagination.endCursor?.value,
            startDeltaCursor: response.pagination.startDeltaCursor?.value,
            hasMore: response.pagination.hasMore ?? response.pagination.hasNextPage ?? false // [REDACTED_TODO_COMMENT]
        )
    }

    func mapToExchangeHistoryPage(response: ExpressDTO.Swap.HistoryDelta.Response) throws -> ExchangeHistoryPage {
        try ExchangeHistoryPage(
            records: response.items.map(mapToExchangeTransaction(record:)),
            nextCursor: response.pagination.startCursor?.value,
            startDeltaCursor: nil,
            hasMore: response.pagination.hasMore
        )
    }

    func mapToOnrampHistoryPage(response: ExpressDTO.Onramp.History.Response) throws -> OnrampHistoryPage {
        try OnrampHistoryPage(
            records: response.items.map(mapToOnrampTransaction(record:)),
            nextCursor: response.pagination.endCursor?.value,
            startDeltaCursor: response.pagination.startDeltaCursor?.value,
            hasMore: response.pagination.hasMore ?? response.pagination.hasNextPage ?? false // [REDACTED_TODO_COMMENT]
        )
    }

    func mapToOnrampHistoryPage(response: ExpressDTO.Onramp.HistoryDelta.Response) throws -> OnrampHistoryPage {
        try OnrampHistoryPage(
            records: response.items.map(mapToOnrampTransaction(record:)),
            nextCursor: response.pagination.startCursor?.value,
            startDeltaCursor: nil,
            hasMore: response.pagination.hasMore
        )
    }

    func mapToExchangeTransaction(record: ExpressDTO.Swap.Transaction) throws -> ExchangeTransaction {
        try ExchangeTransaction(
            txId: record.txId,
            providerId: record.providerId,
            status: ExpressTransactionStatus(rawValue: record.status) ?? .unknown,
            rateType: ExpressProviderRateType(rawValue: record.rateType),
            externalTx: mapToExternalTxInfo(id: record.externalTxId, url: record.externalTxUrl),
            fromAddress: record.fromAddress,
            payIn: PayInInfo(address: record.payinAddress, extraId: record.payinExtraId, hash: record.payinHash),
            payOut: PayOutInfo(address: record.payoutAddress, hash: record.payoutHash),
            refund: mapToRefundInfo(
                address: record.refundAddress,
                extraId: record.refundExtraId,
                network: record.refundNetwork,
                contractAddress: record.refundContractAddress
            ),
            from: mapToExpressHistoryAsset(
                contractAddress: record.fromContractAddress,
                network: record.fromNetwork,
                decimals: record.fromDecimals,
                amount: record.fromAmount,
                actualAmount: nil
            ),
            to: mapToExpressHistoryAsset(
                contractAddress: record.toContractAddress,
                network: record.toNetwork,
                decimals: record.toDecimals,
                amount: record.toAmount,
                actualAmount: record.toActualAmount
            ),
            createdAt: record.createdAt,
            updatedAt: record.updatedAt ?? record.createdAt,
            payTill: record.payTill,
            averageDuration: record.averageDuration
        )
    }

    func mapToOnrampTransaction(record: ExpressDTO.Onramp.Transaction) throws -> OnrampTransaction {
        try OnrampTransaction(
            txId: record.txId,
            providerId: record.providerId,
            status: OnrampTransactionStatus(rawValue: record.status) ?? .unknown,
            failReason: record.failReason,
            externalTx: mapToExternalTxInfo(id: record.externalTxId, url: record.externalTxUrl),
            payOut: PayOutInfo(address: record.payoutAddress, hash: record.payoutHash),
            from: mapToOnrampHistoryFiatAsset(
                currencyCode: record.fromCurrencyCode,
                amount: record.fromAmount,
                precision: record.fromPrecision
            ),
            to: mapToOnrampHistoryCryptoAsset(
                contractAddress: record.toContractAddress,
                network: record.toNetwork,
                decimals: record.toDecimals,
                amount: record.toAmount,
                actualAmount: record.toActualAmount
            ),
            paymentMethod: record.paymentMethod,
            countryCode: record.countryCode,
            createdAt: record.createdAt,
            updatedAt: record.updatedAt ?? record.createdAt
        )
    }

    private func mapToExternalTxInfo(id: String?, url: String?) -> ExternalTxInfo? {
        guard let id else {
            return nil
        }

        return ExternalTxInfo(id: id, url: url.flatMap(URL.init(string:)))
    }

    private func mapToRefundInfo(address: String?, extraId: String?, network: String?, contractAddress: String?) -> RefundInfo? {
        guard let address else {
            ExpressLogger.info(
                String(
                    format: "Refund info missing required field: address %@ (extraId %@, network %@, contractAddress %@)",
                    String(describing: address),
                    String(describing: extraId),
                    String(describing: network),
                    String(describing: contractAddress)
                )
            )
            return nil
        }

        return RefundInfo(
            address: address,
            extraId: extraId,
            currency: mapToRefundedCurrency(network: network, contractAddress: contractAddress)
        )
    }

    private func mapToExpressHistoryAsset(
        contractAddress: String,
        network: String,
        decimals: Int,
        amount: String,
        actualAmount: String?
    ) throws -> ExpressHistoryAsset {
        guard let rawAmount = Decimal(stringValue: amount) else {
            throw ExpressAPIMapperError.mapToDecimalError(amount)
        }

        let actual: Decimal? = try actualAmount.map { value in
            guard let rawActual = Decimal(stringValue: value) else {
                throw ExpressAPIMapperError.mapToDecimalError(value)
            }

            return rawActual / pow(10, decimals)
        }

        return ExpressHistoryAsset(
            currency: ExpressCurrency(contractAddress: contractAddress, network: network),
            amount: rawAmount / pow(10, decimals),
            actualAmount: actual,
            decimals: decimals
        )
    }

    private func mapToOnrampHistoryFiatAsset(
        currencyCode: String,
        amount: String,
        precision: Int
    ) throws -> OnrampHistoryFiatAsset {
        guard let rawAmount = Decimal(stringValue: amount) else {
            throw ExpressAPIMapperError.mapToDecimalError(amount)
        }

        return OnrampHistoryFiatAsset(currencyCode: currencyCode, amount: rawAmount / pow(10, precision))
    }

    private func mapToOnrampHistoryCryptoAsset(
        contractAddress: String,
        network: String,
        decimals: Int,
        amount: String?,
        actualAmount: String?
    ) throws -> OnrampHistoryCryptoAsset {
        func mapToDecimal(_ value: String) throws -> Decimal {
            guard let rawValue = Decimal(stringValue: value) else {
                throw ExpressAPIMapperError.mapToDecimalError(value)
            }

            return rawValue / pow(10, decimals)
        }

        return try OnrampHistoryCryptoAsset(
            currency: ExpressCurrency(contractAddress: contractAddress, network: network),
            amount: amount.map(mapToDecimal),
            actualAmount: actualAmount.map(mapToDecimal),
            decimals: decimals
        )
    }

    private func mapToRefundedCurrency(network: String?, contractAddress: String?) -> ExpressCurrency? {
        guard let network else {
            ExpressLogger.info(
                String(
                    format: "Refunded currency missing required field: network %@",
                    String(describing: network)
                )
            )
            return nil
        }

        // A `nil` contract address means the native coin
        return ExpressCurrency(
            contractAddress: contractAddress ?? ExpressConstants.coinContractAddress,
            network: network
        )
    }
}

enum ExpressAPIMapperError: LocalizedError {
    case mapToDecimalError(_ string: String)
    case requestIdNotEqual
    case payoutAddressNotEqual
    case payoutExtraIdNotEqual
    case widgetUrlMissing

    var errorDescription: String? {
        switch self {
        case .mapToDecimalError(let value): "Wrong decimal value \(value)"
        case .requestIdNotEqual: "Request id is not matched with value in the request"
        case .payoutAddressNotEqual: "Payout address is not matched with value in the request"
        case .payoutExtraIdNotEqual: "Payout extra id is not matched with value in the request"
        case .widgetUrlMissing: "Widget url is missing for a widget transaction"
        }
    }
}

// MARK: - Logging

private extension DecodedTransactionDetails {
    var logDescription: String {
        "Exchange data decoded transaction details payload:"
            .appendingLogProperty(\.requestId, of: self)
            .appendingLogProperty(\.txType, of: self)
            .appendingLogProperty(\.txFrom, of: self)
            .appendingLogProperty(\.txTo, of: self)
            .appendingLogProperty(\.txExtraId, of: self)
            // txData skipped intentionally
            .appendingLogProperty(\.txValue, of: self)
            .appendingLogProperty(\.otherNativeFee, of: self)
            .appendingLogProperty(\.gas, of: self)
            .appendingLogProperty(\.externalTxId, of: self)
            .appendingLogProperty(\.externalTxUrl, of: self)
            .appendingLogProperty(\.payoutAddress, of: self)
            .appendingLogProperty(\.payoutExtraId, of: self)
    }
}
