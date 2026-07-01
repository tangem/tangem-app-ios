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
struct UserDefaultsTransactionHistoryAuxDataStorage {
    private let suiteName: String?
    private var userDefaults: UserDefaults { UserDefaults(suiteName: suiteName) ?? .standard }

    init(suiteName: String?) {
        self.suiteName = suiteName
    }

    var providers: [ExpressProvider] {
        get { decode([ProviderDTO].self, forKey: .providers)?.map(\.asDomain) ?? [] }
        nonmutating set { encode(newValue.map(ProviderDTO.init(from:)), forKey: .providers) }
    }

    var fiatCurrencies: [OnrampFiatCurrency] {
        get { decode([FiatCurrencyDTO].self, forKey: .currencies)?.map(\.asDomain) ?? [] }
        nonmutating set { encode(newValue.map(FiatCurrencyDTO.init(from:)), forKey: .currencies) }
    }

    var coins: [String: CoinsList.Coin] {
        get { decode([String: CoinsList.Coin].self, forKey: .coins) ?? [:] }
        nonmutating set { encode(newValue, forKey: .coins) }
    }
}

// MARK: - Coding helpers

private extension UserDefaultsTransactionHistoryAuxDataStorage {
    enum StorageKey: String {
        case providers = "TxHistoryAuxData_providers_v1"
        case currencies = "TxHistoryAuxData_currencies_v1"
        case coins = "TxHistoryAuxData_coins_v1"
    }

    func decode<T: Decodable>(_ type: T.Type, forKey key: StorageKey) -> T? {
        guard let data = userDefaults.data(forKey: key.rawValue) else {
            return nil
        }

        return try? JSONDecoder().decode(type, from: data)
    }

    func encode<T: Encodable>(_ value: T, forKey key: StorageKey) {
        guard let data = try? JSONEncoder().encode(value) else {
            return
        }

        userDefaults.set(data, forKey: key.rawValue)
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
