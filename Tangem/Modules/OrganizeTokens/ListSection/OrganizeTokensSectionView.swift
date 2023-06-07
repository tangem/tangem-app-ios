//
//  OrganizeTokensSectionView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct OrganizeTokensSectionView: View {
    let viewModel: OrganizeTokensListSectionViewModel

    var body: some View {
        HStack(spacing: 12.0) {
            Text(viewModel.title)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                .lineLimit(1)

            Spacer(minLength: 0.0)

            if viewModel.isDraggable {
                Assets.OrganizeTokens.groupDragAndDropIcon
                    .image
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(size: .init(bothDimensions: 20.0))
                    .foregroundColor(Colors.Icon.informative)
            }
        }
        .padding(.horizontal, 14.0)
        .frame(height: 42.0)
    }
}

// MARK: - Previews

struct OrganizeTokensSectionView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Group {
                OrganizeTokensSectionView(
                    viewModel: .init(
                        title: "Bitcoin network",
                        isDraggable: true,
                        items: []
                    )
                )

                OrganizeTokensSectionView(
                    viewModel: .init(
                        title: "Bitcoin network",
                        isDraggable: false,
                        items: []
                    )
                )
            }
            .background(Colors.Background.primary)
        }
        .padding()
        .previewLayout(.sizeThatFits)
        .background(Colors.Background.secondary)
    }
}
