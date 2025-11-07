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

    func openVerifiedDomain()

    func openDomainVerificationWarning(
        _ verificationStatus: WalletConnectDAppVerificationStatus,
        connectAnywayAction: @escaping () async -> Void
    )

    func openWalletSelector()

    func openAccountSelector()

    func openNetworksSelector(_ blockchainsAvailabilityResult: WalletConnectDAppBlockchainsAvailabilityResult)

    func displaySuccessfulDAppConnection(with dAppName: String)

    func display(proposalLoadingError: WalletConnectDAppProposalLoadingError)
    func display(proposalApprovalError: WalletConnectDAppProposalApprovalError)
    func display(dAppPersistenceError: WalletConnectDAppPersistenceError)

    func dismiss()
}
