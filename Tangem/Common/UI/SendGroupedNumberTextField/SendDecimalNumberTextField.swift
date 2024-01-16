//
//  SendDecimalNumberTextField.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct SendDecimalNumberTextField: View {
    @Binding private var decimalValue: DecimalNumberTextField.DecimalValue?
    private var maximumFractionDigits: Int
    private let font: Font
    private var maxAmountAction: (() -> Void)?

    init(decimalValue: Binding<DecimalNumberTextField.DecimalValue?>, maximumFractionDigits: Int, font: Font) {
        _decimalValue = decimalValue
        self.maximumFractionDigits = maximumFractionDigits
        self.font = font
    }

    var body: some View {
        if #available(iOS 15, *) {
            FocusedDecimalNumberTextField(decimalValue: $decimalValue, maximumFractionDigits: maximumFractionDigits, font: font) {
                if let action = maxAmountAction {
                    Button(action: action) {
                        Text(Localization.sendMaxAmountLabel)
                            .style(Fonts.Bold.callout, color: Colors.Text.primary1)
                    }
                }
            }
            .maximumFractionDigits(maximumFractionDigits)
        } else {
            DecimalNumberTextField(
                decimalValue: $decimalValue,
                decimalNumberFormatter: DecimalNumberFormatter(maximumFractionDigits: maximumFractionDigits),
                font: font
            )
            .maximumFractionDigits(maximumFractionDigits)
        }
    }
}

// MARK: - Setupable

extension SendDecimalNumberTextField: Setupable {
    func maximumFractionDigits(_ digits: Int) -> Self {
        map { $0.maximumFractionDigits = digits }
    }

    func maxAmountAction(_ action: (() -> Void)?) -> Self {
        map { $0.maxAmountAction = action }
    }
}
