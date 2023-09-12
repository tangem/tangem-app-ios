//
//  OrganizeTokensListItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct OrganizeTokensListItemView: View {
    let viewModel: OrganizeTokensListItemViewModel

    var body: some View {
        HStack(spacing: 0.0) {
            TokenItemViewLeadingComponent(
                name: viewModel.name,
                imageURL: viewModel.imageURL,
                blockchainIconName: viewModel.blockchainIconName,
                hasMonochromeIcon: viewModel.hasMonochromeIcon
            )

            // Fixed size spacer
            Color.clear
                .frame(width: Constants.spacerLength, height: 0.0)
                .layoutPriority(1000.0)
                .hidden()

            // According to the mockups, error state on the Organize Tokens
            // screen looks different than on the main screen
            if let errorMessage = viewModel.errorMessage {
                makeMiddleComponent(withErrorMessage: errorMessage)
            } else {
                defaultMiddleComponent
            }

            // Flexible size spacer
            Spacer(minLength: viewModel.isDraggable ? Constants.spacerLength : 0.0)

            if viewModel.isDraggable {
                Assets.OrganizeTokens.itemDragAndDropIcon
                    .image
                    .foregroundColor(Colors.Icon.informative)
            }
        }
        .padding(14.0)
    }

    private var defaultMiddleComponent: some View {
        TokenItemViewMiddleComponent(
            name: viewModel.name,
            balance: viewModel.balance,
            hasPendingTransactions: false, // Pending transactions aren't shown on the Organize Tokens screen
            hasError: false // Errors are handled by the dedicated component made in `makeMiddleComponent(withErrorMessage:)`
        )
    }

    private func makeMiddleComponent(withErrorMessage errorMessage: String) -> some View {
        VStack(alignment: .leading, spacing: 2.0) {
            Text(viewModel.name)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                .lineLimit(2)

            Text(errorMessage)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .lineLimit(1)
        }
        .padding(.vertical, 2.0)
    }
}

// MARK: - Constants

private extension OrganizeTokensListItemView {
    enum Constants {
        static let spacerLength = 12.0
    }
}

// MARK: - Previews

struct OrganizeTokensListItemView_Previews: PreviewProvider {
    private static let previewProvider = OrganizeTokensPreviewProvider()

    static var previews: some View {
        VStack {
            Group {
                let viewModels = previewProvider
                    .singleMediumSection()
                    .flatMap(\.items)

                ForEach(viewModels) { viewModel in
                    OrganizeTokensListItemView(viewModel: viewModel)
                }
            }
            .background(Colors.Background.primary)
        }
        .padding()
        .previewLayout(.sizeThatFits)
        .background(Colors.Background.secondary)
    }
}
