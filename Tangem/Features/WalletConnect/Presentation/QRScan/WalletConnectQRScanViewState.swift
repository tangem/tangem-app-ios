//
//  WalletConnectQRScanViewState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAssets
import TangemLocalization

struct WalletConnectQRScanViewState {
    let navigationBar = NavigationBar()
    let hint = Localization.wcQrScanHint
    var hasCameraAccess = false
    var confirmationDialog: ConfirmationDialog?
}

extension WalletConnectQRScanViewState {
    struct NavigationBar {
        let title = Localization.wcNewConnection
        let closeButtonTitle = Localization.commonClose
    }

    struct ConfirmationDialog {
        let title: String
        let subtitle: String
        let button: DialogButton

        static func cameraAccessDenied(openSystemSettingsAction: @escaping () -> Void) -> ConfirmationDialog {
            ConfirmationDialog(
                title: Localization.commonCameraDeniedAlertTitle,
                subtitle: Localization.commonCameraDeniedAlertMessage,
                button: DialogButton(title: Localization.commonCameraAlertButtonSettings, action: openSystemSettingsAction)
            )
        }
    }

    struct DialogButton {
        let title: String
        let action: () -> Void
    }
}
