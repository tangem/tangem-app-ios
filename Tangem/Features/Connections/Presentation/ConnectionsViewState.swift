//
//  ConnectionsViewState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.URL
import TangemAssets
import struct TangemFoundation.UserWalletId
import enum TangemLocalization.Localization
import struct TangemMCP.MCPSession
import enum TangemUI.ThumbnailWalletViewType
import struct TangemUIUtils.ConfirmationDialogViewModel

struct ConnectionsViewState: Equatable {
    var navigationBar = Self.NavigationBar()

    var tabs: [Self.UserWalletTab]
    var selectedTabID: Self.UserWalletTab.ID

    var modalDialog: Self.ModalDialog?
    var newConnectionButton = NewConnectionButton()

    var isTabBarVisible: Bool {
        tabs.count > 1
    }
}

extension ConnectionsViewState {
    struct NavigationBar: Equatable {
        let title = Localization.wcConnections
        var trailingButton: Self.TrailingButton?
    }
}

extension ConnectionsViewState.NavigationBar {
    struct TrailingButton: Equatable {
        let icon = DesignSystem.Icons.DotsHorizontal.regular20
        let disconnectAllMenuTitle = Localization.wcDisconnectAll
        var isEnabled = true
    }
}

extension ConnectionsViewState {
    struct UserWalletTab: Identifiable, Equatable {
        var id: UserWalletId { tabItem.id }

        let tabItem: Self.TabItem
        var mcpSessionsSection: Self.MCPSessionsSection

        /// - Remark: `nil` when WalletConnect isn't available for this user wallet.
        var dAppsSection: Self.WalletConnectDAppsSection?

        var emptyStateSection: Self.EmptyStateSection? {
            let noMCPSessions = mcpSessionsSection.isEmpty
            let noDApps = dAppsSection?.isEmpty ?? true
            let noConnections = noMCPSessions && noDApps

            return noConnections ? Self.EmptyStateSection() : nil
        }
    }

    struct NewConnectionButton: Equatable {
        let title = Localization.wcNewConnection
        var isLoading = false
    }
}

extension ConnectionsViewState.UserWalletTab {
    struct TabItem: Identifiable, Hashable {
        let id: UserWalletId
        let name: String
        let thumbnail: ThumbnailWalletViewType?
    }

    struct EmptyStateSection: Equatable {
        let title = Localization.wcConnectionsEmptyTitle
        let subtitle = Localization.wcConnectionsEmptyDesc
    }
}

// MARK: - MCP sessions section

extension ConnectionsViewState.UserWalletTab {
    struct MCPSessionsSection: Equatable {
        let title = Localization.wcConnectionsAgentsTitle
        var state: Self.State

        var isEmpty: Bool {
            switch state {
            case .loading, .failed: false
            case .content(let sessions): sessions.isEmpty
            }
        }
    }
}

extension ConnectionsViewState.UserWalletTab.MCPSessionsSection {
    enum State: Equatable {
        case loading
        case failed(FailedState)
        case content([MCPSession])
    }

    struct FailedState: Equatable {
        let title = Localization.wcConnectionsAgentsErrorTitle
        let subtitle = Localization.wcConnectionsAgentsErrorSubtitle
        var isReloading = false
    }
}

// MARK: - WalletConnect dApps section

extension ConnectionsViewState.UserWalletTab {
    struct WalletConnectDAppsSection: Equatable {
        let title = Localization.wcConnectionsDappsTitle
        var state: Self.State

        var isEmpty: Bool {
            switch state {
            case .loading: false
            case .content(.flat(let dApps)): dApps.isEmpty
            case .content(.byAccount(let accounts)): accounts.isEmpty
            }
        }
    }
}

extension ConnectionsViewState.UserWalletTab.WalletConnectDAppsSection {
    enum State: Equatable {
        case loading
        case content(DAppsGrouping)
    }

    enum DAppsGrouping: Equatable {
        case flat([DApp])
        case byAccount([AccountSection])
    }

    struct AccountSection: Identifiable, Equatable {
        let id: String
        let icon: AccountModel.Icon
        let name: String
        let dApps: [DApp]

        init(id: String, icon: AccountModel.Icon, name: String, dApps: [DApp]) {
            assert(!dApps.isEmpty, "Attempt to create AccountSection object with no dApps. Developer mistake.")

            self.id = id
            self.icon = icon
            self.name = name
            self.dApps = dApps
        }
    }

    struct DApp: Identifiable, Equatable {
        let domainModel: WalletConnectConnectedDApp

        var id: String {
            "\(domainModel.session.topic)|\(domainModel.accountId)"
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

        var isVerified: Bool {
            domainModel.verificationStatus.isVerified
        }
    }
}

// MARK: - Modal Dialog

extension ConnectionsViewState {
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

extension ConnectionsViewState.ModalDialog {
    struct Alert: Equatable {
        let title: String
        let subtitle: String
        let buttons: [AlertButton]

        static func disconnectAll(action: @escaping () -> Void) -> Alert {
            Alert(
                title: Localization.wcConnectionsDisconnectAllAlertTitle,
                subtitle: Localization.wcConnectionsDisconnectAllAlertDesc,
                buttons: [
                    AlertButton.cancel,
                    AlertButton(title: Localization.commonDisconnect, role: .destructive, action: action),
                ]
            )
        }

        static func walletConnectFeatureDisabled(reason: String) -> Alert {
            Alert(title: Localization.commonWarning, subtitle: reason, buttons: [AlertButton.ok])
        }
    }

    struct AlertButton: Hashable {
        let title: String
        let role: AlertButtonRole?
        let action: () -> Void

        static let cancel = AlertButton(title: Localization.commonCancel, role: .cancel, action: {})
        static let ok = AlertButton(title: Localization.commonOk, role: nil, action: {})

        static func == (lhs: AlertButton, rhs: AlertButton) -> Bool {
            lhs.title == rhs.title && lhs.role == rhs.role
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(title)
            hasher.combine(role)
        }
    }

    enum AlertButtonRole: Hashable {
        case cancel
        case destructive
    }
}
