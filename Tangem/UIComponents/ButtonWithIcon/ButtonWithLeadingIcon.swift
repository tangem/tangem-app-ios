//
//  ButtonWithLeadingIcon.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct FixedSizeButtonWithLeadingIcon: View {
    var body: some View {
        let colorConfiguration = ButtonWithLeadingIconContentView.ColorConfiguration(
            textColor: stateRelatedStyle.textColor,
            iconColor: stateRelatedStyle.iconColor,
            backgroundColor: backgroundColor
        )
        ButtonWithLeadingIconContentView(
            title: title,
            icon: icon,
            colorConfiguration: colorConfiguration,
            spacing: 4,
            maintainsIdealSize: true,
            action: action
        )
    }

    @Environment(\.isEnabled) private var isEnabled

    private let title: String
    private let icon: Image
    private let style: Style
    private let action: () -> Void

    private var stateRelatedStyle: Style {
        isEnabled ? style : .disabled
    }

    private var backgroundColor: Color {
        let styleColor = style.backgroundColor
        return isEnabled ? backgroundColorOverride ?? styleColor : styleColor
    }

    private var backgroundColorOverride: Color?

    init(
        title: String,
        icon: Image,
        style: Style,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }
}

extension FixedSizeButtonWithLeadingIcon {
    enum Style {
        case `default`
        case disabled

        var textColor: Color {
            switch self {
            case .default:
                return Colors.Text.primary1
            case .disabled:
                return Colors.Text.disabled
            }
        }

        var iconColor: Color {
            switch self {
            case .default:
                return Colors.Icon.primary1
            case .disabled:
                return Colors.Icon.inactive
            }
        }

        var backgroundColor: Color {
            switch self {
            case .default:
                return Colors.Button.secondary
            case .disabled:
                return Colors.Button.disabled
            }
        }
    }
}

struct FlexySizeButtonWithLeadingIcon: View {
    var body: some View {
        let colorConfiguration = ButtonWithLeadingIconContentView.ColorConfiguration(
            textColor: isToggled ? Colors.Text.tertiary : Colors.Text.primary1,
            iconColor: isToggled ? Colors.Icon.informative : Colors.Text.primary1,
            backgroundColor: backgroundColorOverride ?? Colors.Background.primary
        )
        ButtonWithLeadingIconContentView(
            title: title,
            icon: icon,
            colorConfiguration: colorConfiguration,
            spacing: 6,
            maintainsIdealSize: false,
            action: action
        )
    }

    private let title: String
    private let icon: Image
    /// A special appearance for cases when this button is used to switch between
    /// the discrete `On` and `Off` states, like `SwiftUI.Switch` does.
    /// See [this mockup]([REDACTED_INFO]
    /// as an example of such behavior.
    private let isToggled: Bool
    private let action: () -> Void

    private var backgroundColorOverride: Color?

    init(
        title: String,
        icon: Image,
        isToggled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isToggled = isToggled
        self.action = action
    }
}

// MARK: - Setupable protocol conformance

extension FixedSizeButtonWithLeadingIcon: Setupable {
    func overrideBackgroundColor(_ color: Color) -> Self {
        return map { $0.backgroundColorOverride = color }
    }
}

extension FlexySizeButtonWithLeadingIcon: Setupable {
    func overrideBackgroundColor(_ color: Color) -> Self {
        return map { $0.backgroundColorOverride = color }
    }
}

// MARK: - Constants

extension FixedSizeButtonWithLeadingIcon {
    enum Constants {
        /// - Note: Exposed for consumers of this UI component.
        static var cornerRadius: CGFloat { ButtonWithLeadingIconContentView.cornerRadius }
    }
}

extension FlexySizeButtonWithLeadingIcon {
    enum Constants {
        /// - Note: Exposed for consumers of this UI component.
        static var cornerRadius: CGFloat { ButtonWithLeadingIconContentView.cornerRadius }
    }
}

// MARK: - Private implementation

private struct ButtonWithLeadingIconContentView: View {
    static let cornerRadius = 10.0

    struct ColorConfiguration {
        let textColor: Color
        let iconColor: Color
        let backgroundColor: Color
    }

    let title: String
    let icon: Image
    let colorConfiguration: ColorConfiguration
    let spacing: Double
    let maintainsIdealSize: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: spacing) {
                icon
                    .renderingMode(.template)
                    .resizable()
                    .frame(size: .init(bothDimensions: 20))
                    .foregroundColor(colorConfiguration.iconColor)

                if !title.isEmpty {
                    Text(title)
                        .style(Fonts.Bold.subheadline, color: colorConfiguration.textColor)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: maintainsIdealSize ? nil : .infinity)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(colorConfiguration.backgroundColor)
        }
        .cornerRadiusContinuous(Self.cornerRadius)
        .buttonStyle(.borderless)
    }
}

// MARK: - Previews

struct ButtonWithLeadingIcon_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray
                .opacity(0.1)
                .ignoresSafeArea()

            VStack {
                FixedSizeButtonWithLeadingIcon(
                    title: "Buy",
                    icon: Assets.plusMini.image,
                    style: .default
                ) {}

                FixedSizeButtonWithLeadingIcon(
                    title: "Exchange",
                    icon: Assets.exchangeMini.image,
                    style: .default,
                    action: {}
                )
                .disabled(true)

                FixedSizeButtonWithLeadingIcon(
                    title: "Organize tokens",
                    icon: Assets.sliders.image,
                    style: .disabled
                ) {}

                FixedSizeButtonWithLeadingIcon(
                    title: "",
                    icon: Assets.horizontalDots.image,
                    style: .disabled,
                    action: {}
                )
                .disabled(true)

                FixedSizeButtonWithLeadingIcon(
                    title: "LongTitle_LongTitle_LongTitle_LongTitle_LongTitle",
                    icon: Assets.infoIconMini.image,
                    style: .default
                ) {}

                FlexySizeButtonWithLeadingIcon(
                    title: "Buy",
                    icon: Assets.plusMini.image
                ) {}

                FlexySizeButtonWithLeadingIcon(
                    title: "Exchange",
                    icon: Assets.exchangeMini.image,
                    isToggled: true
                ) {}

                FlexySizeButtonWithLeadingIcon(
                    title: "",
                    icon: Assets.horizontalDots.image
                ) {}

                FlexySizeButtonWithLeadingIcon(
                    title: "Organize tokens",
                    icon: Assets.sliders.image,
                    isToggled: true
                ) {}

                FlexySizeButtonWithLeadingIcon(
                    title: "LongTitle_LongTitle_LongTitle_LongTitle_LongTitle",
                    icon: Assets.infoIconMini.image
                ) {}
            }
            .padding(.horizontal)
            .infinityFrame()
        }
    }
}
