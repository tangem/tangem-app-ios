//
//  StorageEntryConverter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import struct BlockchainSdk.Token

@available(iOS, deprecated: 100000.0, message: "Deprecated entry, isn't used in Accounts, will be removed in the future ([REDACTED_INFO])")
struct StorageEntryConverter {
    // MARK: - StoredUserTokenList.Entry to Token

    func convertToToken(_ userToken: StoredUserTokenList.Entry) -> Token? {
        guard let contractAddress = userToken.contractAddress else { return nil }

        return Token(
            name: userToken.name,
            symbol: userToken.symbol,
            contractAddress: contractAddress,
            decimalCount: userToken.decimalCount,
            id: userToken.id
        )
    }

    // MARK: - TokenItem <-> StoredUserTokenList.Entry

    func convertToStoredUserTokens(tokenItems: [TokenItem]) -> [StoredUserTokenList.Entry] {
        return tokenItems
            .map { convertToStoredUserToken(tokenItem: $0) }
            .unique()
    }

    func convertToStoredUserToken(tokenItem: TokenItem) -> StoredUserTokenList.Entry {
        return StoredUserTokenList.Entry(
            id: tokenItem.id,
            name: tokenItem.token?.name ?? tokenItem.networkName,
            symbol: tokenItem.currencySymbol,
            decimalCount: tokenItem.decimalCount,
            blockchainNetwork: tokenItem.blockchainNetwork,
            contractAddress: tokenItem.token?.contractAddress
        )
    }

    func convertToTokenItems(_ entries: [StoredUserTokenList.Entry]) -> [TokenItem] {
        entries.map {
            guard let contractAddress = $0.contractAddress else {
                return .blockchain($0.blockchainNetwork)
            }

            let token = Token(
                name: $0.name,
                symbol: $0.symbol,
                contractAddress: contractAddress,
                decimalCount: $0.decimalCount,
                id: $0.id
            )
            return .token(token, $0.blockchainNetwork)
        }
    }
}
