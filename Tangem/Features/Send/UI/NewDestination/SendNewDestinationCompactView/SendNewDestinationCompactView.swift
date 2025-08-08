//
//  SendNewDestinationCompactView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemLocalization
import TangemAssets

struct SendNewDestinationCompactView: View {
    @ObservedObject var viewModel: SendNewDestinationCompactViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Localization.sendRecipient)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

            address

            if let additionalField = viewModel.additionalField {
                Text(additionalField)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
                    .lineLimit(1)
            }
        }
        .infinityFrame()
        .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: 12, horizontalPadding: 14)
    }

    private var address: some View {
        HStack(alignment: .center, spacing: .zero) {
            VStack(alignment: .leading, spacing: 2) {
                SUITextView(viewModel: .init(), text: .constant(viewModel.address), font: UIFonts.Regular.subheadline, color: UIColor.textPrimary1)
                    .disabled(true)

                if let resolved = viewModel.resolved {
                    Text(resolved)
                        .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)
                        .truncationMode(.middle)
                }
            }

            Spacer()

            AddressIconView(viewModel: AddressIconViewModel(address: viewModel.address))
        }
    }
}
