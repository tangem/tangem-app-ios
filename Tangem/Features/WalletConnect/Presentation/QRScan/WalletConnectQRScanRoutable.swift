//
//  WalletConnectQRScanRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum WalletConnectQRScanResult {
    case fromClipboard(WalletConnectRequestURI)
    case fromQRCode(WalletConnectRequestURI)
}

@MainActor
protocol WalletConnectQRScanRoutable {
    func openPhotoPicker()
    func openSystemSettings()
    func dismiss(with result: WalletConnectQRScanResult?)
}
