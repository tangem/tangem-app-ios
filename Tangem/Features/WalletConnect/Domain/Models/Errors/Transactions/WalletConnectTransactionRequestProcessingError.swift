//
//  WalletConnectTransactionRequestProcessingError.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import protocol Foundation.LocalizedError
import enum BlockchainSdk.Blockchain

enum WalletConnectTransactionRequestProcessingError: LocalizedError {
    case invalidPayload(String)
    case unsupportedBlockchain(String)
    case blockchainToAddDuplicate(Blockchain)
    case blockchainToAddRequiresDAppReconnection(Blockchain)
    case blockchainToAddIsMissingFromUserWallet(Blockchain)
    case unsupportedMethod(String)
    case walletModelNotFound(blockchainNetworkID: String)
    case userWalletNotFound
    case userWalletIsLocked
    case userWalletRepositoryIsLocked
    case missingEthTransactionSigner
    case missingGasLoader
    case eraseMultipleTransactions
    case accountNotFound

    var errorDescription: String? {
        switch self {
        case .invalidPayload(let rawPayload):
            "Transaction request data is invalid or has unexpected format: \(rawPayload)"

        case .unsupportedBlockchain(let blockchain):
            "\(blockchain) blockchain is not supported by Tangem app."

        case .blockchainToAddDuplicate(let blockchain):
            "\(blockchain.displayName) has already been added to a dApp session."

        case .blockchainToAddRequiresDAppReconnection(let blockchain):
            "DApp session reconnection is required to add \(blockchain.displayName) blockchain."

        case .blockchainToAddIsMissingFromUserWallet(let blockchain):
            "Can't add \(blockchain.displayName) blockchain because it's missing from user wallet."

        case .unsupportedMethod(let method):
            "\(method) RPC method is not supported by Tangem app."

        case .walletModelNotFound(let blockchainNetworkID):
            "No WalletModel was found for \(blockchainNetworkID) blockchain."

        case .userWalletNotFound:
            "User wallet not found."

        case .userWalletIsLocked:
            "User wallet is locked."

        case .userWalletRepositoryIsLocked:
            "UserWalletRepository is locked."

        case .missingEthTransactionSigner:
            "EthereumTransactionSigner is missing."

        case .missingGasLoader:
            "EthereumNetworkProvider is missing."

        case .eraseMultipleTransactions:
            "The transaction was sent by our service, the RPC does not need to be returned."

        case .accountNotFound:
            "Account not found."
        }
    }
}
