//
//  MainButton.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct MainButton: View {
    private let title: String
    private let icon: Icon?
    private let style: Style
    private let dimensions: Dimensions
    private let font: Font
    private let isLoading: Bool
    private let isDisabled: Bool
    private let action: () -> Void

    init(
        title: String,
        icon: Icon? = nil,
        style: Style = .primary,
        dimensions: Dimensions = .default,
        font: Font = Fonts.Bold.callout,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping (() -> Void)
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.dimensions = dimensions
        self.font = font
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    init(settings: Settings) {
        self.init(
            title: settings.title,
            icon: settings.icon,
            style: settings.style,
            dimensions: settings.dimensions,
            font: settings.font,
            isLoading: settings.isLoading,
            isDisabled: settings.isDisabled,
            action: settings.action
        )
    }

    var body: some View {
        Button(action: action) {
            content
                .frame(
                    maxWidth: dimensions.maxWidth,
                    alignment: .center
                )
                .padding(.vertical, dimensions.verticalPadding)
                .background(style.background(isDisabled: isDisabled))
                .cornerRadiusContinuous(dimensions.cornerRadius)
        }
        .buttonStyle(BorderlessButtonStyle())
        .disabled(isDisabled || isLoading)
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            ProgressViewCompat(color: style.loaderColor())
        } else {
            Group {
                switch icon {
                case .none:
                    textView

                case .leading(let icon):
                    HStack(alignment: .center, spacing: 10) {
                        iconView(icon: icon)

                        textView
                    }
                case .trailing(let icon):
                    HStack(alignment: .center, spacing: 10) {
                        textView

                        iconView(icon: icon)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private var textView: some View {
        Text(title)
            .style(
                font,
                color: style.textColor(isDisabled: isDisabled)
            )
            .lineLimit(1)
    }

    @ViewBuilder
    private func iconView(icon: ImageType) -> some View {
        icon.image
            .resizable()
            .renderingMode(.template)
            .frame(size: dimensions.iconSize)
            .foregroundColor(style.iconColor(isDisabled: isDisabled))
    }
}

extension MainButton {
    enum Icon {
        case leading(_ icon: ImageType)
        case trailing(_ icon: ImageType)
    }

    enum Style: String, Hashable, CaseIterable {
        case primary
        case secondary

        func iconColor(isDisabled: Bool) -> Color {
            if isDisabled {
                return Colors.Icon.inactive
            }

            switch self {
            case .primary:
                return Colors.Icon.primary2
            case .secondary:
                return Colors.Icon.primary1
            }
        }

        func textColor(isDisabled: Bool) -> Color {
            if isDisabled {
                return Colors.Text.disabled
            }

            switch self {
            case .primary:
                return Colors.Text.primary2
            case .secondary:
                return Colors.Text.primary1
            }
        }

        func loaderColor() -> Color {
            switch self {
            case .primary:
                return Colors.Text.primary2
            case .secondary:
                return Colors.Text.primary1
            }
        }

        func background(isDisabled: Bool) -> Color {
            if isDisabled {
                return Colors.Button.disabled
            }

            switch self {
            case .primary:
                return Colors.Button.primary
            case .secondary:
                return Colors.Button.secondary
            }
        }
    }

    struct Dimensions {
        let maxWidth: CGFloat?
        let verticalPadding: CGFloat
        let horizontalPadding: CGFloat
        let cornerRadius: CGFloat
        let iconToLabelPadding: CGFloat
        let iconSize: CGSize

        static let `default` = Dimensions(
            maxWidth: .infinity,
            verticalPadding: 14,
            horizontalPadding: 16,
            cornerRadius: 14,
            iconToLabelPadding: 10,
            iconSize: CGSize(width: 20, height: 20)
        )
    }

    struct Settings {
        let title: String
        let icon: Icon?
        let style: Style
        let dimensions: Dimensions
        let font: Font
        let isLoading: Bool
        var isDisabled: Bool
        let action: () -> Void

        init(
            title: String,
            icon: Icon? = nil,
            style: Style = .primary,
            dimensions: Dimensions = .default,
            font: Font = Fonts.Regular.callout,
            isLoading: Bool = false,
            isDisabled: Bool = false,
            action: @escaping (() -> Void)
        ) {
            self.title = title
            self.icon = icon
            self.style = style
            self.dimensions = dimensions
            self.font = font
            self.isLoading = isLoading
            self.isDisabled = isDisabled
            self.action = action
        }
    }
}

struct MainButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ForEach(MainButton.Style.allCases, id: \.hashValue) { style in
                buttons(style: style)
                    .previewDisplayName(style.rawValue)
            }
        }
        .previewLayout(.sizeThatFits)
    }

    @ViewBuilder
    static func buttons(style: MainButton.Style) -> some View {
        VStack(spacing: 16) {
            MainButton(
                title: "Order card",
                icon: .leading(Assets.tangemIcon),
                style: style,
                dimensions: .init(
                    maxWidth: 200,
                    verticalPadding: 8,
                    horizontalPadding: 14,
                    cornerRadius: 10,
                    iconToLabelPadding: 8,
                    iconSize: .init(width: 16, height: 16)
                ),
                font: Fonts.Bold.subheadline
            ) {}

            MainButton(
                title: "Order card",
                icon: .leading(Assets.tangemIcon),
                style: style,
                isDisabled: true
            ) {}

            MainButton(
                title: "Order card",
                icon: .trailing(Assets.tangemIcon),
                style: style
            ) {}

            MainButton(
                title: "Order card",
                icon: .trailing(Assets.tangemIcon),
                style: style,
                isDisabled: true
            ) {}

            MainButton(
                title: "Order card",
                icon: .trailing(Assets.tangemIcon),
                style: style,
                isLoading: true
            ) {}

            MainButton(
                title: "A long long long long long long long long long long text",
                icon: .trailing(Assets.tangemIcon),
                style: style,
                isLoading: false
            ) {}
        }
        .padding(.horizontal, 16)
        .background(Colors.Background.secondary)
    }
}
