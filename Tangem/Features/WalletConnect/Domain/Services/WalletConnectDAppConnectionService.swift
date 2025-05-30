//
//  WalletConnectDAppConnectionService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol WalletConnectDAppConnectionService {
    func connectDApp(with request: WalletConnectDAppConnectionRequest) async throws
    func disconnectDApp(with request: WalletConnectDAppConnectionRequest) async throws
}
