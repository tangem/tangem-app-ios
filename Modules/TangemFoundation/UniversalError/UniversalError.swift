//
//  UniversalError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// Each error code must follow this format: xxxyyyzzz where
/// xxx - Feature code
/// yyy - Subsystem code
/// zzz - Specific error code
/// If you need to add new feature add it to list below incrementing last code same for `Subsystems`.
/// If your feature is in separate target, place file with `FeatureErrorsList` and add all errors with `UniversalError` conformance
/// in this separate file. See `VisaErrorsList.swift` for implementation details
///
/// Features:
/// `100` - App error `App+UniversalError`
/// `101` - TangemSdkError `ThirdParty+UniversalError`
/// `102` - BlockchainSdkError `BlockchainSDK+UniversalError`
/// `103` - Express `Express+UniversalError`
/// `104` - Visa `Visa+UniversalError`
/// `105` - Staking `Staking+UniversalError`
/// `106` - NFT `NFT+UniversalError`
/// `107` - WalletConnect `WC+UniversalError`
/// `108` - MoyaError `ThirdParty+UniversalError`
/// `109` - Onramp `Onramp+UniversalError`
/// `110` - MobileWallet `MobileWallet+UniversalError`
public protocol UniversalError: LocalizedError {
    var errorCode: Int { get }
}

public protocol CancellableError {
    var isUserCancelled: Bool { get }
}

public extension Error {
    var universalErrorCode: Int {
        toUniversalError().errorCode
    }

    func toUniversalError() -> UniversalError {
        return self as? UniversalError ?? UniversalErrorWrapper(underlyingError: self)
    }
}

public struct UniversalErrorWrapper: UniversalError {
    public let underlyingError: Error

    init(underlyingError: Error) {
        self.underlyingError = underlyingError
    }

    public var errorCode: Int { -1 }

    public var errorDescription: String? {
        (underlyingError as? LocalizedError)?.localizedDescription
    }
}
