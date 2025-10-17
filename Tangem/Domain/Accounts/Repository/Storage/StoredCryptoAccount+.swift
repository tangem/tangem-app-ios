//
//  StoredCryptoAccount+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import struct BlockchainSdk.Token

// MARK: - Convenience extensions

extension StoredCryptoAccount.Token {
    var isToken: Bool { contractAddress != nil }

    // [REDACTED_TODO_COMMENT]
    var coinId: String? {
        switch blockchainNetwork {
        case .known(let blockchainNetwork):
            return contractAddress == nil ? blockchainNetwork.blockchain.coinId : id
        case .unknown:
            return nil
        }
    }

    var walletModelId: WalletModelId? {
        guard let blockchainNetwork = blockchainNetwork.knownValue else {
            return nil
        }

        if let token = toBSDKToken() {
            return WalletModelId(tokenItem: .token(token, blockchainNetwork))
        }

        return WalletModelId(tokenItem: .blockchain(blockchainNetwork))
    }

    func toBSDKToken() -> Token? {
        guard let contractAddress else {
            return nil
        }

        return Token(
            name: name,
            symbol: symbol,
            contractAddress: contractAddress,
            decimalCount: decimalCount,
            id: id,
            metadata: .fungibleTokenMetadata // By definition, in the domain layer we're dealing only with fungible tokens
        )
    }
}

extension StoredCryptoAccount.Token.BlockchainNetworkContainer {
    /// `known` means that the blockchain network is known and supported by current client version.
    var knownValue: BlockchainNetwork? {
        switch self {
        case .known(let blockchainNetwork):
            return blockchainNetwork
        case .unknown:
            return nil
        }
    }
}
