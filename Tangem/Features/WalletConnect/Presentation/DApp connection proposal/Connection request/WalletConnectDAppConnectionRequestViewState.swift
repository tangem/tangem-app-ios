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

struct WalletConnectDAppConnectionRequestViewState: Equatable {
    let navigationTitle = Localization.wcWalletConnect

    var dAppDescriptionSection: WalletConnectDAppDescriptionViewModel
    var connectionRequestSection: ConnectionRequestSection
    var dAppVerificationWarningSection: WalletConnectWarningNotificationViewModel?

    var walletSection: WalletSection
    var networksSection: NetworksSection
    var networksWarningSection: WalletConnectWarningNotificationViewModel?

    let cancelButtonTitle = Localization.commonCancel
    let connectButtonTitle = Localization.wcCommonConnect

    static func loading(selectedUserWalletName: String, walletSelectionIsAvailable: Bool) -> WalletConnectDAppConnectionRequestViewState {
        WalletConnectDAppConnectionRequestViewState(
            dAppDescriptionSection: WalletConnectDAppDescriptionViewModel.loading,
            connectionRequestSection: ConnectionRequestSection.loading,
            dAppVerificationWarningSection: nil,
            walletSection: WalletSection(selectedUserWalletName: selectedUserWalletName, selectionIsAvailable: walletSelectionIsAvailable),
            networksSection: NetworksSection(state: .loading),
            networksWarningSection: nil
        )
    }

    static func content(
        proposal: WalletConnectDAppConnectionProposal,
        selectedUserWalletName: String,
        walletSelectionIsAvailable: Bool,
        blockchainsAvailabilityResult: WalletConnectDAppBlockchainsAvailabilityResult
    ) -> WalletConnectDAppConnectionRequestViewState {
        WalletConnectDAppConnectionRequestViewState(
            dAppDescriptionSection: WalletConnectDAppDescriptionViewModel.content(
                WalletConnectDAppDescriptionViewModel.ContentState(
                    dAppData: proposal.dApp,
                    verificationStatus: proposal.verificationStatus
                )
            ),
            connectionRequestSection: ConnectionRequestSection.content(ConnectionRequestSection.ContentState(isExpanded: false)),
            dAppVerificationWarningSection: WalletConnectWarningNotificationViewModel(proposal.verificationStatus),
            walletSection: WalletSection(selectedUserWalletName: selectedUserWalletName, selectionIsAvailable: walletSelectionIsAvailable),
            networksSection: NetworksSection(blockchainsAvailabilityResult: blockchainsAvailabilityResult)
        )
    }
}

// MARK: - Connection request section

extension WalletConnectDAppConnectionRequestViewState {
    enum ConnectionRequestSection: Equatable {
        struct LoadingState: Equatable {
            let iconAsset = Assets.Glyphs.load
            let label = "Connecting"
        }

        struct ContentState: Equatable {
            let iconAsset = Assets.Glyphs.connectNew
            let label = Localization.wcConnectionRequest
            let trailingIconAsset = Assets.Glyphs.chevronRightNew
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

        mutating func toggleIsExpanded() {
            guard case .content(var contentState) = self else { return }
            contentState.isExpanded.toggle()
            self = .content(contentState)
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

// MARK: - DApp verification warning section

extension WalletConnectWarningNotificationViewModel {
    init?(_ verificationStatus: WalletConnectDAppVerificationStatus) {
        switch verificationStatus {
        case .verified:
            return nil

        case .unknownDomain:
            self = .dAppUnknownDomain

        case .malicious:
            self = .dAppKnownSecurityRisk
        }
    }
}

// MARK: - Wallet section

extension WalletConnectDAppConnectionRequestViewState {
    struct WalletSection: Equatable {
        let iconAsset = Assets.Glyphs.walletNew
        let label = Localization.wcCommonWallet
        var selectedUserWalletName: String
        var selectionIsAvailable: Bool
        var trailingIconAsset: ImageType?

        init(selectedUserWalletName: String, selectionIsAvailable: Bool) {
            self.selectedUserWalletName = selectedUserWalletName
            self.selectionIsAvailable = selectionIsAvailable
            trailingIconAsset = selectionIsAvailable ? Assets.Glyphs.selectIcon : nil
        }
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

        init(blockchainsAvailabilityResult: WalletConnectDAppBlockchainsAvailabilityResult) {
            guard blockchainsAvailabilityResult.unavailableRequiredBlockchains.isEmpty else {
                self.init(state: .content(.init(selectionMode: .requiredNetworksAreMissing)))
                return
            }

            let availableSelectionMode = AvailableSelectionMode(
                blockchains: blockchainsAvailabilityResult.availableBlockchains.map(\.blockchain)
            )
            let contentState = ContentState(selectionMode: .available(availableSelectionMode))
            self.init(state: .content(contentState))
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

        init(blockchains: [BlockchainSdk.Blockchain]) {
            let maximumIconsCount = 4
            let imageProvider = NetworkImageProvider()
            let prefixedBlockchains: [BlockchainSdk.Blockchain]

            let shouldShowRemainingBlockchainsCounter = blockchains.count > maximumIconsCount

            if shouldShowRemainingBlockchainsCounter {
                let blockchainsCountToTake = maximumIconsCount - 1
                prefixedBlockchains = Array(blockchains.prefix(blockchainsCountToTake))
                remainingBlockchainsCounter = "+\(blockchains.count - blockchainsCountToTake)"
            } else {
                prefixedBlockchains = blockchains
                remainingBlockchainsCounter = nil
            }

            blockchainLogoAssets = prefixedBlockchains.map { blockchain in
                imageProvider.provide(by: blockchain, filled: true)
            }
        }
    }
}
