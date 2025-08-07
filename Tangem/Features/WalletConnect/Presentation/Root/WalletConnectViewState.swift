//
//  WalletConnectViewState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import enum TangemLocalization.Localization

// [REDACTED_TODO_COMMENT]
struct WalletConnectViewState: Equatable {
    let navigationBar = NavigationBar()
    var contentState: ContentState
    var dialog: ModalDialog?
    var newConnectionButton: NewConnectionButton

    static let loading = WalletConnectViewState(
        contentState: .loading,
        dialog: nil,
        newConnectionButton: NewConnectionButton(isLoading: true)
    )

    static let empty = WalletConnectViewState(
        contentState: .empty,
        dialog: nil,
        newConnectionButton: NewConnectionButton(isLoading: false)
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
        case loading(LoadingContentState)
        case content([WalletWithConnectedDApps])

        var isEmpty: Bool {
            switch self {
            case .empty: true
            case .loading: false
            case .content: false
            }
        }

        var isLoading: Bool {
            switch self {
            case .empty: false
            case .loading: true
            case .content: false
            }
        }

        var isContent: Bool {
            switch self {
            case .empty: false
            case .loading: false
            case .content: true
            }
        }

        static let empty = ContentState.empty(.init())
        static let loading = ContentState.loading(LoadingContentState(dAppStubsCount: 5))
    }

    struct NewConnectionButton: Equatable {
        let title = Localization.wcNewConnection
        var isLoading: Bool
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
}

extension WalletConnectViewState.ContentState {
    struct EmptyContentState: Equatable {
        let title = "No sessions"
        let subtitle = "Connect your wallet to a different dApps"
        let asset = Assets.walletConnect
    }

    struct LoadingContentState: Equatable {
        let dAppStubsCount: Int
    }

    struct WalletWithConnectedDApps: Identifiable, Equatable {
        let walletId: String
        let walletName: String
        let dApps: [ConnectedDApp]

        var id: String { walletId }
    }

    struct ConnectedDApp: Identifiable, Equatable {
        let domainModel: WalletConnectConnectedDApp
        let fallbackIconAsset = Assets.Glyphs.explore

        var id: String {
            domainModel.session.topic
        }

        var iconURL: URL? {
            domainModel.dAppData.icon
        }

        var name: String {
            domainModel.dAppData.name
        }

        var domain: String {
            domainModel.dAppData.domain.host ?? ""
        }

        var verifiedDomainIconAsset: ImageType? {
            domainModel.verificationStatus.isVerified
                ? Assets.Glyphs.verified
                : nil
        }
    }
}

extension WalletConnectViewState.ModalDialog {
    struct Content: Equatable {
        let title: String
        let subtitle: String
        let buttons: [DialogButton]

        static func cameraAccessDenied(openSystemSettingsAction: @escaping () -> Void) -> Content {
            Content(
                title: Localization.commonCameraDeniedAlertTitle,
                subtitle: Localization.commonCameraDeniedAlertMessage,
                buttons: [
                    DialogButton(title: Localization.commonCameraAlertButtonSettings, role: nil, action: openSystemSettingsAction),
                ]
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
