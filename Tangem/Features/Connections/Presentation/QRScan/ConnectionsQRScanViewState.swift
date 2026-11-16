//
//  ConnectionsQRScanViewState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAssets
import TangemLocalization
import struct TangemUIUtils.ConfirmationDialogViewModel

struct ConnectionsQRScanViewState {
    let navigationBar = NavigationBar()
    let hint = Localization.wcConnectionsQrScanHint
    var hasCameraAccess = false
    var confirmationDialog: ConfirmationDialogViewModel?
}

extension ConnectionsQRScanViewState {
    struct NavigationBar {
        let title = Localization.wcNewConnection
        let closeButtonTitle = Localization.commonClose
    }
}
