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
    let severity: Severity
    let iconAsset: ImageType
    let title: String
    let body: String
}

extension WalletConnectWarningNotificationViewModel {
    enum Severity: Equatable {
        case attention
        case critical
    }
}

// MARK: - DApp verification status

extension WalletConnectWarningNotificationViewModel {
    static let dAppUnknownDomain = WalletConnectWarningNotificationViewModel(
        severity: .attention,
        iconAsset: Assets.attention20,
        title: Localization.wcAlertAuditUnknownDomain,
        body: Localization.wcAlertDomainIssuesDescription
    )

    static let dAppKnownSecurityRisk = WalletConnectWarningNotificationViewModel(
        severity: .critical,
        iconAsset: Assets.redCircleWarning,
        title: Localization.wcNotificationSecurityRiskTitle,
        body: Localization.wcNotificationSecurityRiskSubtitle
    )

    static let dAppDomainMismatch = WalletConnectWarningNotificationViewModel(
        severity: .critical,
        iconAsset: Assets.redCircleWarning,
        title: "Domain mismatch",
        body: "This website has a domain that does not match the sender or this request. Approving may lead to loss of funds"
    )

    static let dAppScamDomain = WalletConnectWarningNotificationViewModel(
        severity: .critical,
        iconAsset: Assets.redCircleWarning,
        title: "Scam domain",
        body: "We have noticed that this domain is SCAM. We don’t advise you to connect your wallet."
    )
}
