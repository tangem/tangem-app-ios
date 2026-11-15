//
//  ConnectionsInteractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct TangemMCP.FetchMCPSessionsUseCase
import struct TangemMCP.RevokeDeviceMCPSessionsUseCase

struct ConnectionsInteractor {
    let checkCameraAccess: ConnectionsCheckCameraAccessUseCase

    let fetchMCPSessions: FetchMCPSessionsUseCase
    let revokeDeviceMCPSessions: RevokeDeviceMCPSessionsUseCase

    let streamConnectedDApps: WalletConnectStreamConnectedDAppsUseCase
    let extendConnectedDApps: WalletConnectExtendConnectedDAppsUseCase
    let disconnectAllDApps: WalletConnectDisconnectAllDAppsUseCase
}
