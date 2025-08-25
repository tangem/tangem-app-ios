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

    @Published var textFieldViewModel: DecimalNumberTextField.ViewModel
    @Published var alternativeAmount: String?

    init(
        title: String,
        tooltip: String? = nil,
        suffix: String?,
        isEditable: Bool,
        textFieldViewModel: DecimalNumberTextField.ViewModel,
        amountAlternativePublisher: AnyPublisher<String?, Never>,
        onFocusChanged: ((Bool) -> Void)? = nil
    ) {
        self.title = title
        self.tooltip = tooltip
        self.suffix = suffix
        self.isEditable = isEditable
        self.textFieldViewModel = textFieldViewModel
        self.onFocusChanged = onFocusChanged

        amountAlternativePublisher.assign(to: &$alternativeAmount)
    }
}
