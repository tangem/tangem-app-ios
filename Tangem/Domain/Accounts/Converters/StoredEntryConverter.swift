//
//  StoredEntryConverter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import struct BlockchainSdk.Token

enum StoredEntryConverter {
    static func convertToStoredEntry(_ tokenItem: TokenItem) -> StoredCryptoAccount.Token {
        return .init(
            id: tokenItem.id,
            name: tokenItem.name,
            symbol: tokenItem.currencySymbol,
            decimalCount: tokenItem.decimalCount,
            // By definition, all token domain entities are known
            blockchainNetwork: .known(
                blockchainNetwork: convertToStoredBlockchainNetwork(tokenItem.blockchainNetwork)
            ),
            contractAddress: tokenItem.contractAddress
        )
    }

    static func convertToTokenItem(_ storedEntry: StoredCryptoAccount.Token) -> TokenItem? {
        guard let storedBlockchainNetwork = storedEntry.blockchainNetwork.knownValue else {
            return nil
        }

        let blockchainNetwork = convertToBlockchainNetwork(storedBlockchainNetwork)

        guard let bsdkToken = storedEntry.toBSDKToken() else {
            return .blockchain(blockchainNetwork)
        }

        return .token(bsdkToken, blockchainNetwork)
    }

    static func convertToBSDKToken(_ storedEntry: StoredCryptoAccount.Token) -> BlockchainSdk.Token? {
        guard let contractAddress = storedEntry.contractAddress else {
            return nil
        }

        return BlockchainSdk.Token(
            name: storedEntry.name,
            symbol: storedEntry.symbol,
            contractAddress: contractAddress,
            decimalCount: storedEntry.decimalCount,
            id: storedEntry.id,
            metadata: .fungibleTokenMetadata // By definition, in the domain layer we're dealing only with fungible tokens
        )
    }

    static func convertFromBSDKToken(
        _ bsdkToken: BlockchainSdk.Token,
        in blockchainNetwork: BlockchainNetwork
    ) -> StoredCryptoAccount.Token {
        return StoredCryptoAccount.Token(
            id: bsdkToken.id,
            name: bsdkToken.name,
            symbol: bsdkToken.symbol,
            decimalCount: bsdkToken.decimalCount,
            // By definition, all token domain entities are known
            blockchainNetwork: .known(blockchainNetwork: convertToStoredBlockchainNetwork(blockchainNetwork)),
            contractAddress: bsdkToken.contractAddress
        )
    }

    static func convertToStoredBlockchainNetwork(
        _ blockchainNetwork: BlockchainNetwork
    ) -> StoredCryptoAccount.Token.StoredBlockchainNetwork {
        return StoredCryptoAccount.Token.StoredBlockchainNetwork(
            blockchain: blockchainNetwork.blockchain,
            derivationPath: blockchainNetwork.derivationPath,
            settings: blockchainNetwork.settings
        )
    }

    static func convertToBlockchainNetwork(
        _ storedBlockchainNetwork: StoredCryptoAccount.Token.StoredBlockchainNetwork
    ) -> BlockchainNetwork {
        return BlockchainNetwork(
            storedBlockchainNetwork.blockchain,
            derivationPath: storedBlockchainNetwork.derivationPath,
            settings: storedBlockchainNetwork.settings
        )
    }
}

// MARK: - Convenience extensions

extension StoredEntryConverter {
    static func convertToStoredEntries(_ tokenItems: [TokenItem]) -> [StoredCryptoAccount.Token] {
        return tokenItems.map { convertToStoredEntry($0) }
    }

    static func convertToTokenItems(_ storedEntries: [StoredCryptoAccount.Token]) -> [TokenItem] {
        return storedEntries.compactMap { convertToTokenItem($0) }
    }
}

extension TokenItem {
    func toStoredToken() -> StoredCryptoAccount.Token {
        return StoredEntryConverter.convertToStoredEntry(self)
    }
}

extension StoredCryptoAccount.Token {
    func toTokenItem() -> TokenItem? {
        return StoredEntryConverter.convertToTokenItem(self)
    }

    func toBSDKToken() -> BlockchainSdk.Token? {
        return StoredEntryConverter.convertToBSDKToken(self)
    }
}
