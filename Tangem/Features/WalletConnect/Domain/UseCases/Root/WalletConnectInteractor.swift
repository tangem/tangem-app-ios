//
//  WalletConnectInteractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct WalletConnectInteractor {
    let extendConnectedDApps: WalletConnectExtendConnectedDAppsUseCase
    let getConnectedDApps: WalletConnectGetConnectedDAppsUseCase
    let establishDAppConnection: WalletConnectEstablishDAppConnectionUseCase
    let disconnectDApp: WalletConnectDisconnectDAppUseCase
}
