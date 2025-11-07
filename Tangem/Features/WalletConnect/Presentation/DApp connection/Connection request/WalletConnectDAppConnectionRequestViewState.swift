//
//  WalletConnectDAppConnectionRequestViewState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct Foundation.URL
import struct SwiftUI.Color
import enum BlockchainSdk.Blockchain
import TangemAssets
import TangemLocalization
import TangemUI

struct WalletConnectDAppConnectionRequestViewState: Equatable {
    let navigationTitle = Localization.wcWalletConnect

    var dAppDescriptionSection: EntitySummaryView.ViewState
    var connectionRequestSection: ConnectionRequestSection
    var dAppVerificationWarningSection: WalletConnectWarningNotificationViewModel?

    var walletSection: WalletSection?
    var connectionTargetSection: ConnectionTargetSection?
    var networksSection: NetworksSection
    var networksWarningSection: WalletConnectWarningNotificationViewModel?

    let cancelButton = Self.Button(title: Localization.commonCancel, isEnabled: true, isLoading: false)
    var connectButton: Self.Button
}

// MARK: - Connection request section

extension WalletConnectDAppConnectionRequestViewState {
    enum ConnectionRequestSection: Equatable {
        struct LoadingState: Equatable {
            let iconAsset = Assets.Glyphs.load
            let label = Localization.commonConnecting
        }

        struct ContentState: Equatable {
            let iconAsset = Assets.Glyphs.connectNew
            let label = Localization.wcConnectionRequest
            let trailingIconAsset = Assets.Glyphs.chevronDownNew
            var isExpanded: Bool

            let wouldLikeToGroup = BulletGroup(
                label: Localization.wcConnectionReqeustWouldLike,
                points: [
                    BulletPoint(sfSymbol: SFSymbol.checkmark, iconColor: Colors.Icon.accent, title: Localization.wcConnectionReqeustCanViewBalance),
                    BulletPoint(sfSymbol: SFSymbol.checkmark, iconColor: Colors.Icon.accent, title: Localization.wcConnectionReqeustRequestApproval),
                ]
            )

            let wouldNotBeAbleToGroup = BulletGroup(
                label: Localization.wcConnectionReqeustWillNot,
                points: [
                    BulletPoint(sfSymbol: SFSymbol.multiply, iconColor: Colors.Icon.warning, title: Localization.wcConnectionReqeustCantSign),
                ]
            )
        }

        case loading(LoadingState)
        case content(ContentState)

        var id: String {
            switch self {
            case .loading: "loading"
            case .content: "content"
            }
        }

        var iconAsset: ImageType {
            switch self {
            case .loading(let loadingState):
                loadingState.iconAsset
            case .content(let contentState):
                contentState.iconAsset
            }
        }

        var isLoading: Bool {
            if case .loading = self {
                return true
            }
            return false
        }

        var label: String {
            switch self {
            case .loading(let loadingState):
                loadingState.label
            case .content(let contentState):
                contentState.label
            }
        }

        var isExpanded: Bool {
            if case .content(let contentState) = self {
                return contentState.isExpanded
            }

            return false
        }

        static let loading = ConnectionRequestSection.loading(LoadingState())
    }
}

extension WalletConnectDAppConnectionRequestViewState.ConnectionRequestSection {
    struct BulletGroup: Equatable {
        let label: String
        let points: [BulletPoint]
    }

    struct BulletPoint: Hashable {
        let sfSymbol: String
        let iconColor: SwiftUI.Color
        let title: String
    }

    // [REDACTED_TODO_COMMENT]
    private enum SFSymbol {
        static let checkmark = "checkmark"
        static let multiply = "multiply"
    }
}

// MARK: - Wallet section

extension WalletConnectDAppConnectionRequestViewState {
    struct WalletSection: Equatable {
        let iconAsset = Assets.Glyphs.walletNew
        let label = Localization.wcCommonWallet
        let selectionIsAvailable: Bool
        var selectedUserWalletName: String

        init(selectedUserWalletName: String, selectionIsAvailable: Bool) {
            self.selectedUserWalletName = selectedUserWalletName
            self.selectionIsAvailable = selectionIsAvailable
        }
    }
}

// MARK: - Account section

extension WalletConnectDAppConnectionRequestViewState {
    struct ConnectionTargetSection: Equatable {
        let iconAsset = Assets.Glyphs.walletNew
        let selectionIsAvailable: Bool
        let targetName: String
        let target: Target
        let state: State

        var trailingIconAsset: ImageType? {
            switch state {
            case .loading:
                nil
            case .content where selectionIsAvailable == false:
                nil
            case .content:
                Assets.Glyphs.selectIcon
            }
        }

        init(selectionIsAvailable: Bool, targetName: String, target: Target, state: State) {
            self.selectionIsAvailable = selectionIsAvailable
            self.targetName = targetName
            self.target = target
            self.state = state
        }
    }
}

extension WalletConnectDAppConnectionRequestViewState.ConnectionTargetSection {
    enum Target: Equatable {
        case wallet(WCWalletTarget = WCWalletTarget())
        case account(WCAccountTarget)

        struct WCWalletTarget: Equatable {
            let label = Localization.wcCommonWallet
        }

        struct WCAccountTarget: Equatable {
            let label = Localization.accountDetailsTitle
            let icon: AccountModel.Icon
        }
    }

    enum State: Equatable {
        case loading
        case content
    }
}

// MARK: - Networks section

extension WalletConnectDAppConnectionRequestViewState {
    struct NetworksSection: Equatable {
        enum State: Equatable {
            case loading
            case content(ContentState)
        }

        struct ContentState: Equatable {
            let selectionMode: SelectionMode
            let trailingIcon: ImageType

            init(selectionMode: SelectionMode) {
                self.selectionMode = selectionMode
                trailingIcon = switch selectionMode {
                case .available:
                    Assets.Glyphs.selectIcon
                case .requiredNetworksAreMissing:
                    Assets.Glyphs.chevronRightNew
                }
            }
        }

        let iconAsset = Assets.Glyphs.networkNew
        let label = Localization.wcCommonNetworks
        let state: Self.State

        var trailingIconAsset: ImageType? {
            switch state {
            case .loading:
                return nil

            case .content(let contentState):
                switch contentState.selectionMode {
                case .requiredNetworksAreMissing:
                    return Assets.Glyphs.chevronRightNew

                case .available:
                    return Assets.Glyphs.selectIcon
                }
            }
        }

        init(state: Self.State) {
            self.state = state
        }
    }
}

extension WalletConnectDAppConnectionRequestViewState.NetworksSection {
    enum SelectionMode: Equatable {
        case available(AvailableSelectionMode)
        case requiredNetworksAreMissing
    }

    struct AvailableSelectionMode: Equatable {
        let blockchainLogoAssets: [ImageType]
        let remainingBlockchainsCounter: String?
    }
}

// MARK: - Buttons

extension WalletConnectDAppConnectionRequestViewState {
    struct Button: Equatable {
        let title: String
        var isEnabled: Bool
        var isLoading: Bool

        static func connect(isEnabled: Bool, isLoading: Bool) -> WalletConnectDAppConnectionRequestViewState.Button {
            WalletConnectDAppConnectionRequestViewState.Button(title: Localization.wcCommonConnect, isEnabled: isEnabled, isLoading: isLoading)
        }
    }
}
