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
    var dAppVerificationWarningSection: DAppVerificationWarningSection?
    var walletSection: WalletSection
    var networksSection: NetworksSection

    let cancelButtonTitle = Localization.commonCancel
    let connectButtonTitle = Localization.wcCommonConnect

    static func loading(walletName: String, walletSelectionIsAvailable: Bool) -> WalletConnectDAppConnectionRequestViewState {
        WalletConnectDAppConnectionRequestViewState(
            dAppDescriptionSection: WalletConnectDAppDescriptionViewModel.loading,
            connectionRequestSection: ConnectionRequestSection.loading,
            dAppVerificationWarningSection: nil,
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
                WalletConnectDAppDescriptionViewModel.ContentState(dAppData: proposal.dApp, verificationStatus: proposal.verificationStatus)
            ),
            connectionRequestSection: ConnectionRequestSection.content(ConnectionRequestSection.ContentState(isExpanded: false)),
            dAppVerificationWarningSection: DAppVerificationWarningSection(proposal.verificationStatus),
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

extension WalletConnectDAppConnectionRequestViewState {
    struct DAppVerificationWarningSection {
        enum Severity {
            case warning
            case critical
        }

        let severity: Severity
        let iconAsset: ImageType
        let title: String
        let body: String

        static let unknownDomain = DAppVerificationWarningSection(
            severity: .warning,
            iconAsset: Assets.attention20,
            title: Localization.wcAlertAuditUnknownDomain,
            body: Localization.wcAlertDomainIssuesDescription
        )

        static let knownSecurityRisk = DAppVerificationWarningSection(
            severity: .critical,
            iconAsset: Assets.redCircleWarning,
            title: Localization.wcNotificationSecurityRiskTitle,
            body: Localization.wcNotificationSecurityRiskSubtitle
        )

        static let domainMismatch = DAppVerificationWarningSection(
            severity: .critical,
            iconAsset: Assets.redCircleWarning,
            title: "Domain mismatch",
            body: "This website has a domain that does not match the sender or this request. Approving may lead to loss of funds"
        )

        static let scamDomain = DAppVerificationWarningSection(
            severity: .critical,
            iconAsset: Assets.redCircleWarning,
            title: "Scam domain",
            body: "We have noticed that this domain is SCAM. We don’t advise you to connect your wallet."
        )

        private init(severity: Severity, iconAsset: ImageType, title: String, body: String) {
            self.severity = severity
            self.iconAsset = iconAsset
            self.title = title
            self.body = body
        }

        init?(_ verificationStatus: WalletConnectDAppVerificationStatus) {
            switch verificationStatus {
            case .verified:
                return nil

            case .unknownDomain:
                self = .unknownDomain

            case .malicious:
                self = .knownSecurityRisk
            }
        }
    }
}

// MARK: - Wallet section

extension WalletConnectDAppConnectionRequestViewState {
    struct WalletSection: Equatable {
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
            if case .content(let contentState) = state, case .available = contentState.selectionMode {
                return Assets.Glyphs.selectIcon
            }

            return nil
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
