//
//  DefaultRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils
import TangemUI

struct DefaultRowView: View {
    @ObservedObject private var viewModel: DefaultRowViewModel
    private var appearance: Appearance = .init()

    init(viewModel: DefaultRowViewModel) {
        self.viewModel = viewModel
    }

    private var isTappable: Bool { viewModel.action != nil }

    var body: some View {
        if let action = viewModel.action {
            Button(action: action) {
                content
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityIdentifier(viewModel.accessibilityIdentifier)
        } else {
            content
        }
    }

    private var content: some View {
        HStack(spacing: 12) {
            if let leadingIcon = appearance.leadingIcon {
                leadingIconView(for: leadingIcon)
            }

            titleView

            Spacer()

            detailsView

            if isTappable, appearance.isChevronVisible {
                Assets.chevron.image
            }
        }
        .lineLimit(1)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    private var titleView: some View {
        HStack(spacing: 0) {
            Text(viewModel.title)
                .style(appearance.font, color: appearance.textColor)

            if let secondaryAction = viewModel.secondaryAction {
                Button(action: secondaryAction) {
                    Assets.infoCircle16.image
                        .padding(.horizontal, 4)
                        .foregroundColor(Colors.Icon.informative)
                }
            }
        }
    }

    @ViewBuilder
    private func leadingIconView(for icon: Appearance.LeadingIcon) -> some View {
        switch icon {
        case .plus:
            PlusIconView(textAndIconColor: appearance.textColor)
        }
    }

    @ViewBuilder
    private var detailsView: some View {
        switch viewModel.detailsType {
        case .none:
            EmptyView()
        case .loader:
            ActivityIndicatorView(style: .medium, color: .gray)
        case .text(let string, let sensitive):
            if sensitive {
                SensitiveText(string)
                    .style(appearance.font, color: appearance.detailsColor)
                    .accessibilityIdentifier(viewModel.accessibilityIdentifier)
            } else {
                Text(string)
                    .style(appearance.font, color: appearance.detailsColor)
                    .accessibilityIdentifier(viewModel.accessibilityIdentifier)
            }
        case .loadable(let state):
            LoadableTextView(
                state: state,
                font: appearance.font,
                textColor: appearance.detailsColor,
                loaderSize: CGSize(width: 60, height: 14)
            )
        case .icon(let imageType):
            imageType.image
        case .badge(let item):
            BadgeView(item: item)
        }
    }
}

extension DefaultRowView: Setupable {
    func appearance(_ appearance: Appearance) -> Self {
        map { $0.appearance = appearance }
    }
}

extension DefaultRowView {
    struct Appearance {
        enum LeadingIcon {
            case plus
        }

        let isChevronVisible: Bool
        let font: Font
        let textColor: Color
        let detailsColor: Color
        let leadingIcon: LeadingIcon?

        static let destructiveButton = Appearance(isChevronVisible: false, textColor: Colors.Text.warning)
        static let accentButton = Appearance(isChevronVisible: false, textColor: Colors.Text.accent)
        static let addButton = Appearance(
            isChevronVisible: false,
            font: Fonts.Bold.subheadline,
            textColor: Colors.Text.accent,
            leadingIcon: .plus
        )

        init(
            isChevronVisible: Bool = true,
            font: Font = Fonts.Regular.callout,
            textColor: Color = Colors.Text.primary1,
            detailsColor: Color = Colors.Text.tertiary,
            leadingIcon: LeadingIcon? = nil
        ) {
            self.isChevronVisible = isChevronVisible
            self.font = font
            self.textColor = textColor
            self.detailsColor = detailsColor
            self.leadingIcon = leadingIcon
        }
    }
}

struct DefaultRowView_Preview: PreviewProvider {
    static var previews: some View {
        ZStack {
            Colors.Background.secondary.ignoresSafeArea()

            GroupedSection(
                [
                    DefaultRowViewModel(
                        title: "App settings",
                        detailsType: .text("A Long long long long long long long text"),
                        action: nil
                    ),
                    DefaultRowViewModel(
                        title: "App settings",
                        detailsType: .loadable(state: .loading),
                        action: nil
                    ),
                    DefaultRowViewModel(
                        title: "App settings",
                        detailsType: .loader,
                        action: nil
                    ),
                ]
            ) {
                DefaultRowView(viewModel: $0)
            }
            .padding()
        }
    }
}
