//
//  MessageBanner.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public struct MessageBanner<SlotStart: View, SlotEnd: View, ExtraBottom: View>: View, Setupable {
    let title: AttributedString
    let description: AttributedString?

    let slotStartContent: SlotStart
    let slotEndContent: SlotEnd
    let extraBottomContent: ExtraBottom

    var config: MessageBannerConfiguration

    @Environment(\.isFocused) private var isFocused
    @State private var slotStartWidth: CGFloat = 0
    @State private var slotEndWidth: CGFloat = 0

    init(
        title: AttributedString,
        description: AttributedString?,
        slotStart: SlotStart,
        slotEnd: SlotEnd,
        extraBottom: ExtraBottom,
        config: MessageBannerConfiguration = MessageBannerConfiguration()
    ) {
        self.title = title
        self.description = description
        slotStartContent = slotStart
        slotEndContent = slotEnd
        extraBottomContent = extraBottom
        self.config = config
    }

    public var body: some View {
        let banner = VStack(alignment: .leading, spacing: MessageBannerMetrics.rootSpacing) {
            contentView
            buttonsView
        }
        .padding(MessageBannerMetrics.contentPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(config.variant.background, in: containerShape)
        .overlay {
            containerShape.strokeBorder(DesignSystem.Color.borderPrimary, lineWidth: MessageBannerMetrics.borderWidth)
        }

        return applyGlowRing(to: banner)
            .overlay { focusRing }
    }

    private var containerShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: MessageBannerMetrics.cornerRadius, style: .continuous)
    }

    @ViewBuilder
    private func applyGlowRing(to content: some View) -> some View {
        if config.showsGlowRing {
            content.glowRing(config.variant.glowAppearance, cornerRadius: MessageBannerMetrics.cornerRadius)
        } else {
            content
        }
    }

    @ViewBuilder
    private var focusRing: some View {
        if isFocused {
            containerShape.strokeBorder(
                DesignSystem.Color.interactionFocusRingBrand,
                lineWidth: MessageBannerMetrics.focusRingWidth
            )
        }
    }
}

// MARK: - Content

private extension MessageBanner {
    @ViewBuilder
    var contentView: some View {
        switch config.contentAlign {
        case .start:
            HStack(alignment: .top, spacing: MessageBannerMetrics.contentRowSpacing) {
                slotStartContent
                textColumn
                    .frame(maxWidth: .infinity, alignment: .leading)
                slotEndContent
            }
        case .center:
            textColumn
                .frame(maxWidth: .infinity)
                .padding(.horizontal, centerContentInset)
                .overlay(alignment: .topLeading) {
                    slotStartContent.readGeometry(\.size.width, bindTo: $slotStartWidth)
                }
                .overlay(alignment: .topTrailing) {
                    slotEndContent.readGeometry(\.size.width, bindTo: $slotEndWidth)
                }
        }
    }

    var centerContentInset: CGFloat {
        let widestSlot = max(slotStartWidth, slotEndWidth)
        return widestSlot > 0 ? widestSlot + MessageBannerMetrics.contentRowSpacing : 0
    }

    var textColumn: some View {
        VStack(alignment: config.contentAlign.textStackAlignment, spacing: MessageBannerMetrics.textColumnSpacing) {
            Text(title)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                .lineLimit(config.titleLineLimit)
                .multilineTextAlignment(config.contentAlign.textAlignment)

            if let description {
                Text(description)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .lineLimit(config.descriptionLineLimit)
                    .multilineTextAlignment(config.contentAlign.textAlignment)
            }

            if ExtraBottom.self != EmptyView.self {
                extraBottomContent
                    .padding(.top, MessageBannerMetrics.extraBottomTopPadding)
            }
        }
        .accessibilityElement(children: config.accessibilityLabel == nil ? .combine : .ignore)
        .ifLet(config.accessibilityLabel) { view, label in
            view.accessibilityLabel(label)
        }
    }
}

// MARK: - Buttons

private extension MessageBanner {
    @ViewBuilder
    var buttonsView: some View {
        if config.secondaryButton != nil || config.primaryButton != nil {
            HStack(spacing: MessageBannerMetrics.buttonRowSpacing) {
                if let secondaryButton = config.secondaryButton {
                    buttonView(secondaryButton, styleType: .secondary)
                }

                if let primaryButton = config.primaryButton {
                    buttonView(primaryButton, styleType: .default)
                }
            }
        }
    }

    func buttonView(_ model: MessageBannerButton, styleType: TangemUI.Button.StyleType) -> some View {
        TangemUI.Button(
            label: AttributedString(model.title),
            iconStart: model.iconStart,
            iconEnd: model.iconEnd,
            accessibilityLabel: model.accessibilityLabel ?? model.title,
            action: model.action
        )
        .styleType(styleType)
        .size(.x9)
        .horizontalLayout(.infinity)
        .isLoading(model.isLoading)
        .disabled(!model.isEnabled)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Variant tokens

extension MessageBannerVariant {
    var background: Color {
        switch self {
        case .default: DesignSystem.Color.bgOpaquePrimary
        case .solid: DesignSystem.Color.bgTertiary
        case .success: DesignSystem.Color.bgStatusSuccessSubtle
        case .error: DesignSystem.Color.bgStatusErrorSubtle
        case .warning: DesignSystem.Color.bgStatusWarningSubtle
        case .info: DesignSystem.Color.bgStatusInfoSubtle
        }
    }

    var glowAppearance: GlowRingAppearance {
        switch self {
        case .default, .solid: .magic
        case .success: .success
        case .error: .error
        case .warning: .warning
        case .info: .info
        }
    }
}

// MARK: - Constants

enum MessageBannerMetrics {
    static let cornerRadius: CGFloat = 28
    static let contentPadding: CGFloat = 16
    static let rootSpacing: CGFloat = 16
    static let contentRowSpacing: CGFloat = 12
    static let textColumnSpacing: CGFloat = 4
    static let extraBottomTopPadding: CGFloat = 8
    static let buttonRowSpacing: CGFloat = 8
    static let focusRingWidth: CGFloat = 2
    static let borderWidth: CGFloat = 1
}
