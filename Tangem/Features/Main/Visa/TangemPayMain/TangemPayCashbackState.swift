//
//  TangemPayCashbackState.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

enum TangemPayCashbackState: Equatable {
    case content(TangemPayCashback.Summary)
    case failed(isReloading: Bool)
}

// MARK: - Menu row content

extension TangemPayCashbackState {
    var menuTitle: String {
        switch self {
        case .content(let summary):
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

    var isReloading: Bool {
        switch self {
        case .content: false
        case .failed(let isReloading): isReloading
        }
    }
}

// MARK: - Formatting

extension TangemPayCashbackState {
    static let monthSymbols = DateFormatter().monthSymbols ?? []

    static func monthName(_ month: Int) -> String {
        monthSymbols.indices.contains(month - 1) ? monthSymbols[month - 1] : ""
    }
}
