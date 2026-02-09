//
//  WalletConnectDAppProposalLoadingError.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import protocol Foundation.LocalizedError

/// Error that may occur during the fetching or validation of a dApp connection proposal.
enum WalletConnectDAppProposalLoadingError: LocalizedError {
    /// Attempted to pair with a URI that has already been used or is currently active.
    /// - Note: This may occur if the user scans the same QR code multiple times without refreshing.
    case uriAlreadyUsed

    /// An untyped error thrown during session pairing.
    case pairingFailed(any Error)

    /// The dApp URL string is not a valid ``URL``.
    case invalidDomainURL(String)

    /// The dApp domain is not supported by the Tangem app.
    case unsupportedDomain(UnsupportedDomainError)

    /// The dApp has required blockchains that are not supported by the Tangem app.
    case unsupportedBlockchains(UnsupportedBlockchainsError)

    /// The dApp does not specify any blockchains — neither required nor optional.
    case noBlockchainsProvidedByDApp(NoBlockchainsProvidedByDAppError)

    /// The session pairing operation timed out.
    /// - Note: The timeout interval is 30 seconds.
    case pairingTimeout

    /// The dApp connection proposal loading was explicitly cancelled by user.
    case cancelledByUser

    /// There is no selected account.
    /// - Note: App is probably in a corrupted state.
    /// - Warning: @vefimenko_tangem, check if this case should exist in [REDACTED_INFO]
    case selectedAccountRetrievalFailed

    var errorDescription: String? {
        switch self {
        case .uriAlreadyUsed:
            "Attempted to pair with a URI that has already been used or is currently active."

        case .pairingFailed(let underlyingError):
            "An untyped error thrown during session pairing: \(underlyingError.localizedDescription)"

        case .invalidDomainURL(let rawDomainString):
            "The dApp URL string is not a valid ``URL``. Raw value: \(rawDomainString)"

        case .unsupportedDomain(let error):
            "The \(error.dAppName) dApp domain: \(error.dAppRawURL) is not supported by the Tangem app."

        case .unsupportedBlockchains(let error):
            "The \(error.dAppName) dApp has required blockchains that are not supported by the Tangem app. Blockchains: \(error.blockchainNames)"

        case .noBlockchainsProvidedByDApp(let error):
            "The \(error.dAppName) dApp does not specify any blockchains — neither required nor optional."

        case .pairingTimeout:
            "The session pairing operation timed out."

        case .cancelledByUser:
            "The dApp connection proposal loading was explicitly cancelled by user."

        case .selectedAccountRetrievalFailed:
            "There is no selected account. App is probably in a corrupted state."
        }
    }
}

extension WalletConnectDAppProposalLoadingError {
    struct UnsupportedDomainError {
        let proposalID: String
        let dAppName: String
        let dAppRawURL: String
    }

    struct UnsupportedBlockchainsError {
        let proposalID: String
        let dAppName: String
        let blockchainNames: [String]
    }

    struct NoBlockchainsProvidedByDAppError {
        let proposalID: String
        let dAppName: String
    }
}
