//
//  UserDefaultsTransactionHistoryAuxDataStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

// [REDACTED_TODO_COMMENT]
final class UserDefaultsTransactionHistoryAuxDataStorage {
    @AppStorageCompat<StorageKey, Data?>
    private var providersBlob: Data?

    @AppStorageCompat<StorageKey, Data?>
    private var currenciesBlob: Data?

    @AppStorageCompat<StorageKey, Data?>
    private var coinsBlob: Data?

    init() {
        _providersBlob = .init(wrappedValue: nil, .providers)
        _currenciesBlob = .init(wrappedValue: nil, .currencies)
        _coinsBlob = .init(wrappedValue: nil, .coins)
    }

    var providers: [ExpressProvider] {
        get { Self.decode([ProviderDTO].self, from: providersBlob)?.map(\.asDomain) ?? [] }
        set { providersBlob = Self.encode(newValue.map(ProviderDTO.init(from:))) }
    }

    var fiatCurrencies: [OnrampFiatCurrency] {
        get { Self.decode([FiatCurrencyDTO].self, from: currenciesBlob)?.map(\.asDomain) ?? [] }
        set { currenciesBlob = Self.encode(newValue.map(FiatCurrencyDTO.init(from:))) }
    }

    var coins: [String: CoinsList.Coin] {
        get { Self.decode([String: CoinsList.Coin].self, from: coinsBlob) ?? [:] }
        set { coinsBlob = Self.encode(newValue) }
    }
}

// MARK: - Coding helpers

private extension UserDefaultsTransactionHistoryAuxDataStorage {
    enum StorageKey: String {
        case providers = "TxHistoryAuxData_providers_v1"
        case currencies = "TxHistoryAuxData_currencies_v1"
        case coins = "TxHistoryAuxData_coins_v1"
    }

    static func encode<T: Encodable>(_ value: T) -> Data? {
        return try? JSONEncoder().encode(value)
    }

    static func decode<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
        return data.flatMap { try? JSONDecoder().decode(type, from: $0) }
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

    var asDomain: ExpressProvider {
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

    var asDomain: OnrampFiatCurrency {
        return OnrampFiatCurrency(
            identity: OnrampIdentity(name: name, code: code, image: image),
            precision: precision
        )
    }
}
