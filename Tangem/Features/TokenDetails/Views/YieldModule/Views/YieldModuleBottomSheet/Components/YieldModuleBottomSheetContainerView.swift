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
    struct YieldModuleBottomSheetContainerView<SubtitleFooter: View, BodyContent: View, ToolBarTitle: View, TopContent: View>: View {
        // MARK: - Properties

        private let title: String?
        private let subtitle: String?
        private let horizontalPadding: CGFloat

        // MARK: - UI

        private let topContent: TopContent
        private let subtitleFooter: SubtitleFooter
        private let content: BodyContent
        private let toolBarTitle: ToolBarTitle
        private let button: MainButton

        // MARK: - Actions

        private let closeAction: (() -> Void)?
        private let backAction: (() -> Void)?

        // MARK: - Init

        public init(
            title: String? = nil,
            subtitle: String? = nil,
            button: MainButton,
            @ViewBuilder toolBarTitle: () -> ToolBarTitle = { EmptyView() },
            @ViewBuilder topContent: () -> TopContent = { EmptyView() },
            @ViewBuilder subtitleFooter: () -> SubtitleFooter = { EmptyView() },
            @ViewBuilder content: () -> BodyContent = { EmptyView() },
            closeAction: (() -> Void)? = nil,
            backAction: (() -> Void)? = nil,
            horizontalPadding: CGFloat
        ) {
            self.toolBarTitle = toolBarTitle()
            self.topContent = topContent()
            self.subtitleFooter = subtitleFooter()
            self.content = content()

            self.title = title
            self.subtitle = subtitle
            self.button = button
            self.closeAction = closeAction
            self.backAction = backAction
            self.horizontalPadding = horizontalPadding
        }

        // MARK: - View Body

        var body: some View {
            ScrollView {
                VStack(spacing: .zero) {
                    toolBar

                    topContent.padding(.top, 8)

                    titleView
                        .padding(.top, 20)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 6)

                    subtitleView
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)

                    subtitleFooter.padding(.bottom, 24)

                    content

                    button.padding(.top, 32)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
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

        private var toolBar: some View {
            HStack {
                if let backAction {
                    CircleButton.back { backAction() }
                }

                Spacer()

                if let closeAction {
                    CircleButton.close { closeAction() }
                }
            }
            .overlay {
                HStack {
                    Spacer()
                    toolBarTitle
                    Spacer()
                }
            }
        }
    }
}
