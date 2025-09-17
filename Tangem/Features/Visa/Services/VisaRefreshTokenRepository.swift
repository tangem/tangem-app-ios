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
    private(set) var tokens: [VisaRefreshTokenId: String] = [:]

    private let secureStorage = SecureStorage()
    private let biometricsStorage = BiometricsStorage()

    func save(refreshToken: String, visaRefreshTokenId: VisaRefreshTokenId) throws {
        if tokens[visaRefreshTokenId] == refreshToken {
            return
        }

        tokens[visaRefreshTokenId] = refreshToken
        guard BiometricsUtil.isAvailable, AppSettings.shared.saveUserWallets else {
            return
        }

        let key = makeRefreshTokenStorageKey(visaRefreshTokenId: visaRefreshTokenId)
        var savedVisaRefreshTokenIds = loadStoredVisaRefreshTokenIds()
        if savedVisaRefreshTokenIds.contains(visaRefreshTokenId) {
            try biometricsStorage.delete(key)
        }

        guard let tokenData = refreshToken.data(using: .utf8) else {
            return
        }

        try biometricsStorage.store(tokenData, forKey: key)
        savedVisaRefreshTokenIds.insert(visaRefreshTokenId)

        storeVisaRefreshTokenIds(savedVisaRefreshTokenIds)
    }

    func deleteToken(visaRefreshTokenId: VisaRefreshTokenId) throws {
        tokens.removeValue(forKey: visaRefreshTokenId)

        guard BiometricsUtil.isAvailable else {
            return
        }

        var savedVisaRefreshTokenIds = loadStoredVisaRefreshTokenIds()
        guard savedVisaRefreshTokenIds.contains(visaRefreshTokenId) else {
            return
        }
        savedVisaRefreshTokenIds.remove(visaRefreshTokenId)

        let storageKey = makeRefreshTokenStorageKey(visaRefreshTokenId: visaRefreshTokenId)
        try biometricsStorage.delete(storageKey)

        storeVisaRefreshTokenIds(savedVisaRefreshTokenIds)
    }

    func clearPersistent() {
        do {
            let savedVisaRefreshTokenIds = loadStoredVisaRefreshTokenIds()
            storeVisaRefreshTokenIds([])
            for visaRefreshTokenId in savedVisaRefreshTokenIds {
                let storageKey = makeRefreshTokenStorageKey(visaRefreshTokenId: visaRefreshTokenId)
                try biometricsStorage.delete(storageKey)
            }
        } catch {
            VisaLogger.error("Failed to clear repository", error: error)
        }
    }

    func fetch(using context: LAContext) {
        do {
            var loadedTokens = [VisaRefreshTokenId: String]()
            for visaRefreshTokenId in loadStoredVisaRefreshTokenIds() {
                let key = makeRefreshTokenStorageKey(visaRefreshTokenId: visaRefreshTokenId)
                guard let refreshTokenData = try biometricsStorage.get(key, context: context) else {
                    continue
                }

                loadedTokens[visaRefreshTokenId] = String(data: refreshTokenData, encoding: .utf8)
            }

            tokens = loadedTokens
            storeVisaRefreshTokenIds(Set(loadedTokens.keys))
        } catch {
            VisaLogger.error("Failted to fetch token from storage", error: error)
        }
    }

    func lock() {
        tokens.removeAll()
        VisaLogger.info("Repository locked")
    }

    func getToken(forVisaRefreshTokenId visaRefreshTokenId: VisaRefreshTokenId) -> String? {
        return tokens[visaRefreshTokenId]
    }

    private func makeRefreshTokenStorageKey(visaRefreshTokenId: VisaRefreshTokenId) -> String {
        return "\(StorageKey.visaRefreshToken.rawValue)_\(visaRefreshTokenId.rawValue)"
    }

    private func loadStoredVisaRefreshTokenIds() -> Set<VisaRefreshTokenId> {
        do {
            guard let data = try secureStorage.get(StorageKey.visaRefreshTokenIds.rawValue) else {
                return []
            }

            let visaRefreshTokenIds = try JSONDecoder()
                .decode(Set<String>.self, from: data)
                .compactMap(VisaRefreshTokenId.init)

            return Set(visaRefreshTokenIds)
        } catch {
            VisaLogger.error("Failed to load and decode stored visa wallet ids", error: error)
            return []
        }
    }

    private func storeVisaRefreshTokenIds(_ visaRefreshTokenIds: Set<VisaRefreshTokenId>) {
        do {
            let setOfStrings = Set<String>(visaRefreshTokenIds.map(\.rawValue))
            let data = try JSONEncoder().encode(setOfStrings)
            try secureStorage.store(data, forKey: StorageKey.visaRefreshTokenIds.rawValue)
        } catch {
            VisaLogger.error("Failed to encode and store card ids", error: error)
        }
    }
}

extension CommonVisaRefreshTokenRepository {
    enum StorageKey: String {
        case visaRefreshTokenIds
        case visaRefreshToken
    }
}
