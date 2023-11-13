//
//  SendCustomFeeInputField.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

class SendCustomFeeInputFieldModel: Identifiable {
    internal init(title: String, footer: String, amount: Binding<DecimalNumberTextField.DecimalValue?>, fractionDigits: Int, amountAlternative: String? = nil) {
        self.title = title
        self.footer = footer
        self.amount = amount
        self.fractionDigits = fractionDigits
        self.amountAlternative = amountAlternative
    }

    let title: String
    let footer: String
    var amount: Binding<DecimalNumberTextField.DecimalValue?>
    let fractionDigits: Int

    @Published var amountAlternative: String?
}

struct SendCustomFeeInputField: View {
    let viewModel: SendCustomFeeInputFieldModel

    var body: some View {
        GroupedSection(viewModel) { viewModel in
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.title)
                    .style(Fonts.Regular.footnote, color: Colors.Text.secondary)

                HStack {
                    DecimalNumberTextField(
                        decimalValue: viewModel.amount,
                        decimalNumberFormatter: .init(maximumFractionDigits: viewModel.fractionDigits)
                    )

                    if let amountAlternative = viewModel.amountAlternative {
                        Text(amountAlternative)
                            .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
                    }
                }
            }
            .padding(.vertical, 14)
        } footer: {
            Text(viewModel.footer)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
        }
    }
}

#Preview {
    GroupedScrollView {
        SendCustomFeeInputField(
            viewModel: SendCustomFeeInputFieldModel(
                title: "Fee up to",
                footer: "Maximum commission amount",
                amount: .constant(.internal(1234)),
                fractionDigits: 2,
                amountAlternative: "0.41 $"
            )
        )

        SendCustomFeeInputField(
            viewModel: SendCustomFeeInputFieldModel(
                title: "Fee up to",
                footer: "Maximum commission amount",
                amount: .constant(.internal(1234)),
                fractionDigits: 2,
                amountAlternative: nil
            )
        )
    }
    .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
}
