//
//  SupportedTokensFilter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public enum SupportedTokensFilter {
    public static func canHandleToken(contractAddress: String, blockchain: Blockchain) -> Bool {
        guard blockchain.canHandleTokens else {
            return false
        }

        return _canHandleToken(contractAddress: contractAddress, blockchain: blockchain)
    }

    public static func canHandleCustomToken(contractAddress: String, blockchain: Blockchain) -> Bool {
        guard blockchain.canHandleCustomTokens else {
            return false
        }

        return _canHandleToken(contractAddress: contractAddress, blockchain: blockchain)
    }

    private static func _canHandleToken(contractAddress: String, blockchain: Blockchain) -> Bool {
        switch blockchain {
        case .terraV1:
            return contractAddress == CosmosChain.supportedTokenContractAddress
        default:
            return true
        }
    }
}
