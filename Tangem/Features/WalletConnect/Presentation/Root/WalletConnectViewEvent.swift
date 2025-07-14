//
//  WalletConnectViewEvent.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum WalletConnectViewEvent {
    case newConnectionButtonTapped
    case disconnectAllDAppsButtonTapped
    case dAppTapped(WalletConnectConnectedDApp)
    case connectedDAppsChanged([WalletConnectConnectedDApp])
    case closeDialogButtonTapped
}
