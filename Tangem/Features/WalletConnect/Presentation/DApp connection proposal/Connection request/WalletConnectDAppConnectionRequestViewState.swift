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

    var dAppDescriptionSection: DAppDescriptionSection
    var connectionRequestSection: ConnectionRequestSection
    var walletSection: WalletSection
    var networksSection: NetworksSection

    let cancelButtonTitle = Localization.commonCancel
    let connectButtonTitle = Localization.wcCommonConnect

    static func loading(walletName: String, walletSelectionIsAvailable: Bool) -> WalletConnectDAppConnectionRequestViewState {
        WalletConnectDAppConnectionRequestViewState(
            dAppDescriptionSection: DAppDescriptionSection(state: .loading),
            connectionRequestSection: ConnectionRequestSection(state: .loading(.init())),
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
            dAppDescriptionSection: DAppDescriptionSection(
                state: .content(
                    DAppDescriptionSection.ContentState(
                        iconURL: proposal.dApp.icon,
                        name: proposal.dApp.name,
                        domain: proposal.dApp.domain.host
                    )
                )
            ),
            connectionRequestSection: ConnectionRequestSection(state: .content(ConnectionRequestSection.ContentState(isExpanded: false))),
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

// MARK: - DApp description section

extension WalletConnectDAppConnectionRequestViewState {
    struct DAppDescriptionSection {
        enum State {
            case loading
            case content(ContentState)
        }

        struct ContentState: Hashable {
            let iconURL: URL?
            let fallbackIconAsset = Assets.Glyphs.explore
            let name: String
            let domain: String?
        }

        let state: Self.State
    }
}

// MARK: - Connection request section

extension WalletConnectDAppConnectionRequestViewState {
    struct ConnectionRequestSection {
        enum State {
            case loading(LoadingState)
            case content(ContentState)
        }

        struct LoadingState {
            let iconAsset = Assets.Glyphs.load
            let label = "Connecting"
        }

        struct ContentState {
            let iconAsset = Assets.Glyphs.connectNew
            let label = Localization.wcConnectionRequest
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

        let state: Self.State
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
        let selectionIsAvailable: Bool
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
