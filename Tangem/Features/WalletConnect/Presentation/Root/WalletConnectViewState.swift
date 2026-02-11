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
import struct TangemFoundation.IgnoredEquatable
import struct TangemUIUtils.ConfirmationDialogViewModel

struct WalletConnectViewState: Equatable {
    let contentMode: ContentMode
    let navigationBar = NavigationBar()
    var contentState: ContentState
    var dialog: ModalDialog?
    var newConnectionButton: NewConnectionButton

    var usesAccountBasedLayout: Bool {
        contentMode == .repository
    }

    var shouldDisplayWalletNames: Bool {
        switch contentMode {
        case .repository:
            switch contentState {
            case .content(let items):
                return items.count > 1
            case .empty, .loading:
                return false
            }
        case .legacy:
            return true
        }
    }

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

    init(contentState: ContentState, dialog: ModalDialog? = nil, newConnectionButton: NewConnectionButton) {
        contentMode = FeatureProvider.isAvailable(.accounts) ? .repository : .legacy
        self.contentState = contentState
        self.dialog = dialog
        self.newConnectionButton = newConnectionButton
    }
}

extension WalletConnectViewState {
    struct NavigationBar: Equatable {
        let title = Localization.wcConnections
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
        case alert(ModalDialog.Alert)
        case cameraAccessDeniedDialog(ConfirmationDialogViewModel)

        var asAlert: ModalDialog.Alert? {
            switch self {
            case .alert(let alert): alert
            case .cameraAccessDeniedDialog: nil
            }
        }

        var asConfirmationDialog: ConfirmationDialogViewModel? {
            switch self {
            case .alert: nil
            case .cameraAccessDeniedDialog(let dialog): dialog
            }
        }
    }
}

extension WalletConnectViewState.ContentState {
    struct EmptyContentState: Equatable {
        let title = Localization.wcNoSessionsTitle
        let subtitle = Localization.wcNoSessionsDesc
        let asset = Assets.walletConnect
    }

    struct LoadingContentState: Equatable {
        let dAppStubsCount: Int
    }

    struct WalletWithConnectedDApps: Identifiable, Equatable {
        let walletId: String
        let walletName: String
        let accountSections: [AccountSection]
        let walletLevelDApps: [ConnectedDApp]

        var id: String { walletId }

        var hasAccountSections: Bool { !accountSections.isEmpty }
        var hasWalletLevelDApps: Bool { !walletLevelDApps.isEmpty }
    }

    struct AccountSection: Identifiable, Equatable {
        let id: String
        let icon: AccountModel.Icon
        let name: String
        let dApps: [ConnectedDApp]

        static func == (lhs: WalletConnectViewState.ContentState.AccountSection, rhs: WalletConnectViewState.ContentState.AccountSection) -> Bool {
            lhs.id == rhs.id && lhs.dApps == rhs.dApps
        }
    }

    struct ConnectedDApp: Identifiable, Equatable {
        let domainModel: WalletConnectConnectedDApp
        let fallbackIconAsset = Assets.Glyphs.explore

        var id: String {
            "\(domainModel.session.topic)|\(domainModel.accountId ?? "wallet")"
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
    struct Alert: Equatable {
        let title: String
        let subtitle: String
        let buttons: [AlertButton]

        static func disconnectAllDApps(action: @escaping () -> Void) -> Alert {
            Alert(
                title: Localization.wcDisconnectAllAlertTitle,
                subtitle: Localization.wcDisconnectAllAlertDesc,
                buttons: [
                    AlertButton.cancel,
                    AlertButton(title: Localization.commonDisconnect, role: .destructive, action: action),
                ]
            )
        }

        static func featureDisabled(reason: String) -> Alert {
            Alert(
                title: Localization.commonWarning,
                subtitle: reason,
                buttons: [
                    .ok,
                ]
            )
        }
    }

    struct AlertButton: Hashable {
        let title: String
        let role: AlertButtonRole?
        @IgnoredEquatable var action: () -> Void

        static let cancel = AlertButton(title: Localization.commonCancel, role: .cancel, action: {})
        static let ok = AlertButton(title: Localization.commonOk, role: nil, action: {})
    }

    enum AlertButtonRole: Hashable {
        case cancel
        case destructive
    }
}

extension WalletConnectViewState {
    enum ContentMode {
        case legacy
        case repository
    }
}
