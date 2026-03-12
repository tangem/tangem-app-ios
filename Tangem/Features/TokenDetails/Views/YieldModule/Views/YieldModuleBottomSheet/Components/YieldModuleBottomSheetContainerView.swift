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
import TangemUIUtils

struct YieldModuleBottomSheetContainerView<
    SubtitleFooter: View,
    BodyContent: View,
    HeaderContent: View,
    TopContent: View,
    ButtonView: View
>: View {
    // MARK: - Properties

    private let title: String?
    private let subtitle: String?

    private let contentTopPadding: CGFloat
    private let buttonTopPadding: CGFloat

    // MARK: - UI

    private let topContent: TopContent
    private let subtitleFooter: SubtitleFooter
    private let content: BodyContent
    private let header: HeaderContent
    private let button: ButtonView

    // MARK: - Init

    public init(
        title: String? = nil,
        subtitle: String? = nil,
        button: ButtonView,
        @ViewBuilder header: () -> HeaderContent = { EmptyView() },
        @ViewBuilder topContent: () -> TopContent = { EmptyView() },
        @ViewBuilder subtitleFooter: () -> SubtitleFooter = { EmptyView() },
        @ViewBuilder content: () -> BodyContent = { EmptyView() },
        contentTopPadding: CGFloat = 24,
        buttonTopPadding: CGFloat = 16
    ) {
        self.header = header()
        self.topContent = topContent()
        self.subtitleFooter = subtitleFooter()
        self.content = content()

        self.title = title
        self.subtitle = subtitle
        self.contentTopPadding = contentTopPadding
        self.button = button
        self.buttonTopPadding = buttonTopPadding
    }

    // MARK: - View Body

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: .zero) {
                topContent

                titleView
                    .padding(.top, 14)
                    .padding(.horizontal, 14)

                subtitleView
                    .padding(.top, 8)
                    .padding(.horizontal, 16)

                subtitleFooter
                    .padding(.top, 16)

                content
                    .padding(.top, contentTopPadding)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 0)
        }
        .safeAreaInset(edge: .top) {
            header
                .padding(.top, 8)
                .padding(.horizontal, 16)
                .background(Colors.Background.tertiary.edgesIgnoringSafeArea(.all))
        }
        .safeAreaInset(edge: .bottom) {
            button
                .padding(.top, buttonTopPadding)
                .padding(.horizontal, 16)
                .padding(.bottom, 18)
                .background(ListFooterOverlayShadowView())
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    // MARK: - Sub Views

    @ViewBuilder
    private var titleView: some View {
        if let title {
            Text(title).style(Fonts.Bold.title2, color: Colors.Text.primary1)
                .multilineTextAlignment(.center)
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
