//
//  TangemRow.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public struct TangemRow<
    TitleAccessory: View,
    SubtitleAccessory: View,
    ValueAccessory: View,
    SubvalueAccessory: View,
    Start: View,
    End: View,
    ExtraBottom: View
>: View, Setupable {
    let title: String?
    let subtitle: String?
    let value: String?
    let subvalue: String?

    let titleAccessoryContent: TitleAccessory
    let subtitleAccessoryContent: SubtitleAccessory
    let valueAccessoryContent: ValueAccessory
    let subvalueAccessoryContent: SubvalueAccessory
    let startContent: Start
    let endContent: End
    let extraBottomContent: ExtraBottom

    var config: TangemRowConfiguration

    @Environment(\.isEnabled) private var isEnabled

    init(
        title: String?,
        subtitle: String?,
        value: String?,
        subvalue: String?,
        titleAccessory: TitleAccessory,
        subtitleAccessory: SubtitleAccessory,
        valueAccessory: ValueAccessory,
        subvalueAccessory: SubvalueAccessory,
        start: Start,
        end: End,
        extraBottom: ExtraBottom,
        config: TangemRowConfiguration = TangemRowConfiguration()
    ) {
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.subvalue = subvalue
        titleAccessoryContent = titleAccessory
        subtitleAccessoryContent = subtitleAccessory
        valueAccessoryContent = valueAccessory
        subvalueAccessoryContent = subvalueAccessory
        startContent = start
        endContent = end
        extraBottomContent = extraBottom
        self.config = config
    }

    public var body: some View {
        mainWrapper
            .padding(config.includesInnerPadding ? TangemRowMetrics.innerPadding : 0)
            .overlay(alignment: .bottom) { dividerView }
            .overlay { focusRingView }
    }

    private var mainWrapper: some View {
        VStack(spacing: TangemRowMetrics.rootSpacing) {
            tappableContent

            if ExtraBottom.self != EmptyView.self {
                extraBottomContent
            }
        }
    }

    private var tappableContent: some View {
        coreButton
            .rowAccessibility(
                label: config.accessibilityLabel,
                hint: config.accessibilityHint,
                isSelected: config.focusRingEnabled
            )
    }

    @ViewBuilder
    private var coreButton: some View {
        if let onTap = config.onTap {
            Button(action: onTap) { contentCore }
                .buttonStyle(PressStyle())
        } else {
            contentCore
        }
    }

    private var contentCore: some View {
        HStack(alignment: config.verticalAlignment.stackAlignment, spacing: TangemRowMetrics.slotSpacing) {
            startContent
                .opacity(contentOpacity)

            TangemRowContentLayout(contentLead: config.contentLead) {
                titleColumn
                valueColumn
            }
            .frame(maxWidth: .infinity)
            .opacity(contentOpacity)

            endContent
                .opacity(contentOpacity)
        }
    }

    private var contentOpacity: Double {
        isEnabled ? 1 : TangemRowMetrics.disabledOpacity
    }

    private var titleColumn: some View {
        VStack(alignment: .leading, spacing: TangemRowMetrics.lineSpacing) {
            orderedLines(primary: titleLine, secondary: subtitleLine)
        }
    }

    private var valueColumn: some View {
        VStack(alignment: .trailing, spacing: TangemRowMetrics.lineSpacing) {
            orderedLines(primary: valueLine, secondary: subvalueLine)
        }
    }

    @ViewBuilder
    private func orderedLines(primary: some View, secondary: some View) -> some View {
        switch config.lineOrder {
        case .primaryFirst:
            primary
            secondary
        case .secondaryFirst:
            secondary
            primary
        }
    }

    @ViewBuilder
    private var titleLine: some View {
        if title != nil || TitleAccessory.self != EmptyView.self {
            labelLine(text: title, accessory: titleAccessoryContent, role: .title, lineLimit: config.titleLineLimit)
        }
    }

    @ViewBuilder
    private var subtitleLine: some View {
        if subtitle != nil || SubtitleAccessory.self != EmptyView.self {
            labelLine(text: subtitle, accessory: subtitleAccessoryContent, role: .subtitle, lineLimit: config.subtitleLineLimit)
        }
    }

    @ViewBuilder
    private var valueLine: some View {
        if value != nil || ValueAccessory.self != EmptyView.self {
            labelLine(text: value, accessory: valueAccessoryContent, role: .value, lineLimit: config.valueLineLimit)
        }
    }

    @ViewBuilder
    private var subvalueLine: some View {
        if subvalue != nil || SubvalueAccessory.self != EmptyView.self {
            labelLine(text: subvalue, accessory: subvalueAccessoryContent, role: .subvalue, lineLimit: config.subvalueLineLimit)
        }
    }

    private func labelLine(text: String?, accessory: some View, role: Role, lineLimit: Int) -> some View {
        HStack(alignment: .center, spacing: TangemRowMetrics.inlineAccessorySpacing) {
            if let text {
                Text(text)
                    .style(role.font, color: role.color)
                    .lineLimit(lineLimit)
                    .truncationMode(.tail)
            }

            accessory
                .layoutPriority(1)
        }
    }

    @ViewBuilder
    private var dividerView: some View {
        if config.showsDivider {
            Rectangle()
                .fill(DesignSystem.Tokens.Theme.Border.secondary)
                .frame(height: TangemRowMetrics.dividerHeight)
                .padding(.horizontal, TangemRowMetrics.dividerInset)
        }
    }

    @ViewBuilder
    private var focusRingView: some View {
        if config.focusRingEnabled {
            RoundedRectangle(cornerRadius: TangemRowMetrics.focusRingCornerRadius, style: .continuous)
                .inset(by: -TangemRowMetrics.focusRingWidth / 2)
                .stroke(DesignSystem.Tokens.Theme.Interaction.FocusRing.brand, lineWidth: TangemRowMetrics.focusRingWidth)
        }
    }
}

