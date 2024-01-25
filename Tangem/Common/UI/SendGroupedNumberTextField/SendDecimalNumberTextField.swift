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
    private var maxAmountAction: (() -> Void)?
    private var suffix: String? = nil
    private var font: Font = Fonts.Regular.title1

    init(decimalValue: Binding<DecimalNumberTextField.DecimalValue?>, maximumFractionDigits: Int) {
        _decimalValue = decimalValue
        self.maximumFractionDigits = maximumFractionDigits
    }

    var body: some View {
        if #available(iOS 15, *) {
            FocusedDecimalNumberTextField(decimalValue: $decimalValue, maximumFractionDigits: maximumFractionDigits) {
                if let action = maxAmountAction {
                    Button(action: action) {
                        Text(Localization.sendMaxAmountLabel)
                            .style(Fonts.Bold.callout, color: Colors.Text.primary1)
                    }
                }
            }
            .maximumFractionDigits(maximumFractionDigits)
            .font(font)
            .suffix(suffix)
        } else {
            DecimalNumberTextField(
                decimalValue: $decimalValue,
                decimalNumberFormatter: DecimalNumberFormatter(maximumFractionDigits: maximumFractionDigits)
            )
            .maximumFractionDigits(maximumFractionDigits)
            .font(font)
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

    func suffix(_ suffix: String?) -> Self {
        map { $0.suffix = suffix }
    }

    func font(_ font: Font) -> Self {
        map { $0.font = font }
    }
}

@available(iOS 15.0, *)
struct SendDecimalNumberTextField_Previews: PreviewProvider {
    @State private static var decimalValue: DecimalNumberTextField.DecimalValue?

    static var previews: some View {
        VStack(alignment: .leading) {
            StatefulPreviewWrapper(decimalValue) { decimalValue in
                SendDecimalNumberTextField(decimalValue: $decimalValue, maximumFractionDigits: 8)
                    .suffix("WEI")
            }
            .border(Color.purple)

            StatefulPreviewWrapper(decimalValue) { decimalValue in
                SendDecimalNumberTextField(decimalValue: decimalValue, maximumFractionDigits: 8)
                    .suffix(nil)
            }
            .border(Color.orange)

            StatefulPreviewWrapper(decimalValue) { decimalValue in
                SendDecimalNumberTextField(decimalValue: decimalValue, maximumFractionDigits: 8)
                    .suffix("USDT")
            }
            .border(Color.red)

            StatefulPreviewWrapper(decimalValue) { decimalValue in
                SendDecimalNumberTextField(decimalValue: decimalValue, maximumFractionDigits: 8)
                    .suffix("USDT")
                    .font(Fonts.Regular.body)
            }
            .border(Color.green)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Colors.Background.tertiary)
        .padding()
    }
}
