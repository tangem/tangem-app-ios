//
//  YieldAccountBottomSheetContainer.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct YieldAccountBottomSheetContainer<
    Title: View, Subtitle: View, BodyContent: View, ToolBarTitle: View, TopContent: View, ButtonLabel: View
>: View {
    // MARK: - Slots

    private let topContent: () -> TopContent
    private let title: () -> Title
    private let subtitle: () -> Subtitle
    private let content: () -> BodyContent
    private let toolBarTitle: () -> ToolBarTitle
    private let buttonLabel: () -> ButtonLabel

    // MARK: - Actions & UI

    private let buttonStyle: TangemButtonStyle
    private let closeAction: (() -> Void)?
    private let backAction: (() -> Void)?
    private let buttonAction: () -> Void

    // MARK: - Шnit

    public init(
        @ViewBuilder topContent: @escaping () -> TopContent = { EmptyView() },
        @ViewBuilder title: @escaping () -> Title = { EmptyView() },
        @ViewBuilder subtitle: @escaping () -> Subtitle = { EmptyView() },
        @ViewBuilder content: @escaping () -> BodyContent = { EmptyView() },
        @ViewBuilder toolBarTitle: @escaping () -> ToolBarTitle = { EmptyView() },
        @ViewBuilder buttonLabel: @escaping () -> ButtonLabel,
        buttonStyle: TangemButtonStyle,
        closeAction: (() -> Void)? = nil,
        backAction: (() -> Void)? = nil,
        buttonAction: @escaping () -> Void
    ) {
        self.topContent = topContent
        self.title = title
        self.subtitle = subtitle
        self.content = content
        self.toolBarTitle = toolBarTitle
        self.buttonLabel = buttonLabel
        self.buttonStyle = buttonStyle
        self.closeAction = closeAction
        self.backAction = backAction
        self.buttonAction = buttonAction
    }

    // MARK: - View Body

    var body: some View {
        VStack(spacing: .zero) {
            toolBar.padding(.bottom, 20)

            topContent().padding(.bottom, 28)

            title()
                .padding(.horizontal, 16)
                .padding(.bottom, 6)

            subtitle()
                .padding(.horizontal, 16)
                .padding(.bottom, 24)

            content().padding(.bottom, 24)

            bottomButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }

    // MARK: - Sub Views

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
                toolBarTitle()
                Spacer()
            }
        }
    }

    private var bottomButton: some View {
        Button(action: buttonAction) {
            buttonLabel()
        }
        .buttonStyle(buttonStyle)
    }
}

// #Preview {
//    YieldAccountBottomSheetContainer()
// }
