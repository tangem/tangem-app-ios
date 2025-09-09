//
//  YieldModuleBottomSheetContainer.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

extension YieldModuleBottomSheetView {
    struct SheetContainer<SubtitleFooter: View, BodyContent: View, ToolBarTitle: View, TopContent: View>: View {
        // MARK: - Properties

        private let title: String?
        private let subtitle: String?

        // MARK: - UI

        private let topContent: TopContent
        private let subtitleFooter: SubtitleFooter
        private let content: BodyContent
        private let toolBarTitle: ToolBarTitle
        private let buttonStyle: CallToActionButtonStyle

        // MARK: - Actions

        private let closeAction: (() -> Void)?
        private let backAction: (() -> Void)?
        private let buttonAction: () -> Void
        private let horizontalPadding: CGFloat

        // MARK: - Init

        public init(
            title: String? = nil,
            subtitle: String? = nil,
            buttonStyle: CallToActionButtonStyle,
            @ViewBuilder toolBarTitle: () -> ToolBarTitle = { EmptyView() },
            @ViewBuilder topContent: () -> TopContent = { EmptyView() },
            @ViewBuilder subtitleFooter: () -> SubtitleFooter = { EmptyView() },
            @ViewBuilder content: () -> BodyContent = { EmptyView() },
            closeAction: (() -> Void)? = nil,
            backAction: (() -> Void)? = nil,
            buttonAction: @escaping () -> Void,
            horizontalPadding: CGFloat
        ) {
            // вычисляем и сохраняем View один раз
            self.toolBarTitle = toolBarTitle()
            self.topContent = topContent()
            self.subtitleFooter = subtitleFooter()
            self.content = content()

            self.title = title
            self.subtitle = subtitle
            self.buttonStyle = buttonStyle
            self.closeAction = closeAction
            self.backAction = backAction
            self.buttonAction = buttonAction
            self.horizontalPadding = horizontalPadding
        }

        // MARK: - View Body

        var body: some View {
            ScrollView {
                VStack(spacing: .zero) {
                    toolBar.padding(.bottom, 20)

                    topContent.padding(.bottom, 28)

                    titleView
                        .padding(.horizontal, 16)
                        .padding(.bottom, 6)

                    subtitleView
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)

                    subtitleFooter.padding(.bottom, 24)

                    content.padding(.bottom, 24)

                    bottomButton
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
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

        private var bottomButton: some View {
            Button(action: buttonAction) {
                buttonStyle.label
            }
            .buttonStyle(buttonStyle.tangemButtonStyle)
        }
    }
}

extension YieldModuleBottomSheetView {
    enum CallToActionButtonStyle {
        case gray(title: String)
        case black(title: String)
        case blackWithTangemIcon(title: String)

        var tangemButtonStyle: TangemButtonStyle {
            var buttonColorStyle: ButtonColorStyle

            switch self {
            case .gray:
                buttonColorStyle = .gray
            case .black, .blackWithTangemIcon:
                buttonColorStyle = .black
            }

            return TangemButtonStyle(colorStyle: buttonColorStyle, layout: .flexibleWidth)
        }

        @ViewBuilder
        var label: some View {
            switch self {
            case .gray(let title):
                Text(title)
            case .black(let title):
                Text(title)
            case .blackWithTangemIcon(let title):
                HStack(spacing: 10) {
                    Text(title)
                    Assets.tangemIcon.image
                }
            }
        }
    }
}
