//
//  OrganizeTokensViewContainerView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct OrganizeTokensViewContainerView: View {
    @State private var contentSizeBinding: CGSize = .zero

    var body: some View {
        ZStack {
            GeometryReader { proxy in
                let containerHeight = proxy.size.height
                let contentHeight = contentSizeBinding.height
                let shouldEmbedContentViewIntoNavigationView = contentHeight
                >= containerHeight * Constants.maxContentViewHeightToContainerViewHeightRatio

                if shouldEmbedContentViewIntoNavigationView {
                    NavigationView {
                        contentView
                            .navigationTitle(Localization.organizeTokensTitle)
                            .navigationBarTitleDisplayMode(.inline)
                    }
                } else {
                    NavigationView {
                        Color.clear
                            .navigationTitle(Localization.organizeTokensTitle)
                            .navigationBarTitleDisplayMode(.inline)
                    }
                    .frame(height: Constants.standaloneNavigationViewHeight)
                    .infinityFrame(alignment: .top)
                    .zIndex(.greatestFiniteMagnitude)

                    VStack(spacing: 0.0) {
                        Constants.dimmingAreaColor
                            .ignoresSafeArea(edges: .top)

                        contentView
                            .frame(
                                height: clamp(
                                    contentHeight,
                                    min: containerHeight * Constants.minContentViewHeightToContainerViewHeightRatio,
                                    max: containerHeight * Constants.maxContentViewHeightToContainerViewHeightRatio
                                )
                            )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        // [REDACTED_TODO_COMMENT]
        let previewProvider = OrganizeTokensPreviewProvider()
        let sections = previewProvider.singleMediumSection()

        OrganizeTokensView(
            viewModel: OrganizeTokensViewModel(
                coordinator: OrganizeTokensCoordinator(),
                sections: sections
            ),
            contentSizeBinding: $contentSizeBinding
        )
    }
}

// MARK: - Constants

private extension OrganizeTokensViewContainerView {
    enum Constants {
        static let minContentViewHeightToContainerViewHeightRatio = 0.6
        static let maxContentViewHeightToContainerViewHeightRatio = 0.9
        static let standaloneNavigationViewHeight = 52.0
        static let dimmingAreaColor = Color(hex: "#F5F5F5")!.opacity(0.8)
    }
}

// MARK: - Previews

struct OrganizeTokensViewContainerView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Assets.Stories
                .amazement
                .image
                .resizable()
                .aspectRatio(contentMode: .fit)

            OrganizeTokensViewContainerView()
        }
    }
}
