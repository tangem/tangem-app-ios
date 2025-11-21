//
//  WC+UniversalError.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation

// `Subsystems`:
// `001` - DAppProposalLoading
// `002` - DAppProposalApproval
// `004` - CommonBlockaidAPIService.BlockaidAPIServiceError
// `005` - DAppPersistenceError
// `006` - WebSocketError
// `007` - WalletConnectEstablishDAppConnectionUseCase.FeatureDisabledError
// `008` - WalletConnectSavedSessionMigrationService.Error
// `009` - WalletConnectTransactionRequestProcessingError
// `010` - WalletConnectSignError
// `011` - WalletConnectURIParsingError

extension WalletConnectDAppProposalLoadingError: UniversalError {
    var errorCode: Int {
        switch self {
        case .uriAlreadyUsed:
            107001001
        case .pairingFailed:
            107001002
        case .invalidDomainURL:
            107001003
        case .unsupportedDomain:
            107001004
        case .unsupportedBlockchains:
            107001005
        case .noBlockchainsProvidedByDApp:
            107001006
        case .pairingTimeout:
            107001007
        case .cancelledByUser:
            107001008
        }
    }
}

extension WalletConnectDAppProposalApprovalError: UniversalError {
    var errorCode: Int {
        switch self {
        case .invalidConnectionRequest:
            107002001
        case .proposalExpired:
            107002002
        case .approvalFailed:
            107002003
        case .rejectionFailed:
            107002004
        case .cancelledByUser:
            107002005
        }
    }
}

extension CommonBlockaidAPIService.BlockaidAPIServiceError: UniversalError {
    var errorCode: Int {
        switch self {
        case .blockchainIsNotSupported:
            107004000
        case .missingTransactionValue:
            107004001
        }
    }
}

extension WalletConnectDAppPersistenceError: UniversalError {
    var errorCode: Int {
        switch self {
        case .notFound:
            107005000
        case .retrievingFailed:
            107005001
        case .savingFailed:
            107005002
        }
    }
}

extension WebSocketError: UniversalError {
    var errorCode: Int {
        switch self {
        case .closedUnexpectedly:
            107006000
        case .peerDisconnected:
            107006001
        }
    }
}

extension WalletConnectEstablishDAppConnectionUseCase.FeatureDisabledError: UniversalError {
    var errorCode: Int {
        107007000
    }
}

extension WalletConnectSavedSessionMigrationService.Error: UniversalError {
    var errorCode: Int {
        switch self {
        case .invalidDAppURL:
            107008000
        case .userWalletNotFound:
            107008001
        }
    }
}

extension WalletConnectTransactionRequestProcessingError: UniversalError {
    var errorCode: Int {
        switch self {
        case .invalidPayload:
            107009001
        case .unsupportedBlockchain:
            107009002
        case .blockchainToAddDuplicate:
            107009003
        case .blockchainToAddRequiresDAppReconnection:
            107009004
        case .blockchainToAddIsMissingFromUserWallet:
            107009005
        case .userWalletNotFound:
            107009006
        case .unsupportedMethod:
            107009008
        case .walletModelNotFound:
            107009012
        case .userWalletRepositoryIsLocked:
            107009014
        case .userWalletIsLocked:
            107009016
        case .missingEthTransactionSigner:
            107009018
        case .missingGasLoader:
            107009019
        case .eraseMultipleTransactions:
            107009020
        case .accountNotFound:
            1007009021
        }
    }
}

extension WCTransactionSignError: UniversalError {
    var errorCode: Int {
        switch self {
        case .signFailed:
            107010001
        }
    }
}

extension WalletConnectURIParsingError: UniversalError {
    var errorCode: Int {
        switch self {
        case .unsupportedWalletConnectVersion:
            107011001
        case .expired:
            107011002
        case .invalidFormat:
            107011003
        }
    }
}
