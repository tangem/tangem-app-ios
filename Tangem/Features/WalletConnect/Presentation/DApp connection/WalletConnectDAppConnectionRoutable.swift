//
//  WalletConnectDAppConnectionRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

@MainActor
protocol WalletConnectDAppConnectionRoutable: AnyObject {
    func openConnectionRequest()

    func openVerifiedDomain(for dAppName: String)

    func openDomainVerificationWarning(
        _ verificationStatus: WalletConnectDAppVerificationStatus,
        cancelAction: @escaping () async -> Void,
        connectAnywayAction: @escaping () async -> Void
    )

    func openWalletSelector()

    func openNetworksSelector(_ blockchainsAvailabilityResult: WalletConnectDAppBlockchainsAvailabilityResult)

    func displaySuccessfulDAppConnection(with dAppName: String)

    func displayProposalLoadingError(_ proposalLoadingError: WalletConnectDAppProposalLoadingError)
    func displayProposalApprovalError(_ proposalConnectionError: WalletConnectDAppProposalApprovalError)

    func dismiss()
}
