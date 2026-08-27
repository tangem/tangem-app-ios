//
//  StoredCryptoAccount.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import enum BlockchainSdk.Blockchain
import struct TangemSdk.DerivationPath

struct StoredCryptoAccount: Codable, Equatable {
    enum Grouping: Codable, Equatable {
        case none
        case byBlockchainNetwork
    }

    enum Sorting: Codable, Equatable {
        case manual
        case byBalance
    }

    struct Icon: Codable, Equatable {
        let iconName: String
        let iconColor: String
    }

    var derivationIdentity: CryptoAccountDerivationIdentity {
        CryptoAccountDerivationIdentity(derivationIndex: derivationIndex, type: type)
    }

    /// Nil, if the account uses a localized name.
    let name: String?
    let icon: Icon
    let tokens: [Token]
    let grouping: Grouping
    let sorting: Sorting

    private let derivationIndex: Int
    private let type: AccountType

    init(
        derivationIndex: Int,
        type: AccountType,
        name: String?,
        icon: Icon,
        tokens: [Token],
        grouping: Grouping,
        sorting: Sorting
    ) {
        self.derivationIndex = derivationIndex
        self.type = type
        self.name = name
        self.icon = icon
        self.tokens = tokens
        self.grouping = grouping
        self.sorting = sorting
    }
}

// MARK: - Inner types

extension StoredCryptoAccount {
    /// Similar to the `StoredUserTokenList.Entry` model.
    struct Token: Codable, Hashable {
        /// Container type, preserves currently unknown/unsupported to the client networks.
        enum BlockchainNetworkContainer: Codable, Hashable {
            case known(blockchainNetwork: StoredBlockchainNetwork)
            case unknown(networkId: String, rawDerivationPath: String?)
        }

        /// Storage-layer of `BlockchainNetwork`. Distinct from `BlockchainNetwork`
        /// because `Equatable`/`Hashable` here include `settings` — storage compares by
        /// full record identity, while the domain type ignores `settings`.
        struct StoredBlockchainNetwork: Codable, Hashable {
            let blockchain: Blockchain
            let derivationPath: DerivationPath?
            let settings: BlockchainSettings?
        }

        let id: String?
        let name: String
        let symbol: String
        let decimalCount: Int
        let blockchainNetwork: BlockchainNetworkContainer
        let contractAddress: String?
    }
}

// MARK: - Codable protocol conformance

extension StoredCryptoAccount {
    /// Everything written before the kinds existed was one of the wallet's own accounts, so a record that does not name
    /// its kind is a crypto one rather than an unreadable one.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decodeIfPresent(AccountType.self, forKey: .type) ?? .crypto

        try self.init(
            derivationIndex: container.decode(Int.self, forKey: .derivationIndex),
            type: type,
            name: container.decodeIfPresent(String.self, forKey: .name),
            icon: container.decode(Icon.self, forKey: .icon),
            tokens: container.decode([Token].self, forKey: .tokens),
            grouping: container.decode(Grouping.self, forKey: .grouping),
            sorting: container.decode(Sorting.self, forKey: .sorting)
        )
    }
}
