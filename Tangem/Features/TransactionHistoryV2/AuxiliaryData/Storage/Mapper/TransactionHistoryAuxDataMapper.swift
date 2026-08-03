//
//  TransactionHistoryAuxDataMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExpress
import TangemFoundation
import TangemAppDatabase

/// Maps transaction history auxiliary data between domain entities and their database records.
enum TransactionHistoryAuxDataMapper {
    /// - Note: `Blockchain.allMainnetCases` is fine here because this is a responsibility of a consumer of the storage
    /// to provide only supported networks.
    private static let blockchainsKeyedByNetworkID = Blockchain.allMainnetCases.keyedFirst(by: \.networkId)

    // MARK: Express providers

    static func mapToExpressProviderType(fromString string: String) throws -> ExpressProviderType {
        if let providerType = ExpressProviderType(rawValue: string) {
            return providerType
        }

        throw "Failed to create Express provider type from string: \(string)"
    }

    static func mapToExpressProvider(_ record: ExpressProviderRecord, providerType: ExpressProviderType) throws -> ExpressProvider {
        return ExpressProvider(
            id: record.id,
            name: record.name,
            type: providerType,
            exchangeOnlyWithinSingleAddress: record.exchangeOnlyWithinSingleAddress,
            imageURL: try url(fromString: record.imageURL),
            termsOfUse: try url(fromString: record.termsOfUse),
            privacyPolicy: try url(fromString: record.privacyPolicy),
            recommended: record.recommended,
            slippage: try decimal(fromString: record.slippage)
        )
    }

    static func mapToExpressProviderRecord(_ provider: ExpressProvider, updatedAt: Date) -> ExpressProviderRecord {
        return ExpressProviderRecord(
            id: provider.id,
            name: provider.name,
            type: provider.type.rawValue,
            exchangeOnlyWithinSingleAddress: provider.exchangeOnlyWithinSingleAddress,
            imageURL: provider.imageURL?.absoluteString,
            termsOfUse: provider.termsOfUse?.absoluteString,
            privacyPolicy: provider.privacyPolicy?.absoluteString,
            recommended: provider.recommended,
            slippage: provider.slippage?.stringValue,
            updatedAt: updatedAt
        )
    }

    // MARK: Fiat currencies

    static func mapToOnrampFiatCurrency(_ record: FiatCurrencyRecord) throws -> OnrampFiatCurrency {
        let identity = OnrampIdentity(
            name: record.name,
            code: record.code,
            image: try url(fromString: record.imageURL)
        )

        return OnrampFiatCurrency(
            identity: identity,
            precision: record.precision
        )
    }

    static func mapToFiatCurrencyRecord(_ currency: OnrampFiatCurrency, updatedAt: Date) -> FiatCurrencyRecord {
        return FiatCurrencyRecord(
            code: currency.identity.code,
            name: currency.identity.name,
            imageURL: currency.identity.image?.absoluteString,
            precision: currency.precision,
            updatedAt: updatedAt
        )
    }

    // MARK: Crypto currencies

    static func mapToTokenItem(_ record: CryptoCurrencyRecord) throws -> TokenItem {
        guard let blockchain = blockchainsKeyedByNetworkID[record.networkID] else {
            throw "Unknown/unsupported blockchain with network id: \(record.networkID)"
        }

        let blockchainNetwork = BlockchainNetwork(blockchain, derivationPath: nil)

        // `ExpressConstants.coinContractAddress` is used as a sentinel value to indicate that the asset is a native coin
        guard record.contractAddress != ExpressConstants.coinContractAddress else {
            return .blockchain(blockchainNetwork)
        }

        return .token(
            .init(
                name: record.name,
                symbol: record.symbol,
                contractAddress: record.contractAddress,
                decimalCount: record.decimalCount,
                id: record.id,
                metadata: .fungibleTokenMetadata // No caching for NFT tokens yet
            ),
            blockchainNetwork
        )
    }

    static func mapToCryptoCurrencyRecord(_ tokenItem: TokenItem, updatedAt: Date) throws -> CryptoCurrencyRecord {
        if let kind = tokenItem.token?.metadata.kind, case .nonFungible = kind {
            throw "Caching of non-fungible token \(tokenItem.name) (\(tokenItem.networkId)) is not supported"
        }

        return CryptoCurrencyRecord(
            id: tokenItem.token?.id,
            networkID: tokenItem.networkId,
            name: tokenItem.name,
            symbol: tokenItem.currencySymbol,
            // `ExpressConstants.coinContractAddress` is used as a sentinel value to indicate that the asset is a native coin
            contractAddress: tokenItem.token?.contractAddress ?? ExpressConstants.coinContractAddress,
            decimalCount: tokenItem.decimalCount,
            updatedAt: updatedAt
        )
    }

    // MARK: - Shared helpers

    private static func url(fromString string: String?) throws -> URL? {
        guard let urlString = string?.nilIfEmpty else {
            return nil // nil and empty strings are valid values
        }

        if let url = URL(string: urlString) {
            return url
        }

        throw "Failed to create URL from string: \(urlString)"
    }

    private static func decimal(fromString string: String?) throws -> Decimal? {
        guard let decimalString = string?.nilIfEmpty else {
            return nil // nil and empty strings are valid values
        }

        if let decimal = Decimal(stringValue: decimalString) {
            return decimal
        }

        throw "Failed to create Decimal from string: \(decimalString)"
    }
}
