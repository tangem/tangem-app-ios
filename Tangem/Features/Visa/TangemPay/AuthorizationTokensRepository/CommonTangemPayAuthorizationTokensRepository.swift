//
//  CommonTangemPayAuthorizationTokensRepository.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import LocalAuthentication
import TangemSdk
import TangemVisa

final class CommonTangemPayAuthorizationTokensRepository: TangemPayAuthorizationTokensRepository {
    private let secureStorage = SecureStorage()

    func save(tokens: TangemPayAuthorizationTokens, customerWalletId: String) throws {
        let key = makeAuthorizationTokensStorageKey(customerWalletId: customerWalletId)
        var savedCustomerWalletIds = loadStoredCustomerWalletIds()
        if savedCustomerWalletIds.contains(customerWalletId) {
            try secureStorage.delete(key)
        }

        let tokensData = try JSONEncoder().encode(tokens)

        try secureStorage.store(tokensData, forKey: key)
        savedCustomerWalletIds.insert(customerWalletId)

        storeCustomerWalletIds(savedCustomerWalletIds)
    }

    func deleteTokens(customerWalletId: String) throws {
        var savedCustomerWalletIds = loadStoredCustomerWalletIds()
        guard savedCustomerWalletIds.contains(customerWalletId) else {
            return
        }
        savedCustomerWalletIds.remove(customerWalletId)

        let storageKey = makeAuthorizationTokensStorageKey(customerWalletId: customerWalletId)
        try secureStorage.delete(storageKey)

        storeCustomerWalletIds(savedCustomerWalletIds)
    }

    func getToken(forCustomerWalletId customerWalletId: String) -> TangemPayAuthorizationTokens? {
        let key = makeAuthorizationTokensStorageKey(customerWalletId: customerWalletId)
        guard let tokensData = try? secureStorage.get(key),
              let tokens = try? JSONDecoder().decode(TangemPayAuthorizationTokens.self, from: tokensData)
        else {
            return nil
        }

        return tokens
    }

    private func makeAuthorizationTokensStorageKey(customerWalletId: String) -> String {
        "\(StorageKey.authorizationTokens.rawValue)_\(customerWalletId)"
    }

    private func loadStoredCustomerWalletIds() -> Set<String> {
        do {
            guard let data = try secureStorage.get(StorageKey.customerWalletIds.rawValue) else {
                return []
            }

            return try JSONDecoder().decode(Set<String>.self, from: data)
        } catch {
            return []
        }
    }

    private func storeCustomerWalletIds(_ customerWalletIds: Set<String>) {
        do {
            let data = try JSONEncoder().encode(customerWalletIds)
            try secureStorage.store(data, forKey: StorageKey.customerWalletIds.rawValue)
        } catch {
            VisaLogger.error("Failed to save to persistance", error: error)
        }
    }
}

extension CommonTangemPayAuthorizationTokensRepository {
    enum StorageKey: String {
        case customerWalletIds
        case authorizationTokens
    }
}
