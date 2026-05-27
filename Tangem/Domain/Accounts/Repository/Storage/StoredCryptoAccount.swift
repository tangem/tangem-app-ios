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

    let derivationIndex: Int
    /// Nil, if the account uses a localized name.
    let name: String?
    let icon: Icon
    let tokens: [Token]
    let grouping: Grouping
    let sorting: Sorting
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
