//
//  WalletConnectCameraAccessProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol WalletConnectCameraAccessProvider {
    func checkCameraAccess() -> WalletConnectCameraAccess
    func requestCameraAccess() async -> Bool
}
