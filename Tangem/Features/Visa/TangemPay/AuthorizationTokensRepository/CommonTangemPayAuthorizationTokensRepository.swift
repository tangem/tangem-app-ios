//
//  CommonTangemPayAuthorizationTokensRepository.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import LocalAuthentication
import TangemPay
import TangemSdk
import TangemVisa

final class CommonTangemPayAuthorizationTokensRepository: TangemPayAuthorizationTokensRepository {
    private(set) var tokens: [String: TangemPayAuthorizationTokens] = [:]

    private let secureStorage = SecureStorage()
    private let biometricsStorage = BiometricsStorage()

    func save(tokens: TangemPayAuthorizationTokens, customerWalletId: String) throws {
        if self.tokens[customerWalletId] == tokens {
            return
        }

        self.tokens[customerWalletId] = tokens
        guard BiometricsUtil.isAvailable, AppSettings.shared.saveUserWallets else {
            return
        }

        let key = makeAuthorizationTokensStorageKey(customerWalletId: customerWalletId)
        var savedCustomerWalletIds = loadStoredCustomerWalletIds()
        if savedCustomerWalletIds.contains(customerWalletId) {
            try biometricsStorage.delete(key)
        }

        let tokensData = try JSONEncoder().encode(tokens)

        try biometricsStorage.store(tokensData, forKey: key)
        savedCustomerWalletIds.insert(customerWalletId)

        storeCustomerWalletIds(savedCustomerWalletIds)
    }

    func deleteTokens(customerWalletId: String) throws {
        tokens.removeValue(forKey: customerWalletId)

        guard BiometricsUtil.isAvailable else {
            return
        }

        var savedCustomerWalletIds = loadStoredCustomerWalletIds()
        guard savedCustomerWalletIds.contains(customerWalletId) else {
            return
        }
        savedCustomerWalletIds.remove(customerWalletId)

        let storageKey = makeAuthorizationTokensStorageKey(customerWalletId: customerWalletId)
        try biometricsStorage.delete(storageKey)

        storeCustomerWalletIds(savedCustomerWalletIds)
    }

    func clearPersistent() {
        do {
            let savedCustomerWalletIds = loadStoredCustomerWalletIds()
            storeCustomerWalletIds([])
            for customerWalletId in savedCustomerWalletIds {
                let storageKey = makeAuthorizationTokensStorageKey(customerWalletId: customerWalletId)
                try biometricsStorage.delete(storageKey)
            }
        } catch {
            VisaLogger.error("Failed to clear persistence", error: error)
        }
    }

    func fetch(using context: LAContext) {
        do {
            var loadedTokens = [String: TangemPayAuthorizationTokens]()
            for customerWalletId in loadStoredCustomerWalletIds() {
                let key = makeAuthorizationTokensStorageKey(customerWalletId: customerWalletId)
                guard let tokensData = try biometricsStorage.get(key, context: context) else {
                    continue
                }

                loadedTokens[customerWalletId] = try JSONDecoder().decode(TangemPayAuthorizationTokens.self, from: tokensData)
            }

            tokens = loadedTokens
            storeCustomerWalletIds(Set(loadedTokens.keys))
        } catch {
            VisaLogger.error("Failed to load from persistence", error: error)
        }
    }

    func getToken(forCustomerWalletId customerWalletId: String) -> TangemPayAuthorizationTokens? {
        tokens[customerWalletId]
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
