//
//  WalletConnectDAppConnectionService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol WalletConnectDAppConnectionService {
    // [REDACTED_TODO_COMMENT]
    func connectDApp(with request: WalletConnectDAppConnectionRequest, _ userWalletID: String) async throws
    func disconnectDApp(with request: WalletConnectDAppConnectionRequest) async throws
}
