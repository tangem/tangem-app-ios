//
//  ConnectionsQRScanRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum ConnectionsQRScanResult {
    case walletConnect(WalletConnectRequestURI, source: Self.Source)
    case mcpConnectionRequest(userCode: String, source: Self.Source)
}

extension ConnectionsQRScanResult {
    enum Source {
        case qrCode
        case clipboard
    }
}

@MainActor
protocol ConnectionsQRScanRoutable: AnyObject {
    func dismiss(with result: ConnectionsQRScanResult?)
    func display(error: some Error)
}
