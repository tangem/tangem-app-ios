//
//  WalletConnectWarningNotificationViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAssets
import TangemLocalization

struct WalletConnectWarningNotificationViewModel: Equatable {
    let containerStyle: ContainerStyle
    let severity: Severity
    let iconAsset: ImageType
    let title: String
    let body: String

    init(containerStyle: ContainerStyle, severity: Severity, iconAsset: ImageType, title: String, body: String) {
        self.containerStyle = containerStyle
        self.severity = severity
        self.iconAsset = iconAsset
        self.title = title
        self.body = body
    }
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

// MARK: - Convenience initializers

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
}

// MARK: - DApp networks warnings

extension WalletConnectWarningNotificationViewModel {
    static var noBlockchainsAreSelected = WalletConnectWarningNotificationViewModel(
        containerStyle: .embedded,
        severity: .attention,
        iconAsset: Assets.WalletConnect.yellowWarningCircle,
        title: Localization.wcSpecifyNetworksTitle,
        body: Localization.wcSpecifyNetworksSubtitle
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
