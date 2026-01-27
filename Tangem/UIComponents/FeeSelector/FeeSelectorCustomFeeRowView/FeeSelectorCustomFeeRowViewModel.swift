//
//  FeeSelectorCustomFeeRowData.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

class FeeSelectorCustomFeeRowViewModel: ObservableObject, Identifiable {
    var id: String { title }

    let title: String
    let tooltip: String?
    let suffix: String?
    let isEditable: Bool
    let onFocusChanged: ((Bool) -> Void)?
    let accessibilityIdentifier: String?
    let alternativeAmountAccessibilityIdentifier: String?

    @Published var textFieldViewModel: DecimalNumberTextFieldViewModel
    @Published var alternativeAmount: String?

    init(
        title: String,
        tooltip: String? = nil,
        suffix: String?,
        isEditable: Bool,
        textFieldViewModel: DecimalNumberTextFieldViewModel,
        amountAlternativePublisher: AnyPublisher<String?, Never>,
        onFocusChanged: ((Bool) -> Void)? = nil,
        accessibilityIdentifier: String? = nil,
        alternativeAmountAccessibilityIdentifier: String? = nil
    ) {
        self.title = title
        self.tooltip = tooltip
        self.suffix = suffix
        self.isEditable = isEditable
        self.textFieldViewModel = textFieldViewModel
        self.onFocusChanged = onFocusChanged
        self.accessibilityIdentifier = accessibilityIdentifier
        self.alternativeAmountAccessibilityIdentifier = alternativeAmountAccessibilityIdentifier

        amountAlternativePublisher.assign(to: &$alternativeAmount)
    }
}
