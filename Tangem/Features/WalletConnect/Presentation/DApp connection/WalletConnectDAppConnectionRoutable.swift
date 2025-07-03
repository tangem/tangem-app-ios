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
        connectAnywayAction: @escaping () async -> Void
    )

    func openSolanaBlockchainWarning(dAppName: String, connectAnywayAction: @escaping () async -> Void)

    func openWalletSelector()

    func openNetworksSelector(_ blockchainsAvailabilityResult: WalletConnectDAppBlockchainsAvailabilityResult)

    func displaySuccessfulDAppConnection(with dAppName: String)

    func display(proposalLoadingError: WalletConnectDAppProposalLoadingError)
    func display(proposalApprovalError: WalletConnectDAppProposalApprovalError)
    func display(dAppPersistenceError: WalletConnectDAppPersistenceError)

    func dismiss()
}
