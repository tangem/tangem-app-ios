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
protocol WalletConnectQRScanRoutable: AnyObject {
    func dismiss(with result: WalletConnectQRScanResult?)
    func display(error: some Error)
}
