//
//  WalletConnectDAppConnectionProposalRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

@MainActor
protocol WalletConnectDAppConnectionProposalRoutable: AnyObject {
    func openDomainVerification()
    func openWalletSelector()
    func openNetworksSelector()
    func dismiss()
}
