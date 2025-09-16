//
//  YieldModuleBottomSheetContainerView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

extension YieldModuleBottomSheetView {
    struct YieldModuleBottomSheetContainerView<
        SubtitleFooter: View,
        BodyContent: View,
        HeaderContent: View,
        TopContent: View
    >: View {
        // MARK: - Properties

        private let title: String?
        private let subtitle: String?

        private let topPadding: CGFloat
        private let horizontalPadding: CGFloat
        private let buttonTopPadding: CGFloat

        // MARK: - UI

        private let topContent: TopContent
        private let subtitleFooter: SubtitleFooter
        private let content: BodyContent
        private let header: HeaderContent
        private let button: MainButton

        // MARK: - Init

        public init(
            title: String? = nil,
            subtitle: String? = nil,
            button: MainButton,
            @ViewBuilder header: () -> HeaderContent = { EmptyView() },
            @ViewBuilder topContent: () -> TopContent = { EmptyView() },
            @ViewBuilder subtitleFooter: () -> SubtitleFooter = { EmptyView() },
            @ViewBuilder content: () -> BodyContent = { EmptyView() },
            topPadding: CGFloat,
            horizontalPadding: CGFloat,
            buttonTopPadding: CGFloat
        ) {
            self.header = header()
            self.topContent = topContent()
            self.subtitleFooter = subtitleFooter()
            self.content = content()

            self.title = title
            self.subtitle = subtitle
            self.topPadding = topPadding
            self.button = button
            self.horizontalPadding = horizontalPadding
            self.buttonTopPadding = buttonTopPadding
        }

        // MARK: - View Body

        var body: some View {
            ScrollView {
                VStack(spacing: .zero) {
                    header

                    topContent

                    titleView
                        .padding(.top, 20)
                        .padding(.horizontal, 14)

                    subtitleView
                        .padding(.top, 8)
                        .padding(.horizontal, 16)

                    subtitleFooter.padding(.top, 26)

                    content.padding(.top, 24)

                    button.padding(.top, 32)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 18)
            }
        }

        // MARK: - Sub Views

        @ViewBuilder
        private var titleView: some View {
            if let title {
                Text(title).style(Fonts.Bold.title2, color: Colors.Text.primary1)
            }
        }

        @ViewBuilder
        private var subtitleView: some View {
            if let subtitle {
                Text(subtitle)
                    .multilineTextAlignment(.center)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
            }
        }
    }
}
