//
//  TangemPayCashbackState.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemLocalization

enum TangemPayCashbackState: Equatable {
    case content(TangemPayCashback.Summary, isReloading: Bool)
    case failed(isReloading: Bool)
}

// MARK: - Menu row content

extension TangemPayCashbackState {
    var menuTitle: String {
        switch self {
        case .content(let summary, _):
            Localization.tangempayCashbackMenuItemTitle(Self.monthName(summary.period.month))

        case .failed:
            Localization.tangempayCashbackTitle
        }
    }

    var menuSubtitle: String? {
        switch self {
        case .content:
            nil

        case .failed(let isReloading):
            isReloading
                ? Localization.tangempayCashbackMenuItemLoading
                : Localization.tangempayCashbackWidgetErrorDescription
        }
    }

    var menuIcon: ImageType {
        switch self {
        case .content, .failed(isReloading: true): DesignSystem.Icons.PercentBackward.regular20
        case .failed(isReloading: false): DesignSystem.Icons.ArrowRefresh.regular20
        }
    }

    var isMenuActionDestructive: Bool {
        switch self {
        case .content, .failed(isReloading: true): false
        case .failed(isReloading: false): true
        }
    }

    var isReloading: Bool {
        switch self {
        case .content(_, let isReloading), .failed(let isReloading): isReloading
        }
    }
}

// MARK: - Formatting

extension TangemPayCashbackState {
    private static let standaloneMonthSymbols = DateFormatter().standaloneMonthSymbols ?? []

    static func monthName(_ month: Int) -> String {
        standaloneMonthSymbols.indices.contains(month - 1) ? standaloneMonthSymbols[month - 1] : ""
    }
}
