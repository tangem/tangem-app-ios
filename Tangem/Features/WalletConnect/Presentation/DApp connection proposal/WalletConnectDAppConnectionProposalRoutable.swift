//
//  WalletConnectDAppConnectionProposalRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

@MainActor
protocol WalletConnectDAppConnectionProposalRoutable: AnyObject {
    func openConnectionRequest()

    func openVerifiedDomain(for dAppName: String)
    func openDomainVerificationWarning(
        _ verificationStatus: WalletConnectDAppVerificationStatus,
        cancelAction: @escaping () async -> Void,
        connectAnywayAction: @escaping () async -> Void
    )

    func openWalletSelector()
    func openNetworksSelector(_ blockchainsAvailabilityResult: WalletConnectDAppBlockchainsAvailabilityResult)

    func openErrorScreen(error: some Error)

    func dismiss()

    func showErrorToast(with message: String)
    func showSuccessToast(with message: String)
}
