//
//  WalletConnectViewEvent.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum WalletConnectViewEvent {
    case viewDidAppear
    case newConnectionButtonTapped
    case disconnectAllDAppsButtonTapped
    case dAppTapped(WalletConnectSavedSession)
    case canConnectNewDAppStateChanged(Bool)
    case connectedDAppsChanged([WalletConnectSavedSession])
    case closeDialogButtonTapped
}
