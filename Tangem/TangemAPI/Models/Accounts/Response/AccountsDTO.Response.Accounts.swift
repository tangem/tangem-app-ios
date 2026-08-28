//
//  AccountsDTO.Response.Accounts.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension AccountsDTO.Response {
    struct Accounts: Decodable {
        /// - Warning: Which counters the answer must carry follows which endpoint was asked, and the joint accounts
        /// feature is what decides the endpoint — see the `Decodable` conformance below.
        struct Wallet {
            /// - Note: This field may be nil in cases where a new wallet is created by [REDACTED_AUTHOR]
            /// and the PUT request `/user-tokens` has not been sent yet.
            let version: Int?
            /// - Note: This field may be nil in cases where a new wallet is created by [REDACTED_AUTHOR]
            /// and the PUT request `/user-tokens` has not been sent yet.
            let group: AccountsDTO.GroupType?
            /// - Note: This field may be nil in cases where a new wallet is created by [REDACTED_AUTHOR]
            /// and the PUT request `/user-tokens` has not been sent yet.
            let sort: AccountsDTO.SortType?
            let totalArchivedAccounts: Int
            /// - Note: Filled from the whole total while the endpoint counts the kinds of account together: every
            /// account that total counts is a crypto one. Once the kinds are counted apart, it is a count of its own.
            let totalCryptoAccounts: Int
            /// - Note: Absent while the endpoint counts the kinds of account together — no count of joint ones exists yet.
            let totalJointAccounts: Int?
        }

        struct Token: Codable, Hashable {
            let id: String?
            let networkId: String
            let name: String
            let symbol: String
            let decimals: Int
            let derivationPath: String?
            let contractAddress: String?
            let dynamicAddressesEnabled: Bool?
        }

        struct Account: Decodable {
            let id: String
            /// Nil, if the account uses a localized name.
            let name: String?
            let icon: String
            let iconColor: String
            let derivation: Int
            let type: String?
            let tokens: [Token]
        }

        let wallet: Wallet
        let accounts: [Account]
        let unassignedTokens: [Token]
    }
}

// MARK: - Decodable protocol conformance

extension AccountsDTO.Response.Accounts.Wallet: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        version = try container.decodeIfPresent(Int.self, forKey: .version)
        group = try container.decodeIfPresent(AccountsDTO.GroupType.self, forKey: .group)
        sort = try container.decodeIfPresent(AccountsDTO.SortType.self, forKey: .sort)
        totalArchivedAccounts = try container.decode(Int.self, forKey: .totalArchivedAccounts)

        if FeatureProvider.isAvailable(.jointAccounts) {
            totalCryptoAccounts = try container.decode(Int.self, forKey: .totalCryptoAccounts)
            totalJointAccounts = try container.decode(Int.self, forKey: .totalJointAccounts)
        } else {
            totalCryptoAccounts = try container.decode(Int.self, forKey: .totalAccounts)
            totalJointAccounts = nil
        }
    }
}

// MARK: - Auxiliary types

private extension AccountsDTO.Response.Accounts.Wallet {
    enum CodingKeys: String, CodingKey {
        case version
        case group
        case sort
        case totalAccounts
        case totalArchivedAccounts
        case totalCryptoAccounts
        case totalJointAccounts
    }
}
