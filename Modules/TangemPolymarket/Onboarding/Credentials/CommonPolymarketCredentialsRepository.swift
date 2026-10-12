//
//  CommonPolymarketCredentialsRepository.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemSdk

public final class CommonPolymarketCredentialsRepository {
    private let secureStorage = SecureStorage()
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init() {}
}

// MARK: - PolymarketCredentialsRepository protocol conformance

extension CommonPolymarketCredentialsRepository: PolymarketCredentialsRepository {
    public func save(credentials: PolymarketL2Credentials, userWalletId: UserWalletId) throws {
        let data = try encoder.encode(StoredCredentials(credentials: credentials))
        try secureStorage.store(data, forKey: makeKey(userWalletId: userWalletId))
    }

    public func load(userWalletId: UserWalletId) -> PolymarketL2Credentials? {
        let key = makeKey(userWalletId: userWalletId)

        do {
            guard let data = try secureStorage.get(key) else {
                return nil
            }

            return try decoder.decode(StoredCredentials.self, from: data).credentials
        } catch let error as DecodingError {
            PolymarketLogger.error("Dropping credentials that cannot be decoded", error: error)
            try? secureStorage.delete(key)
            return nil
        } catch {
            PolymarketLogger.error("Failed to read the stored credentials", error: error)
            return nil
        }
    }

    public func delete(userWalletId: UserWalletId) {
        do {
            try secureStorage.delete(makeKey(userWalletId: userWalletId))
        } catch {
            PolymarketLogger.error("Failed to delete the stored credentials", error: error)
        }
    }

    public func clean(genericPasswordAccounts: [String]) {
        for account in genericPasswordAccounts where account.hasPrefix(Constants.keyPrefix) {
            do {
                try secureStorage.delete(account)
            } catch {
                PolymarketLogger.error("Failed to delete the stored credentials", error: error)
            }
        }
    }
}

// MARK: - Private implementation

private extension CommonPolymarketCredentialsRepository {
    func makeKey(userWalletId: UserWalletId) -> String {
        Constants.keyPrefix + userWalletId.stringValue
    }

    enum Constants {
        static let keyPrefix = "polymarket_l2_credentials_"
    }

    struct StoredCredentials: Codable {
        let apiKey, secret, passphrase: String

        init(credentials: PolymarketL2Credentials) {
            apiKey = credentials.apiKey
            secret = credentials.secret
            passphrase = credentials.passphrase
        }

        var credentials: PolymarketL2Credentials {
            PolymarketL2Credentials(apiKey: apiKey, secret: secret, passphrase: passphrase)
        }
    }
}
