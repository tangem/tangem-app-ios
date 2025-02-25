//
//  VisaRefreshTokenRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import LocalAuthentication
import TangemSdk
import TangemVisa

protocol VisaRefreshTokenRepository: VisaRefreshTokenSaver {
    func save(refreshToken: String, cardId: String) throws
    func deleteToken(cardId: String) throws
    /// - Parameters:
    ///  - cardIdTokenToKeep: this token will be saved after clearing secure and biometrics storages, but it will only persist in memory, not in storages
    func clear(cardIdTokenToKeep: String?)
    func fetch(using context: LAContext)
    func getToken(forCardId cardId: String) -> String?
    func lock()
}

extension VisaRefreshTokenRepository {
    func clear() {
        clear(cardIdTokenToKeep: nil)
    }
}

extension VisaRefreshTokenRepository {
    func saveRefreshTokenToStorage(refreshToken: String, cardId: String) throws {
        try save(refreshToken: refreshToken, cardId: cardId)
    }
}

private struct VisaRefreshTokenRepositoryKey: InjectionKey {
    static var currentValue: VisaRefreshTokenRepository = CommonVisaRefreshTokenRepository()
}

extension InjectedValues {
    var visaRefreshTokenRepository: VisaRefreshTokenRepository {
        get { Self[VisaRefreshTokenRepositoryKey.self] }
        set { Self[VisaRefreshTokenRepositoryKey.self] = newValue }
    }
}

class CommonVisaRefreshTokenRepository: VisaRefreshTokenRepository {
    private(set) var tokens: [String: String] = [:]

    private let secureStorage = SecureStorage()
    private let biometricsStorage = BiometricsStorage()
    private let logger = VisaAppLogger(tag: .refreshTokenRepository)

    func save(refreshToken: String, cardId: String) throws {
        if tokens[cardId] == refreshToken {
            return
        }

        tokens[cardId] = refreshToken
        guard BiometricsUtil.isAvailable, AppSettings.shared.saveUserWallets else {
            return
        }

        let key = makeRefreshTokenStorageKey(cardId: cardId)
        var savedCardIds = loadStoredCardIds()
        if savedCardIds.contains(cardId) {
            try biometricsStorage.delete(key)
        }

        guard let tokenData = refreshToken.data(using: .utf8) else {
            return
        }

        try biometricsStorage.store(tokenData, forKey: key)
        savedCardIds.insert(cardId)

        storeCardsIds(savedCardIds)
    }

    func deleteToken(cardId: String) throws {
        tokens.removeValue(forKey: cardId)

        guard BiometricsUtil.isAvailable else {
            return
        }

        var savedCardIds = loadStoredCardIds()
        guard savedCardIds.contains(cardId) else {
            return
        }
        savedCardIds.remove(cardId)

        let storageKey = makeRefreshTokenStorageKey(cardId: cardId)
        try biometricsStorage.delete(storageKey)

        storeCardsIds(savedCardIds)
    }

    func clear(cardIdTokenToKeep: String?) {
        do {
            var tokenToKeep: String?
            if let cardIdTokenToKeep {
                tokenToKeep = tokens[cardIdTokenToKeep]
            }
            let savedCardIds = loadStoredCardIds()
            tokens.removeAll()
            storeCardsIds([])
            for cardId in savedCardIds {
                let storageKey = makeRefreshTokenStorageKey(cardId: cardId)
                try biometricsStorage.delete(storageKey)
            }

            if let cardIdTokenToKeep, let tokenToKeep {
                try save(refreshToken: tokenToKeep, cardId: cardIdTokenToKeep)
            }
        } catch {
            logger.error("Failed to clear repository", error: error)
        }
    }

    func fetch(using context: LAContext) {
        do {
            var loadedTokens = [String: String]()
            for cardId in loadStoredCardIds() {
                let key = makeRefreshTokenStorageKey(cardId: cardId)
                guard let refreshTokenData = try biometricsStorage.get(key, context: context) else {
                    continue
                }

                loadedTokens[cardId] = String(data: refreshTokenData, encoding: .utf8)
            }

            tokens = loadedTokens
            storeCardsIds(Set(loadedTokens.keys))
        } catch {
            logger.error("Failted to fetch token from storage", error: error)
        }
    }

    func lock() {
        tokens.removeAll()
        logger.info("Repository locked")
    }

    func getToken(forCardId cardId: String) -> String? {
        return tokens[cardId]
    }

    private func makeRefreshTokenStorageKey(cardId: String) -> String {
        return "\(StorageKey.visaRefreshToken.rawValue)_\(cardId)"
    }

    private func loadStoredCardIds() -> Set<String> {
        do {
            guard let data = try secureStorage.get(StorageKey.visaCardIds.rawValue) else {
                return []
            }

            let cards = try JSONDecoder().decode(Set<String>.self, from: data)
            return cards
        } catch {
            logger.error("Failed to load and decode stored card ids", error: error)
            return []
        }
    }

    private func storeCardsIds(_ cardIds: Set<String>) {
        do {
            let data = try JSONEncoder().encode(cardIds)
            try secureStorage.store(data, forKey: StorageKey.visaCardIds.rawValue)
        } catch {
            logger.error("Failed to encode and store card ids", error: error)
        }
    }
}

extension CommonVisaRefreshTokenRepository {
    enum StorageKey: String {
        case visaCardIds
        case visaRefreshToken
    }
}
