//
//  SendDestinationCompactView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemLocalization
import TangemAssets

struct SendDestinationCompactView: View {
    @ObservedObject var viewModel: SendDestinationCompactViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Localization.sendRecipient)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

            address
        }
        .infinityFrame()
        .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: 12, horizontalPadding: 14)
    }

    private var address: some View {
        HStack(alignment: .center, spacing: .zero) {
            VStack(alignment: .leading, spacing: 2) {
                SUITextView(
                    viewModel: .init(),
                    text: .constant(viewModel.address),
                    font: UIFonts.Regular.body,
                    color: UIColor.textPrimary1
                )
                .disabled(true)

                if let resolved = viewModel.resolved {
                    Text(resolved)
                        .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)
                        .truncationMode(.middle)
                }

                if let additionalField = viewModel.additionalField {
                    Text(additionalField)
                        .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
                        .lineLimit(1)
                        .padding(.top, 6) // extra space
                }
            }

            Spacer(minLength: 24)

            AddressIconView(viewModel: AddressIconViewModel(address: viewModel.address))
        }
    }
}
