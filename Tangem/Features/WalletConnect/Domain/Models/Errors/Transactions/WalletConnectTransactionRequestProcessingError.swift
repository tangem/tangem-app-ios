//
//  WalletConnectTransactionRequestProcessingError.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import enum BlockchainSdk.Blockchain

enum WalletConnectTransactionRequestProcessingError: Error {
    case invalidPayload
    case unsupportedBlockchain(String)
    case blockchainToAddDuplicate(Blockchain)
    case blockchainToAddRequiresDAppReconnection(Blockchain)
    case blockchainToAddIsMissingFromUserWallet(Blockchain)
    case userWalletNotFound
    case missingBlockchains([String])
    case unsupportedMethod(String)
    case notEnoughDataInRequest(String)
    case dataInWrongFormat(String)
    case missingTransaction
    case walletModelNotFound(String)
    case wrongCardSelected
    case userWalletRepositoryIsLocked
    case missingActiveUserWalletModel
    case userWalletIsLocked
}
