//
//  SendAmountCompactContentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemAccessibilityIdentifiers

struct SendAmountCompactContentView: View {
    @ObservedObject var viewModel: SendAmountCompactContentViewModel
    let namespace: SendAmountView.Namespace

    var body: some View {
        VStack(spacing: 18) {
            TokenIcon(
                tokenIconInfo: viewModel.tokenIconInfo,
                size: CGSize(width: 36, height: 36),
                // Kingfisher shows a grey background even if there has a cached image
                forceKingfisher: false
            )
            .matchedGeometryEffect(id: namespace.names.tokenIcon, in: namespace.id)

            VStack(alignment: .center, spacing: 6) {
                ZStack {
                    SendDecimalNumberTextField(viewModel: viewModel.amountDecimalNumberTextFieldViewModel)
                        .accessibilityIdentifier(SendAccessibilityIdentifiers.sendAmountViewValue)
                        .alignment(.center)
                        .prefixSuffixOptions(viewModel.amountFieldOptions)
                        .minTextScale(SendAmountStep.Constants.amountMinTextScale)
                        .matchedGeometryEffect(id: namespace.names.amountCryptoText, in: namespace.id)
                        .allowsHitTesting(false) // This text field is read-only
                }
                // We have to keep frame until SendDecimalNumberTextField size fix
                // Just on appear it has the zero height. Is cause break animation
                .frame(height: 35)

                // Keep empty text so that the view maintains its place in the layout
                Text(viewModel.alternativeAmount ?? " ")
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    .lineLimit(1)
                    .matchedGeometryEffect(id: namespace.names.amountFiatText, in: namespace.id)
            }
            .infinityFrame(axis: .horizontal, alignment: .center)
        }
    }
}
