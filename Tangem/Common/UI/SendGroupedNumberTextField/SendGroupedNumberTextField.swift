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
    @State private var maximumFractionDigits: Int = 8
    private var didTapMaxAmountAction: (() -> Void)?

    init(decimalValue: Binding<Decimal?>) {
        _decimalValue = decimalValue
    }

    var body: some View {
        if #available(iOS 15, *) {
            FocusedGroupedNumberTextField(decimalValue: $decimalValue) {
                Button(Localization.sendMaxAmountLabel) {
                    didTapMaxAmountAction?()
                }
            }
            .maximumFractionDigits(maximumFractionDigits)
        } else {
            GroupedNumberTextField(decimalValue: $decimalValue)
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

