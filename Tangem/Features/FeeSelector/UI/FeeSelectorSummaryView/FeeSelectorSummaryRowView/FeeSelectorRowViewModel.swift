//
//  FeeSelectorRowViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemMacro
import SwiftUI
import TangemUI
import TangemFoundation

struct FeeSelectorRowViewModel: Hashable {
    let rowType: RowType
    let title: String
    let subtitle: SubtitleType
    let availability: Availability
    let accessibilityIdentifier: String

    // MARK: - Expansion

    @IgnoredEquatable
    var expandAction: (() -> Void)?

    // MARK: - Selection

    let isSelected: Bool

    @IgnoredEquatable
    var selectAction: (() -> Void)?
}

// MARK: - Configurations

extension FeeSelectorRowViewModel {
    /// Plain (no selection and no expansion)
    init(rowType: RowType, title: String, subtitle: SubtitleType, accessibilityIdentifier: String, availability: Availability = .available) {
        self.rowType = rowType
        self.title = title
        self.subtitle = subtitle
        self.availability = availability
        self.accessibilityIdentifier = accessibilityIdentifier

        // expansion and selection disabled
        expandAction = nil
        isSelected = false
        selectAction = nil
    }

    /// Optional expansion-only configuration: provides expandAction, disables selection
    init(rowType: RowType, title: String, subtitle: SubtitleType, accessibilityIdentifier: String, availability: Availability = .available, expandAction: (() -> Void)?) {
        self.rowType = rowType
        self.title = title
        self.subtitle = subtitle
        self.availability = availability
        self.accessibilityIdentifier = accessibilityIdentifier
        self.expandAction = expandAction

        // selection disabled
        isSelected = false
        selectAction = nil
    }

    /// Selection-only configuration: provides selection state and action, disables expansion
    init(
        rowType: RowType,
        title: String,
        subtitle: SubtitleType,
        accessibilityIdentifier: String,
        availability: Availability = .available,
        isSelected: Bool,
        selectAction: @escaping () -> Void
    ) {
        self.rowType = rowType
        self.title = title
        self.subtitle = subtitle
        self.availability = availability
        self.accessibilityIdentifier = accessibilityIdentifier

        self.isSelected = isSelected
        self.selectAction = selectAction

        // expansion disabled
        expandAction = nil
    }
}

extension FeeSelectorRowViewModel {
    @CaseFlagable
    enum RowType {
        case fee(image: Image)
        case token(tokenIconInfo: TokenIconInfo)
    }

    enum SubtitleType: Hashable {
        case fee(LoadableTextView.State)
        case balance(LoadableTokenBalanceView.State)
    }

    @CaseFlagable
    enum Availability {
        case available
        case noBalance
        case notSupported
        case unavailable
        case notEnoughBalance
    }
}

extension FeeSelectorRowViewModel.RowType: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .fee:
            hasher.combine(0)
        case .token(let info):
            hasher.combine(1)
            hasher.combine(info)
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.fee, .fee): return true
        case (.token(let l), .token(let r)): return l == r
        default: return false
        }
    }
}