// MARK: - Press style

private extension TangemRow {
    struct PressStyle: ButtonStyle {
        @Environment(\.isEnabled) private var isEnabled

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .background(configuration.isPressed && isEnabled ? DesignSystem.Tokens.Theme.Interaction.press : Color.clear)
                .contentShape(Rectangle())
        }
    }
}

// MARK: - Role

extension TangemRow {
    enum Role {
        case title
        case subtitle
        case value
        case subvalue

        var font: TangemTypographyToken {
            switch self {
            case .title, .value: DesignSystem.Tokens.Font.Body.medium
            case .subtitle, .subvalue: DesignSystem.Tokens.Font.Caption.medium
            }
        }

        var color: Color {
            switch self {
            case .title, .value: DesignSystem.Tokens.Theme.Text.primary
            case .subtitle, .subvalue: DesignSystem.Tokens.Theme.Text.secondary
            }
        }
    }
}

// MARK: - Accessibility

private extension View {
    @ViewBuilder
    func rowAccessibility(label: String?, hint: String?, isSelected: Bool) -> some View {
        let traits: AccessibilityTraits = isSelected ? .isSelected : []

        if let label {
            accessibilityElement(children: .ignore)
                .accessibilityLabel(label)
                .rowAccessibilityHint(hint)
                .accessibilityAddTraits(traits)
        } else {
            accessibilityElement(children: .combine)
                .rowAccessibilityHint(hint)
                .accessibilityAddTraits(traits)
        }
    }

    @ViewBuilder
    func rowAccessibilityHint(_ hint: String?) -> some View {
        if let hint {
            accessibilityHint(hint)
        } else {
            self
        }
    }
}

// MARK: - Constants

enum TangemRowMetrics {
    static let rootSpacing = DesignSystem.Tokens.Spacing.s100
    static let innerPadding = DesignSystem.Tokens.Spacing.s200
    static let slotSpacing = DesignSystem.Tokens.Spacing.s150
    static let columnSpacing = DesignSystem.Tokens.Spacing.s150
    static let lineSpacing = DesignSystem.Tokens.Spacing.s025
    static let inlineAccessorySpacing = DesignSystem.Tokens.Spacing.s050
    static let dividerInset = DesignSystem.Tokens.Spacing.s200
    static let dividerHeight = DesignSystem.Tokens.BorderWidth.sm
    static let disabledOpacity = DesignSystem.Tokens.Opacity.disabled
    static let focusRingWidth = DesignSystem.Tokens.BorderWidth.md
    static let focusRingCornerRadius = DesignSystem.Tokens.CornerRadius._200
    static let iconSize = DesignSystem.Tokens.Size.s300
}
