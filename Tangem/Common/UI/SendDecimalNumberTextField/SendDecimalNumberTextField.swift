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

    private var initialFocusBehavior: InitialFocusBehavior = .noFocus
    private var maximumFractionDigits: Int
    private var maxAmountAction: (() -> Void)?
    private var suffix: String? = nil
    private var font: Font = Fonts.Regular.title1
    private var alignment: Alignment = .leading

    init(decimalValue: Binding<DecimalNumberTextField.DecimalValue?>, maximumFractionDigits: Int) {
        _decimalValue = decimalValue
        self.maximumFractionDigits = maximumFractionDigits
    }

    var body: some View {
        FocusedDecimalNumberTextField(decimalValue: $decimalValue, maximumFractionDigits: maximumFractionDigits) {
            if let action = maxAmountAction {
                Button(action: action) {
                    Text(Localization.sendMaxAmountLabel)
                        .style(Fonts.Bold.callout, color: Colors.Text.primary1)
                }
            }
        }
        .alignment(alignment)
        .initialFocusBehavior(initialFocusBehavior)
        .maximumFractionDigits(maximumFractionDigits)
        .appearance(.init(font: font))
        .suffix(suffix)
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

    func alignment(_ alignment: Alignment) -> Self {
        map { $0.alignment = alignment }
    }

    func initialFocusBehavior(_ initialFocusBehavior: InitialFocusBehavior) -> Self {
        map { $0.initialFocusBehavior = initialFocusBehavior }
    }
}

struct SendDecimalNumberTextField_Previews: PreviewProvider {
    @State private static var decimalValue: DecimalNumberTextField.DecimalValue?

    static var previews: some View {
        ZStack {
            Colors.Background.tertiary.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                SendDecimalNumberTextField(decimalValue: $decimalValue, maximumFractionDigits: 8)
                    .suffix("WEI")
                    .padding()
                    .background(Colors.Background.action)

                SendDecimalNumberTextField(decimalValue: $decimalValue, maximumFractionDigits: 8)
                    .suffix(nil)
                    .padding()
                    .background(Colors.Background.action)

                SendDecimalNumberTextField(decimalValue: $decimalValue, maximumFractionDigits: 8)
                    .suffix("USDT")
                    .padding()
                    .background(Colors.Background.action)

                SendDecimalNumberTextField(decimalValue: $decimalValue, maximumFractionDigits: 8)
                    .suffix("USDT")
                    .font(Fonts.Regular.body)
                    .alignment(.leading)
                    .padding()
                    .background(Colors.Background.action)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }
}
