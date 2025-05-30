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
    func openDomainVerification()
    func openWalletSelector()
    func openNetworksSelector()
    func openErrorScreen(error: some Error)
    func dismiss()
    func showErrorToast(with message: String)
    func showSuccessToast(with message: String)
}
