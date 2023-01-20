//
//  SendGroupedNumberTextField.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct SendGroupedNumberTextField: View {
    @Binding private var decimalValue: Decimal?
    private var maximumFractionDigits: Int
    private var didTapMaxAmountAction: (() -> Void)?

    init(decimalValue: Binding<Decimal?>, maximumFractionDigits: Int) {
        _decimalValue = decimalValue
        self.maximumFractionDigits = maximumFractionDigits
    }

    var body: some View {
        if #available(iOS 15, *) {
            FocusedGroupedNumberTextField(decimalValue: $decimalValue, maximumFractionDigits: maximumFractionDigits) {
                EmptyView()

                // [REDACTED_TODO_COMMENT]
                // Button(Localization.sendMaxAmountLabel) {
                //     didTapMaxAmountAction?()
                // }
            }
            .maximumFractionDigits(maximumFractionDigits)
        } else {
            GroupedNumberTextField(decimalValue: $decimalValue, maximumFractionDigits: maximumFractionDigits)
                .maximumFractionDigits(maximumFractionDigits)
        }
    }
}

// MARK: - Setupable

extension SendGroupedNumberTextField: Setupable {
    func maximumFractionDigits(_ digits: Int) -> Self {
        map { $0.maximumFractionDigits = digits }
    }

    func didTapMaxAmount(_ action: @escaping () -> Void) -> Self {
        map { $0.didTapMaxAmountAction = action }
    }
}
