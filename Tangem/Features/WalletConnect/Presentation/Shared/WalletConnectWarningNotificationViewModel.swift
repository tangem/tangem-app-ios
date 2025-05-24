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

    init(containerStyle: ContainerStyle, severity: Severity, title: String, body: String) {
        self.containerStyle = containerStyle
        self.severity = severity

        self.iconAsset = switch severity {
        case .attention:
            Assets.attention20
        case .critical:
            Assets.redCircleWarning
        }

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

// MARK: - DApp verification warnings

extension WalletConnectWarningNotificationViewModel {
    static let dAppUnknownDomain = WalletConnectWarningNotificationViewModel(
        containerStyle: .standAloneSection,
        severity: .attention,
        title: Localization.wcAlertAuditUnknownDomain,
        body: Localization.wcAlertDomainIssuesDescription
    )

    static let dAppKnownSecurityRisk = WalletConnectWarningNotificationViewModel(
        containerStyle: .standAloneSection,
        severity: .critical,
        title: Localization.wcNotificationSecurityRiskTitle,
        body: Localization.wcNotificationSecurityRiskSubtitle
    )

    static let dAppDomainMismatch = WalletConnectWarningNotificationViewModel(
        containerStyle: .standAloneSection,
        severity: .critical,
        title: "Domain mismatch",
        body: "This website has a domain that does not match the sender or this request. Approving may lead to loss of funds"
    )

    static let dAppScamDomain = WalletConnectWarningNotificationViewModel(
        containerStyle: .standAloneSection,
        severity: .critical,
        title: "Scam domain",
        body: "We have noticed that this domain is SCAM. We don’t advise you to connect your wallet."
    )
}

// MARK: - DApp networks warnings

extension WalletConnectWarningNotificationViewModel {
    static func requiredNetworksAreUnavailableForSelectedWallet(_ blockchainNames: [String]) -> WalletConnectWarningNotificationViewModel {
        WalletConnectWarningNotificationViewModel(
            containerStyle: .embedded,
            severity: .attention,
            title: Localization.wcMissingRequiredNetworkTitle,
            body: Localization.wcMissingRequiredNetworkDescription(blockchainNames.joined(separator: ", "))
        )
    }
}
