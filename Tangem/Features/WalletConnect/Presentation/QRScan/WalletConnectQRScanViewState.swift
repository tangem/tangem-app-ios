//
//  WalletConnectQRScanViewState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAssets
import TangemLocalization
import struct TangemUIUtils.ConfirmationDialogViewModel

struct WalletConnectQRScanViewState {
    let navigationBar = NavigationBar()
    let hint = Localization.wcQrScanHint
    var hasCameraAccess = false
    var confirmationDialog: ConfirmationDialogViewModel?
}

extension WalletConnectQRScanViewState {
    struct NavigationBar {
        let title = Localization.wcNewConnection
        let closeButtonTitle = Localization.commonClose
    }
}
