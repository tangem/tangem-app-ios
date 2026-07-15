//
//  UserDefaultsTransactionHistoryAuxDataStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExpress

// [REDACTED_TODO_COMMENT]
struct UserDefaultsTransactionHistoryAuxDataStorage {
    /// - Note: Despite the name of the type, this inner storage is not limited to BlockchainSDK. It's just a convenient UserDefaults wrapper.
    private let dataStorage: BlockchainDataStorage

    var expressProviders: [ExpressProvider] {
        get {
            let dtos: [ProviderDTO]? = dataStorage.get(key: StorageKey.expressProviders.rawValue)

            return dtos?.map(\.asDomainEntity) ?? []
        }
        nonmutating set {
            dataStorage.store(
                key: StorageKey.expressProviders.rawValue,
                value: newValue.map(ProviderDTO.init(from:))
            )
        }
    }

    var onrampProviders: [ExpressProvider] {
        get {
            let dtos: [ProviderDTO]? = dataStorage.get(key: StorageKey.onrampProviders.rawValue)

            return dtos?.map(\.asDomainEntity) ?? []
        }
        nonmutating set {
            dataStorage.store(
                key: StorageKey.onrampProviders.rawValue,
                value: newValue.map(ProviderDTO.init(from:))
            )
        }
    }

    var fiatCurrencies: [OnrampFiatCurrency] {
        get {
            let dtos: [FiatCurrencyDTO]? = dataStorage.get(key: StorageKey.currencies.rawValue)

            return dtos?.map(\.asDomainEntity) ?? []
        }
        nonmutating set {
            dataStorage.store(
                key: StorageKey.currencies.rawValue,
                value: newValue.map(FiatCurrencyDTO.init(from:))
            )
        }
    }

    var cryptoCurrencies: [String: TokenItem] {
        get {
            let cryptoCurrencies: [String: TokenItem]? = dataStorage.get(key: StorageKey.cryptoCurrencies.rawValue)

            return cryptoCurrencies ?? [:]
        }
        nonmutating set {
            dataStorage.store(
                key: StorageKey.cryptoCurrencies.rawValue,
                value: newValue
            )
        }
    }

    init(dataStorage: BlockchainDataStorage) {
        self.dataStorage = dataStorage
    }
}

// MARK: - Storage keys

private extension UserDefaultsTransactionHistoryAuxDataStorage {
    enum StorageKey: String {
        case expressProviders = "TxHistoryAuxData_expressProviders_v1"
        case onrampProviders = "TxHistoryAuxData_onrampProviders_v1"
        case currencies = "TxHistoryAuxData_currencies_v1"
        case cryptoCurrencies = "TxHistoryAuxData_cryptoCurrencies_v1"
    }
}

// MARK: - DTOs

private struct ProviderDTO: Codable {
    let id: String
    let name: String
    let type: String
    let exchangeOnlyWithinSingleAddress: Bool
    let imageURL: URL?
    let termsOfUse: URL?
    let privacyPolicy: URL?
    let recommended: Bool?
    let slippage: Decimal?

    init(from provider: ExpressProvider) {
        id = provider.id
        name = provider.name
        type = provider.type.rawValue
        exchangeOnlyWithinSingleAddress = provider.exchangeOnlyWithinSingleAddress
        imageURL = provider.imageURL
        termsOfUse = provider.termsOfUse
        privacyPolicy = provider.privacyPolicy
        recommended = provider.recommended
        slippage = provider.slippage
    }

    var asDomainEntity: ExpressProvider {
        return ExpressProvider(
            id: id,
            name: name,
            type: ExpressProviderType(rawValue: type) ?? .unknown,
            exchangeOnlyWithinSingleAddress: exchangeOnlyWithinSingleAddress,
            imageURL: imageURL,
            termsOfUse: termsOfUse,
            privacyPolicy: privacyPolicy,
            recommended: recommended,
            slippage: slippage
        )
    }
}

private struct FiatCurrencyDTO: Codable {
    let name: String
    let code: String
    let image: URL?
    let precision: Int

    init(from currency: OnrampFiatCurrency) {
        name = currency.identity.name
        code = currency.identity.code
        image = currency.identity.image
        precision = currency.precision
    }

    var asDomainEntity: OnrampFiatCurrency {
        return OnrampFiatCurrency(
            identity: OnrampIdentity(name: name, code: code, image: image),
            precision: precision
        )
    }
}
