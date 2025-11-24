//
//  StoredCryptoAccount.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct StoredCryptoAccount: Codable, Equatable {
    // [REDACTED_TODO_COMMENT]
    typealias Grouping = StoredUserTokenList.Grouping

    // [REDACTED_TODO_COMMENT]
    typealias Sorting = StoredUserTokenList.Sorting

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
            case known(blockchainNetwork: BlockchainNetwork)
            case unknown(networkId: String, rawDerivationPath: String?)
        }

        let id: String?
        let name: String
        let symbol: String
        let decimalCount: Int
        let blockchainNetwork: BlockchainNetworkContainer
        let contractAddress: String?
    }
}
