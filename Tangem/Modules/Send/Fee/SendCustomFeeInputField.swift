//
//  SendCustomFeeInputField.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendCustomFeeInputField: View {
    @ObservedObject var viewModel: SendCustomFeeInputFieldModel

    var body: some View {
        GroupedSection(viewModel) { viewModel in
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.title)
                    .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                    .lineLimit(1)

                HStack {
                    DecimalNumberTextField(
                        decimalValue: $viewModel.amount,
                        decimalNumberFormatter: .init(maximumFractionDigits: viewModel.fractionDigits),
                        font: Fonts.Regular.subheadline
                    )

                    if let amountAlternative = viewModel.amountAlternative {
                        Text(amountAlternative)
                            .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
                            .lineLimit(1)
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
                amountPublisher: .just(output: .internal(1234)),
                fractionDigits: 2,
                amountAlternativePublisher: .just(output: "0.41 $"),
                footer: "Maximum commission amount",
                didChangeField: { _ in }
            )
        )

        SendCustomFeeInputField(
            viewModel: SendCustomFeeInputFieldModel(
                title: "Fee up to",
                amountPublisher: .just(output: .internal(1234)),
                fractionDigits: 2,
                amountAlternativePublisher: .just(output: nil),
                footer: "Maximum commission amount",
                didChangeField: { _ in }
            )
        )
    }
    .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
}
