//
//  WalletConnectQRScanViewEvent.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum WalletConnectQRScanViewEvent {
    case viewDidAppear
    case navigationCloseButtonTapped
    case pasteFromClipboardButtonTapped(String?)
    case qrCodeParsed(String)
    case cameraAccessStatusChanged(Bool)
    case closeDialogButtonTapped
}
