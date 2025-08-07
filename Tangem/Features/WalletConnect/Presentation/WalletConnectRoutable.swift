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
    func openDAppConnectionProposal(forURI uri: WalletConnectRequestURI, source: Analytics.WalletConnectSessionSource)
    func openConnectedDAppDetails(_ dApp: WalletConnectConnectedDApp)
    func openQRScanner(completion: @escaping (WalletConnectQRScanResult) -> Void)

    func legacyOpenQRScanner(with codeBinding: Binding<String>)
}
