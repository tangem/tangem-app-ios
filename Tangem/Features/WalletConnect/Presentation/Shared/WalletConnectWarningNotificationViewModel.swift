//
//  WalletConnectWarningNotificationViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAssets
import TangemLocalization

// [REDACTED_TODO_COMMENT]
struct WalletConnectWarningNotificationViewModel: Equatable {
    let containerStyle: ContainerStyle
    let severity: Severity
    let iconAsset: ImageType
    let title: String
    let body: String
}

extension WalletConnectWarningNotificationViewModel {
    enum ContainerStyle: Equatable {
        case standAloneSection
        case embedded
    }

    enum Severity: Equatable {
        case attention
        case critical
    }
}

// MARK: - DApp verification warnings

extension WalletConnectWarningNotificationViewModel {
    static let dAppUnknownDomain = WalletConnectWarningNotificationViewModel(
        containerStyle: .standAloneSection,
        severity: .attention,
        iconAsset: Assets.attention20,
        title: Localization.wcAlertAuditUnknownDomain,
        body: Localization.wcAlertDomainIssuesDescription
    )

    static let dAppKnownSecurityRisk = WalletConnectWarningNotificationViewModel(
        containerStyle: .standAloneSection,
        severity: .critical,
        iconAsset: Assets.redCircleWarning,
        title: Localization.wcNotificationSecurityRiskTitle,
        body: Localization.wcNotificationSecurityRiskSubtitle
    )

    static let dAppDomainMismatch = WalletConnectWarningNotificationViewModel(
        containerStyle: .standAloneSection,
        severity: .critical,
        iconAsset: Assets.redCircleWarning,
        title: "Domain mismatch",
        body: "This website has a domain that does not match the sender or this request. Approving may lead to loss of funds"
    )

    static let dAppScamDomain = WalletConnectWarningNotificationViewModel(
        containerStyle: .standAloneSection,
        severity: .critical,
        iconAsset: Assets.redCircleWarning,
        title: "Scam domain",
        body: "We have noticed that this domain is SCAM. We don’t advise you to connect your wallet."
    )
}

// MARK: - DApp networks warnings

extension WalletConnectWarningNotificationViewModel {
    static var noBlockchainsAreSelected = WalletConnectWarningNotificationViewModel(
        containerStyle: .embedded,
        severity: .attention,
        iconAsset: Assets.WalletConnect.yellowWarningCircle,
        title: "Specify selected networks",
        body: "At least one network is required for dApp connection"
    )

    static func requiredNetworksAreUnavailableForSelectedWallet(_ blockchainNames: [String]) -> WalletConnectWarningNotificationViewModel {
        WalletConnectWarningNotificationViewModel(
            containerStyle: .embedded,
            severity: .attention,
            iconAsset: Assets.WalletConnect.yellowWarningCircle,
            title: Localization.wcMissingRequiredNetworkTitle,
            body: Localization.wcMissingRequiredNetworkDescription(blockchainNames.joined(separator: ", "))
        )
    }
}
