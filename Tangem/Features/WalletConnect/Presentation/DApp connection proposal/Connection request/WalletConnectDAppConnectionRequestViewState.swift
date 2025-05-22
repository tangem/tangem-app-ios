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

struct WalletConnectDAppConnectionRequestViewState {
    let navigationTitle = Localization.wcWalletConnect

    var dAppDescriptionSection: WalletConnectDAppDescriptionViewModel
    var connectionRequestSection: ConnectionRequestSection
    var walletSection: WalletSection
    var networksSection: NetworksSection

    let cancelButtonTitle = Localization.commonCancel
    let connectButtonTitle = Localization.wcCommonConnect

    static func loading(walletName: String, walletSelectionIsAvailable: Bool) -> WalletConnectDAppConnectionRequestViewState {
        WalletConnectDAppConnectionRequestViewState(
            dAppDescriptionSection: WalletConnectDAppDescriptionViewModel.loading,
            connectionRequestSection: ConnectionRequestSection.loading,
            walletSection: WalletSection(walletName: walletName, selectionIsAvailable: walletSelectionIsAvailable),
            networksSection: NetworksSection(state: .loading)
        )
    }

    static func content(
        proposal: WalletConnectDAppConnectionProposal,
        walletName: String,
        walletSelectionIsAvailable: Bool
    ) -> WalletConnectDAppConnectionRequestViewState {
        WalletConnectDAppConnectionRequestViewState(
            dAppDescriptionSection: WalletConnectDAppDescriptionViewModel.content(
                WalletConnectDAppDescriptionViewModel.ContentState(dAppData: proposal.dApp)
            ),
            connectionRequestSection: ConnectionRequestSection.content(ConnectionRequestSection.ContentState(isExpanded: false)),
            walletSection: WalletSection(walletName: walletName, selectionIsAvailable: walletSelectionIsAvailable),
            networksSection: NetworksSection(
                state: .content(
                    NetworksSection.ContentState(
                        selectionMode: .requiredNetworksAreMissing // [REDACTED_TODO_COMMENT]
                    )
                )
            )
        )
    }
}

// MARK: - Connection request section

extension WalletConnectDAppConnectionRequestViewState {
    enum ConnectionRequestSection {
        struct LoadingState {
            let iconAsset = Assets.Glyphs.load
            let label = "Connecting"
        }

        struct ContentState {
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

        static let loading = ConnectionRequestSection.loading(LoadingState())
    }
}

extension WalletConnectDAppConnectionRequestViewState.ConnectionRequestSection {
    struct BulletGroup {
        let label: String
        let points: [BulletPoint]
    }

    struct BulletPoint {
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
    struct WalletSection {
        let iconAsset = Assets.Glyphs.walletNew
        let label = Localization.wcCommonWallet
        var walletName: String
        var selectionIsAvailable: Bool
        var trailingIconAsset: ImageType?

        init(walletName: String, selectionIsAvailable: Bool) {
            self.walletName = walletName
            self.selectionIsAvailable = selectionIsAvailable
            trailingIconAsset = selectionIsAvailable ? Assets.Glyphs.selectIcon : nil
        }
    }
}

// MARK: - Networks section

extension WalletConnectDAppConnectionRequestViewState {
    struct NetworksSection {
        enum State {
            case loading
            case content(ContentState)
        }

        struct ContentState {
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
    }
}

extension WalletConnectDAppConnectionRequestViewState.NetworksSection {
    enum SelectionMode {
        case available(AvailableSelectionMode)
        case requiredNetworksAreMissing
    }

    struct AvailableSelectionMode {
        let blockchainLogoAssets: [ImageType]
        let remainingBlockchainsCount: UInt?

        init(blockchains: [BlockchainSdk.Blockchain]) {
            let maximumAmountOfIconsToShow = 4
            let imageProvider = NetworkImageProvider()

            blockchainLogoAssets = blockchains.prefix(4).map { blockchain in
                imageProvider.provide(by: blockchain, filled: true)
            }

            let leftBlockchains = blockchains.count - maximumAmountOfIconsToShow

            remainingBlockchainsCount = leftBlockchains > 0
                ? UInt(leftBlockchains)
                : 0
        }
    }
}
