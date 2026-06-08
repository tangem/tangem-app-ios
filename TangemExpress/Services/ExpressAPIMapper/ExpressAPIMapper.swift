//
//  ExpressAPIMapper.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

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
                .compactMap { ExpressProviderRateType(rawValue: $0.rawValue) }

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
            type: provider.type ?? .unknown,
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
            externalTxURL: txDetails.externalTxUrl.flatMap(URL.init(string:))
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

    func mapToExpressTransaction(response: ExpressDTO.Swap.ExchangeStatus.Response) -> ExpressTransaction {
        ExpressTransaction(
            providerId: .init(response.providerId),
            externalStatus: ExpressTransactionStatus(rawValue: response.status) ?? .unknown,
            refundedCurrency: mapToRefundedExpressCurrency(response: response),
            externalTxId: response.externalTxId,
            externalTxURL: response.externalTxUrl.flatMap(URL.init(string:)),
            averageDuration: response.averageDuration,
            createdAt: response.createdAt
        )
    }

    private func mapToRefundedExpressCurrency(response: ExpressDTO.Swap.ExchangeStatus.Response) -> ExpressCurrency? {
        guard let refundContractAddress = response.refundContractAddress,
              let refundNetwork = response.refundNetwork else {
            return nil
        }

        return ExpressCurrency(contractAddress: refundContractAddress, network: refundNetwork)
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
            externalTxId: codedData.externalTxId,
            externalTxURL: codedData.externalTxUrl.flatMap(URL.init(string:))
        )
    }

    func mapToOnrampTransaction(response: ExpressDTO.Onramp.Status.Response) throws -> OnrampTransaction {
        guard var fromAmount = Decimal(stringValue: response.fromAmount) else {
            throw ExpressAPIMapperError.mapToDecimalError(response.fromAmount)
        }

        fromAmount /= pow(10, response.fromPrecision)

        let toAmount = response.toAmount
            .flatMap { Decimal(stringValue: $0) }
            .map { $0 / pow(10, response.toDecimals) }

        return OnrampTransaction(
            fromAmount: fromAmount,
            toAmount: toAmount,
            status: OnrampTransactionStatus(rawValue: response.status) ?? .unknown,
            externalTxId: response.externalTxId,
            externalTxURL: response.externalTxUrl.flatMap(URL.init(string:))
        )
    }

    // MARK: - History

    func mapToExchangeHistoryPage(response: ExpressDTO.Swap.History.Response) throws -> ExchangeHistoryPage {
        let records = try response.data.map(mapToExchangeHistoryRecord(record:))

        return ExchangeHistoryPage(
            records: records,
            nextCursor: response.nextCursor.value,
            hasMore: response.hasMore
        )
    }

    func mapToOnrampHistoryPage(response: ExpressDTO.Onramp.History.Response) throws -> OnrampHistoryPage {
        let records = try response.data.map(mapToOnrampHistoryRecord(record:))

        return OnrampHistoryPage(
            records: records,
            nextCursor: response.nextCursor.value,
            hasMore: response.hasMore
        )
    }

    private func mapToExchangeHistoryRecord(record: ExpressDTO.Swap.History.Record) throws -> ExchangeHistoryRecord {
        try ExchangeHistoryRecord(
            txId: record.txId,
            status: record.status,
            provider: mapToExpressHistoryProvider(provider: record.provider),
            from: mapToExchangeHistoryAsset(asset: record.from),
            to: mapToExchangeHistoryAsset(asset: record.to),
            payinHash: record.payinHash,
            payoutHash: record.payoutHash,
            externalTxId: record.externalTxId,
            externalTxURL: record.externalTxUrl.flatMap(URL.init(string:)),
            refund: record.refund.map(mapToExpressHistoryRefund(refund:)),
            rateType: record.rateType,
            createdAt: record.createdAt,
            updatedAt: record.updatedAt
        )
    }

    private func mapToOnrampHistoryRecord(record: ExpressDTO.Onramp.History.Record) throws -> OnrampHistoryRecord {
        try OnrampHistoryRecord(
            txId: record.txId,
            status: record.status,
            provider: mapToExpressHistoryProvider(provider: record.provider),
            from: mapToOnrampHistoryFiatAsset(asset: record.from),
            to: mapToOnrampHistoryAsset(asset: record.to),
            payoutHash: record.payoutHash,
            externalTxId: record.externalTxId,
            externalTxURL: record.externalTxUrl.flatMap(URL.init(string:)),
            refund: record.refund.map(mapToOnrampHistoryRefund(refund:)),
            rate: record.rate.map(mapToOnrampHistoryRate(rate:)),
            failReason: record.failReason,
            createdAt: record.createdAt,
            updatedAt: record.updatedAt
        )
    }

    private func mapToExpressHistoryProvider(provider: ExpressDTO.HistoryProvider) -> ExpressHistoryProvider {
        ExpressHistoryProvider(
            id: provider.id,
            name: provider.name,
            iconURL: URL(string: provider.iconUrl),
            providerURL: URL(string: provider.providerUrl)
        )
    }

    private func mapToExchangeHistoryAsset(asset: ExpressDTO.Swap.History.AssetRef) throws -> ExchangeHistoryAsset {
        guard let raw = Decimal(stringValue: asset.rawAmount) else {
            throw ExpressAPIMapperError.mapToDecimalError(asset.rawAmount)
        }

        let amount = raw / pow(10, asset.decimals)

        return ExchangeHistoryAsset(
            network: asset.network,
            tokenId: asset.tokenId,
            amount: amount,
            decimals: asset.decimals,
            isActual: asset.isActual
        )
    }

    private func mapToExpressHistoryRefund(refund: ExpressDTO.Swap.History.Refund) throws -> ExpressHistoryRefund {
        guard let raw = Decimal(stringValue: refund.rawAmount) else {
            throw ExpressAPIMapperError.mapToDecimalError(refund.rawAmount)
        }

        let amount = raw / pow(10, refund.decimals)

        return ExpressHistoryRefund(
            network: refund.network,
            tokenId: refund.tokenId,
            amount: amount,
            decimals: refund.decimals,
            hash: refund.hash
        )
    }

    private func mapToOnrampHistoryFiatAsset(asset: ExpressDTO.Onramp.History.FiatAsset) throws -> OnrampHistoryFiatAsset {
        guard let amount = Decimal(stringValue: asset.amount) else {
            throw ExpressAPIMapperError.mapToDecimalError(asset.amount)
        }

        return OnrampHistoryFiatAsset(currencyCode: asset.currencyCode, amount: amount)
    }

    private func mapToOnrampHistoryAsset(asset: ExpressDTO.Onramp.History.AssetRef) throws -> OnrampHistoryAsset {
        guard let expectedRaw = Decimal(stringValue: asset.expectedRawAmount) else {
            throw ExpressAPIMapperError.mapToDecimalError(asset.expectedRawAmount)
        }

        let expected = expectedRaw / pow(10, asset.decimals)

        let actual: Decimal? = try asset.actualRawAmount.map { amount in
            guard let raw = Decimal(stringValue: amount) else {
                throw ExpressAPIMapperError.mapToDecimalError(amount)
            }

            return raw / pow(10, asset.decimals)
        }

        return OnrampHistoryAsset(
            network: asset.network,
            tokenId: asset.tokenId,
            expectedAmount: expected,
            actualAmount: actual,
            decimals: asset.decimals
        )
    }

    private func mapToOnrampHistoryRefund(refund: ExpressDTO.Onramp.History.Refund) throws -> ExpressHistoryRefund {
        guard let raw = Decimal(stringValue: refund.rawAmount) else {
            throw ExpressAPIMapperError.mapToDecimalError(refund.rawAmount)
        }

        let amount = raw / pow(10, refund.decimals)

        return ExpressHistoryRefund(
            network: refund.network,
            tokenId: refund.tokenId,
            amount: amount,
            decimals: refund.decimals,
            hash: refund.hash
        )
    }

    private func mapToOnrampHistoryRate(rate: ExpressDTO.Onramp.History.Rate) -> OnrampHistoryRate {
        OnrampHistoryRate(
            atCreate: rate.atCreate.flatMap { Decimal(stringValue: $0) },
            atFinish: rate.atFinish.flatMap { Decimal(stringValue: $0) }
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
