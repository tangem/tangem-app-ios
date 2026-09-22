//
//  PolymarketDepositNotificationEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

enum PolymarketDepositNotificationEvent: Hashable {
    case depositLimits(assetSymbol: String, networkName: String, minimumFormatted: String)
}

// MARK: - NotificationEvent protocol conformance

extension PolymarketDepositNotificationEvent: NotificationEvent {
    var title: NotificationView.Title? {
        .string(titleText)
    }

    var description: String? {
        descriptionText
    }

    var colorScheme: NotificationView.ColorScheme {
        .secondary
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .depositLimits:
            return .init(iconType: .image(Assets.blueCircleWarning))
        }
    }

    var bannerRing: NotificationBanner.Ring? {
        switch self {
        case .depositLimits:
            return .info
        }
    }

    var redesignedBannerContent: RedesignedBannerContent? {
        var title = AttributedString(titleText)
        title.font = .system(size: 14, weight: .medium)

        return RedesignedBannerContent(
            title: .attributed(title),
            icon: NotificationView.MessageIcon(
                iconType: .image(DesignSystem.Icons.Info.regular20),
                renderingMode: .template,
                color: DesignSystem.Color.iconPrimary,
                isLeading: false,
                size: CGSize(bothDimensions: 20)
            )
        )
    }

    var severity: NotificationView.Severity {
        .info
    }

    var isDismissable: Bool {
        false
    }

    var buttonAction: NotificationButtonAction? {
        nil
    }

    var analyticsEvent: Analytics.Event? {
        nil
    }

    var analyticsParams: [Analytics.ParameterKey: String] {
        [:]
    }

    var isOneShotAnalyticsEvent: Bool {
        false
    }
}

// MARK: - Private implementation

private extension PolymarketDepositNotificationEvent {
    var titleText: String {
        switch self {
        case .depositLimits(let assetSymbol, let networkName, _):
            return Localization.receiveBottomSheetWarningTitle(assetSymbol, networkName)
        }
    }

    var descriptionText: String {
        switch self {
        case .depositLimits(_, _, let minimumFormatted):
            return Localization.predictionAddFundsNotificationLimitsDescription(minimumFormatted)
        }
    }
}
