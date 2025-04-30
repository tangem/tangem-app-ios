//
//  WalletConnectViewState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import enum TangemAssets.Assets
import enum TangemLocalization.Localization

// [REDACTED_TODO_COMMENT]
struct WalletConnectViewState: Equatable {
    let navigationBar: NavigationBar
    var contentState: ContentState
    var dialog: ModalDialog?
    var newConnectionButton: Button

    static let initial = WalletConnectViewState(
        navigationBar: NavigationBar(),
        contentState: .empty(WalletConnectViewState.ContentState.EmptyContentState()),
        dialog: nil,
        newConnectionButton: WalletConnectViewState.Button(isLoading: true)
    )
}

extension WalletConnectViewState {
    struct NavigationBar: Equatable {
        let title = "Connections"
        let trailingButtonAsset = Assets.verticalDots
        let disconnectAllMenuTitle = Localization.wcDisconnectAll
    }

    enum ContentState: Equatable {
        case empty(EmptyContentState)
        case withConnectedDApps([WalletWithConnectedDApps])
    }

    enum ModalDialog: Equatable {
        case alert(ModalDialog.Content)
        case confirmationDialog(ModalDialog.Content)

        var title: String {
            switch self {
            case .alert(let content), .confirmationDialog(let content):
                content.title
            }
        }

        var subtitle: String {
            switch self {
            case .alert(let content), .confirmationDialog(let content):
                content.subtitle
            }
        }

        var isAlert: Bool {
            switch self {
            case .alert: true
            case .confirmationDialog: false
            }
        }

        var isConfirmationDialog: Bool {
            switch self {
            case .alert: false
            case .confirmationDialog: true
            }
        }
    }

    struct Button: Equatable {
        let title = "New connection"
        var isLoading: Bool
    }
}

extension WalletConnectViewState.ContentState {
    struct EmptyContentState: Equatable {
        let title = "No sessions"
        let subtitle = "Connect your wallet to a different dApps"
        let asset = Assets.walletConnect
    }

    struct WalletWithConnectedDApps: Identifiable, Equatable {
        let walletId: String
        let walletName: String
        let dApps: [WalletConnectSavedSession]

        var id: String { walletId }
    }
}

extension WalletConnectViewState.ModalDialog {
    struct Content: Equatable {
        let title: String
        let subtitle: String
        let buttons: [DialogButton]

        static func cameraAccessDenied(
            openSystemSettingsAction: @escaping () -> Void,
            establishConnectionFromClipboardURI: (() -> Void)?
        ) -> Content {
            var buttons = [
                DialogButton(title: Localization.commonCameraAlertButtonSettings, role: nil, action: openSystemSettingsAction),
            ]

            if let establishConnectionFromClipboardURI {
                buttons.append(
                    DialogButton(
                        title: Localization.walletConnectPasteFromClipboard,
                        role: nil,
                        action: establishConnectionFromClipboardURI
                    )
                )
            }

            return Content(
                title: Localization.commonCameraDeniedAlertTitle,
                subtitle: Localization.commonCameraDeniedAlertMessage,
                buttons: buttons
            )
        }

        static func disconnectAllDApps(action: @escaping () -> Void) -> Content {
            Content(
                title: Localization.wcDisconnectAllAlertTitle,
                subtitle: Localization.wcDisconnectAllAlertDesc,
                buttons: [
                    DialogButton.cancel,
                    DialogButton(title: Localization.commonDisconnect, role: .destructive, action: action),
                ]
            )
        }

        static func featureDisabled(reason: String) -> Content {
            Content(
                title: Localization.commonWarning,
                subtitle: reason,
                buttons: [
                    .ok,
                ]
            )
        }
    }

    struct DialogButton: Hashable {
        let title: String
        let role: DialogButtonRole?
        let action: () -> Void

        static let cancel = DialogButton(title: Localization.commonCancel, role: .cancel, action: {})
        static let ok = DialogButton(title: Localization.commonOk, role: nil, action: {})

        func hash(into hasher: inout Hasher) {
            hasher.combine(title)
            hasher.combine(role)
        }

        static func == (lhs: WalletConnectViewState.ModalDialog.DialogButton, rhs: WalletConnectViewState.ModalDialog.DialogButton) -> Bool {
            lhs.title == rhs.title && lhs.role == rhs.role
        }
    }

    enum DialogButtonRole: Hashable {
        case cancel
        case destructive
    }
}
