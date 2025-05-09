//
//  WalletConnectRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import struct SwiftUI.Binding

@MainActor
protocol WalletConnectRoutable: AnyObject {
    func openConnectedDAppDetails(_ dApp: WalletConnectSavedSession)
    func openQRScanner(clipboardURI: WalletConnectRequestURI?, completion: @escaping (WalletConnectQRScanResult) -> Void)

    func legacyOpenQRScanner(with codeBinding: Binding<String>)
}
