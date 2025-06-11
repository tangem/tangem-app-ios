//
//  WalletConnectDAppProposalLoadingError.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

/// Error that may occur during the fetching or validation of a dApp connection proposal.
enum WalletConnectDAppProposalLoadingError: Error {
    /// Attempted to pair with a URI that has already been used or is currently active.
    /// - Note: This may occur if the user scans the same QR code multiple times without refreshing.
    case uriAlreadyUsed

    /// An untyped error thrown during dApp connection proposal loading.
    case pairingFailed(any Error)

    /// The dApp URL string is not a valid ``URL``.
    case invalidDomainURL(String)

    /// The dApp domain is not supported by the Tangem app.
    case unsupportedDomain(UnsupportedDomainError)

    /// The dApp has required blockchains that are not supported by the Tangem app.
    case unsupportedBlockchains(UnsupportedBlockchainsError)

    /// The dApp does not specify any blockchains — neither required nor optional.
    case noBlockchainsProvidedByDApp(NoBlockchainsProvidedByDAppError)

    /// The dApp connection proposal loading was explicitly cancelled by user.
    case cancelledByUser
}

extension WalletConnectDAppProposalLoadingError {
    struct UnsupportedDomainError {
        let proposalID: String
        let dAppName: String
        let dAppRawDomain: String
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
