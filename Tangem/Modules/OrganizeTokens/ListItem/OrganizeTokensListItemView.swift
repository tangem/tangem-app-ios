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
                customTokenColor: viewModel.customTokenColor,
                blockchainIconName: viewModel.blockchainIconName,
                hasMonochromeIcon: viewModel.hasMonochromeIcon,
                isCustom: viewModel.isCustom
            )

            // Fixed size spacer
            FixedSpacer(width: Constants.spacerLength, length: Constants.spacerLength)
                .layoutPriority(1000.0)

            VStack(alignment: .leading, spacing: 4) {
                if let errorMessage = viewModel.errorMessage {
                    makeMiddleComponent(withErrorMessage: errorMessage)
                } else {
                    defaultMiddleComponent
                }
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
        .frame(minHeight: 68)
    }

    @ViewBuilder
    private var defaultMiddleComponent: some View {
        Text(viewModel.name)
            .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
            .lineLimit(1)

        LoadableTextView(
            state: viewModel.balance,
            font: Fonts.Regular.footnote,
            textColor: Colors.Text.tertiary,
            loaderSize: .init(width: 52, height: 12),
            isSensitiveText: true
        )
    }

    @ViewBuilder
    private func makeMiddleComponent(withErrorMessage errorMessage: String) -> some View {
        Text(viewModel.name)
            .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
            .lineLimit(1)

        Text(errorMessage)
            .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            .lineLimit(1)
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
