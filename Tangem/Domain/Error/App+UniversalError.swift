//
//  App+UniversalError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

// `Subsystems`:
// `000` - CommonError
// `001` - Visa onboarding
// `002` - Visa user wallet model
// `003` - Referral
// `004` - TransactionDispatcherResult.Error
// `005` - AnyWalletManagerFactoryError
// `006` - MultipleAddressTransactionHistoryService.ServiceError
// `007` - CommonUserTokensManager.Error
// `008` - CommonTokenEnricher.Error
// `009` - OrganizeTokensViewModel.Error
// `010` - WalletModelError
// `011` - AccountsAwareUserTokensManager.Error
// `012` - CloreMigrationSigningError

extension CommonError: UniversalError {
    var errorCode: Int {
        switch self {
        case .objectReleased:
            100000000
        case .noData:
            100000001
        case .notImplemented:
            100000002
        }
    }
}

extension VisaOnboardingViewModel.OnboardingError: UniversalError {
    var errorCode: Int {
        switch self {
        case .missingTargetApproveAddress:
            100001000
        case .wrongRemoteState:
            100001001
        }
    }
}

extension VisaUserWalletModel.ModelError: UniversalError {
    var errorCode: Int {
        switch self {
        case .missingRequiredBlockchain:
            100002001
        case .invalidBlockchain:
            100002002
        case .noPaymentAccount:
            100002003
        case .missingPublicKey:
            100002004
        case .failedToGenerateAddress:
            100002005
        case .authorizationError:
            100002006
        case .missingValidRefreshToken:
            100002007
        case .missingCardId:
            100002008
        case .invalidConfig:
            100002009
        case .invalidActivationState:
            100002010
        }
    }
}

extension ReferralViewModel.ReferralError: UniversalError {
    var errorCode: Int {
        switch self {
        case .awardNotLoaded:
            return 100003001
        case .blockchainNotSupported:
            return 100003002
        case .invalidToken:
            return 100003003
        case .decodingError:
            return 100003004
        case .accountFetchError:
            return 100003005
        case .moyaError(let error):
            return error.errorCode
        case .unknown(let error):
            let nsError = error as NSError
            // Look for status code at https://osstatus.com
            // if nothing was found - add the specific case to `ReferralError` enum
            return nsError.code
        }
    }
}

extension TransactionDispatcherResult.Error: UniversalError {
    var errorCode: Int {
        switch self {
        case .actionNotSupported:
            100004001
        case .demoAlert:
            100004002
        case .informationRelevanceServiceError:
            100004003
        case .informationRelevanceServiceFeeWasIncreased:
            100004004
        case .loadTransactionInfo(let error):
            error.errorCode
        case .sendTxError(_, let error):
            error.errorCode
        case .transactionNotFound:
            100004005
        case .userCancelled:
            100004006
        }
    }
}

extension AnyWalletManagerFactoryError: UniversalError {
    var errorCode: Int {
        switch self {
        case .walletWithBlockchainCurveNotFound:
            100005000
        case .entryHasNotDerivationPath:
            100005001
        case .noDerivation:
            100005002
        }
    }
}

extension MultipleAddressTransactionHistoryService.ServiceError: UniversalError {
    var errorCode: Int {
        switch self {
        case .unknownProvider:
            100006000
        }
    }
}

extension CommonUserTokensManager.Error: UniversalError {
    var errorCode: Int {
        switch self {
        case .addressNotFound:
            100007000
        case .failedSupportedCurve:
            100007001
        case .failedSupportedLongHashesTokens:
            100007002
        }
    }
}

extension AccountsAwareUserTokensManager.Error: UniversalError {
    var errorCode: Int {
        switch self {
        case .addressNotFound:
            100011000
        case .failedSupportedCurve:
            100011001
        case .failedSupportedLongHashesTokens:
            100011002
        case .derivationNotSupported:
            100011003
        case .derivationPathNotFound:
            100011004
        case .accountDerivationNodeMismatch:
            100011005
        }
    }
}

extension CommonTokenEnricher.Error: UniversalError {
    var errorCode: Int {
        switch self {
        case .notFound:
            100008000
        case .unsupportedBlockchain:
            100008001
        }
    }
}

extension OrganizeTokensViewModel.Error: UniversalError {
    var errorCode: Int {
        switch self {
        case .sectionOffsetOutOfBound:
            100009000
        }
    }
}

extension AccountsAwareOrganizeTokensViewModel.Error: UniversalError {
    var errorCode: Int {
        switch self {
        case .sectionOffsetOutOfBound:
            100009000
        }
    }
}

extension WalletModelError: UniversalError {
    var errorCode: Int {
        switch self {
        case .balanceNotFound:
            100010000
        }
    }
}

extension CloreMigrationSigningError: UniversalError {
    var errorCode: Int {
        switch self {
        case .userWalletNotFound:
            100012000
        case .accountNotFound:
            100012001
        case .failedToGetWalletModel:
            100012002
        case .invalidSignature:
            100012003
        }
    }
}
