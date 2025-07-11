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
// `003` - WCFeeProviderError
// `004` - CommonBlockaidAPIService.BlockaidAPIServiceError
// `006` - WebSocketError
// `007` - WalletConnectEstablishDAppConnectionUseCase.FeatureDisabledError
// `008` - WalletConnectSavedSessionMigrationService.Error

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
        case .cancelledByUser:
            107001007
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

extension WCFeeProviderError: UniversalError {
    var errorCode: Int {
        switch self {
        case .unsupportedBlockchain:
            107003000
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
        case .invalidDAppDomain:
            107008000
        case .userWalletNotFound:
            107008001
        }
    }
}
