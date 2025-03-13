//
//  Analytics+WalletConnectSessionSource.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

extension Analytics {
    enum WalletConnectSessionSource: String {
        case qrCode = "QR"
        case deeplink = "Deeplink"
        case clipboard = "Clipboard"
    }
}
