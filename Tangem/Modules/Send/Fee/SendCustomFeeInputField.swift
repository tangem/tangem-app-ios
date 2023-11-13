//
//  SendCustomFeeInputField.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

class SendCustomFeeInputFieldModel: Identifiable {
    let title = "Fee up to"
    let footer = "Maximum commission amount"

    var amount: Binding<DecimalNumberTextField.DecimalValue?> = .constant(.internal(1234))

    let fractionDigits: Int = 2

    @Published var amountAlternative: String? = "0.41 $"
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
        SendCustomFeeInputField(viewModel: SendCustomFeeInputFieldModel())
    }
    .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
}
