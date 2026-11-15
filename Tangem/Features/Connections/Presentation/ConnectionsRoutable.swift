//
//  ConnectionsRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct TangemFoundation.UserWalletId
import struct TangemMCP.MCPSession

@MainActor
protocol ConnectionsRoutable: AnyObject {
    func openQRScanner(completion: @escaping (ConnectionsQRScanResult) -> Void)

    func openMCPConnectionRequest(
        userCode: String,
        preselectedUserWalletID: UserWalletId,
        connectionAcceptedAction: @escaping (UserWalletId) -> Void
    )
    func openMCPSessionDetails(_ session: MCPSession, sessionRevokedAction: @escaping () -> Void)

    func openDAppConnectionProposal(
        forURI uri: WalletConnectRequestURI,
        source: Analytics.WalletConnectSessionSource,
        preselectedUserWalletID: UserWalletId
    )
    func openConnectedDAppDetails(_ dApp: WalletConnectConnectedDApp)

    func displayDisconnectAllSucceeded()
    func displayDisconnectAllFailed()
    func display(error: some Error)
}
