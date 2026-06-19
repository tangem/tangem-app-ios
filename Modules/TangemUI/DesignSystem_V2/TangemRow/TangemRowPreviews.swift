//
//  TangemRowPreviews.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation
import TangemUIUtils

// MARK: - Showcase

public struct TangemRowShowcase: View {
    @State private var contentLead: TangemRowContentLead = .equal
    @State private var verticalAlignment: TangemRowVerticalAlignment = .top

    @State private var showDivider = true
    @State private var includeInnerPadding = true
    @State private var focusRing = false
    @State private var isInteractive = true
    @State private var isEnabled = true
    @State private var overflow = false
    @State private var rightToLeft = false

    @State private var showTitle = true
    @State private var showSubtitle = true
    @State private var showValue = true
    @State private var showSubvalue = true
    @State private var showStartIcon = false
    @State private var showEndIcon = true
    @State private var showTitleAccessory = false
    @State private var showSubtitleAccessory = false
    @State private var showValueAccessory = false
    @State private var showSubvalueAccessory = false
    @State private var showExtraBottom = false

    @State private var overrideLabel = false
    @State private var customHint = false

    @State private var lineOrder: TangemRowLineOrder = .primaryFirst
    @State private var titleLineLimit = 1
    @State private var subtitleLineLimit = 1
    @State private var valueLineLimit = 1
    @State private var subvalueLineLimit = 1

    @State private var titleColorOverride: ShowcaseColor = .default
    @State private var subtitleColorOverride: ShowcaseColor = .default
    @State private var valueColorOverride: ShowcaseColor = .default
    @State private var subvalueColorOverride: ShowcaseColor = .default

    @State private var dynamicTypeIndex = Self.dynamicTypeAllCases.firstIndex(of: .large) ?? 0
    @State private var tapCount = 0
    @State private var expanded: [String: Bool] = [:]

    private static let dynamicTypeAllCases: [DynamicTypeSize] = Array(DynamicTypeSize.allCases)

    private var dynamicTypeSize: DynamicTypeSize {
        Self.dynamicTypeAllCases[dynamicTypeIndex]
    }

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                controls

                Divider()

                Text("taps: \(tapCount)")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)

                rowPreview
                    .dynamicTypeSize(dynamicTypeSize)
                    .environment(\.layoutDirection, rightToLeft ? .rightToLeft : .leftToRight)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
                    .background(DesignSystem.Color.bgOpaquePrimary)
            }
            .padding()
        }
    }

    @ViewBuilder
    private var controls: some View {
        group("Layout", initiallyExpanded: true) {
            pickerRow(
                title: "contentLead",
                cases: TangemRowContentLead.allCases,
                binding: $contentLead,
                label: { String(describing: $0) }
            )
            pickerRow(
                title: "verticalAlignment",
                cases: TangemRowVerticalAlignment.allCases,
                binding: $verticalAlignment,
                label: { String(describing: $0) }
            )
        }

        group("State") {
            Toggle("showDivider", isOn: $showDivider)
            Toggle("includeInnerPadding", isOn: $includeInnerPadding)
            Toggle("focusRing", isOn: $focusRing)
            Toggle("interactive (onTap)", isOn: $isInteractive)
            Toggle("isEnabled", isOn: $isEnabled)
            Toggle("overflow text", isOn: $overflow)
            Toggle("right-to-left", isOn: $rightToLeft)
        }

        group("Content lines") {
            Toggle("title", isOn: $showTitle)
            Toggle("subtitle", isOn: $showSubtitle)
            Toggle("value", isOn: $showValue)
            Toggle("subvalue", isOn: $showSubvalue)
        }

        group("Lines & order") {
            pickerRow(
                title: "lineOrder",
                cases: TangemRowLineOrder.allCases,
                binding: $lineOrder,
                label: { String(describing: $0) }
            )
            stepperRow("title lineLimit", value: $titleLineLimit)
            stepperRow("subtitle lineLimit", value: $subtitleLineLimit)
            stepperRow("value lineLimit", value: $valueLineLimit)
            stepperRow("subvalue lineLimit", value: $subvalueLineLimit)
        }

        group("Accessories & slots") {
            Toggle("start icon", isOn: $showStartIcon)
            Toggle("end icon", isOn: $showEndIcon)
            Toggle("title accessory", isOn: $showTitleAccessory)
            Toggle("subtitle accessory", isOn: $showSubtitleAccessory)
            Toggle("value accessory", isOn: $showValueAccessory)
            Toggle("subvalue accessory", isOn: $showSubvalueAccessory)
            Toggle("extra bottom", isOn: $showExtraBottom)
        }

        group("Accessibility (VoiceOver)", initiallyExpanded: true) {
            Toggle("override label", isOn: $overrideLabel)
            Toggle("custom hint", isOn: $customHint)
            voiceOverPanel
        }

        group("Text color overrides") {
            pickerRow(title: "title", cases: ShowcaseColor.allCases, binding: $titleColorOverride, label: { $0.label })
            pickerRow(title: "subtitle", cases: ShowcaseColor.allCases, binding: $subtitleColorOverride, label: { $0.label })
            pickerRow(title: "value", cases: ShowcaseColor.allCases, binding: $valueColorOverride, label: { $0.label })
            pickerRow(title: "subvalue", cases: ShowcaseColor.allCases, binding: $subvalueColorOverride, label: { $0.label })
        }

        group("Dynamic Type") {
            Stepper(
                "DT: \(String(describing: dynamicTypeSize))",
                value: $dynamicTypeIndex,
                in: 0 ... (Self.dynamicTypeAllCases.count - 1)
            )
        }
    }

    private var voiceOverPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("VoiceOver reads")
                .font(.caption)
                .foregroundStyle(.secondary)

            announcementRow("content element", reading: contentElementReading)

            if showExtraBottom {
                announcementRow("extra bottom", reading: "Extra bottom content")
            }

            if showEndIcon {
                Text("end(icon:) is decorative — accessibility-hidden, no separate element.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Text("Slots/accessories are opaque Views — predicted from samples; badge labels read only if the badge isn't accessibility-hidden.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func announcementRow(_ title: String, reading: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Text("\u{201C}\(reading)\u{201D}")
                .font(.callout.monospaced())
                .textSelection(.enabled)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Color.bgOpaqueSecondary, in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Predicted VoiceOver output

    private var contentElementReading: String {
        let segments: [String]
        if overrideLabel {
            segments = [overrideLabelSample]
        } else {
            let titleColumn = orderedLines(
                primary: line(text: showTitle ? titleSample : nil, accessory: showTitleAccessory ? titleAccessorySample : nil),
                secondary: line(text: showSubtitle ? subtitleSample : nil, accessory: showSubtitleAccessory ? subtitleAccessorySample : nil)
            )
            let valueColumn = orderedLines(
                primary: line(text: showValue ? valueSample : nil, accessory: showValueAccessory ? valueAccessorySample : nil),
                secondary: line(text: showSubvalue ? subvalueSample : nil, accessory: showSubvalueAccessory ? subvalueAccessorySample : nil)
            )
            segments = (titleColumn + valueColumn).compactMap { $0 }
        }

        var traits: [String] = []
        if isInteractive { traits.append("Button") }
        if focusRing { traits.append("Selected") }
        if !isEnabled { traits.append("Dimmed") }

        var pieces = [segments.joined(separator: ", ")]
        if traits.isNotEmpty { pieces.append(traits.joined(separator: ", ")) }
        if customHint { pieces.append(customHintSample) }

        return pieces.filter { $0.isNotEmpty }.joined(separator: ". ")
    }

    private func line(text: String?, accessory: String?) -> String? {
        let parts = [text, accessory].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }

    private func orderedLines(primary: String?, secondary: String?) -> [String?] {
        switch lineOrder {
        case .primaryFirst: [primary, secondary]
        case .secondaryFirst: [secondary, primary]
        }
    }

    private var titleSample: String { overflow ? "Very long title that would not fit and be truncated after third line" : "Title" }
    private var subtitleSample: String { overflow ? "Even longer subtitle that would not fit on a single line" : "Subtitle" }
    private var valueSample: String { overflow ? "Enormous value that overflows" : "Value" }
    private var subvalueSample: String { overflow ? "Very very long subvalue that would not fit" : "Subvalue" }

    private let titleAccessorySample = "New"
    private let subtitleAccessorySample = "info"
    private let valueAccessorySample = "+2.3%"
    private let subvalueAccessorySample = "≈"
    private let overrideLabelSample = "Custom row label"
    private let customHintSample = "The service is not available right now"

    @ViewBuilder
    private var rowPreview: some View {
        let row = TangemRow(
            title: showTitle ? titleSample : nil,
            subtitle: showSubtitle ? subtitleSample : nil,
            value: showValue ? valueSample : nil,
            subvalue: showSubvalue ? subvalueSample : nil
        )
        .titleAccessory {
            if showTitleAccessory {
                TangemBadgeV2(label: titleAccessorySample, accessibilityLabel: nil)
            }
        }
        .subtitleAccessory {
            if showSubtitleAccessory {
                TangemBadgeV2(label: subtitleAccessorySample, accessibilityLabel: nil)
                    .size(.x4)
            }
        }
        .valueAccessory {
            if showValueAccessory {
                TangemBadgeV2(label: valueAccessorySample, accessibilityLabel: nil)
                    .appearance(.success)
            }
        }
        .subvalueAccessory {
            if showSubvalueAccessory {
                TangemBadgeV2(label: subvalueAccessorySample, accessibilityLabel: nil)
                    .size(.x4)
            }
        }
        .start(icon: showStartIcon ? Assets.chevronRight : nil)
        .end(icon: showEndIcon ? Assets.chevronRight : nil)
        .extraBottom {
            if showExtraBottom {
                Text("Extra bottom content")
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .contentLead(contentLead)
        .verticalAlignment(verticalAlignment)
        .lineOrder(lineOrder)
        .titleLineLimit(titleLineLimit)
        .subtitleLineLimit(subtitleLineLimit)
        .valueLineLimit(valueLineLimit)
        .subvalueLineLimit(subvalueLineLimit)
        .showDivider(showDivider)
        .includeInnerPadding(includeInnerPadding)
        .focusRing(focusRing)
        .accessibilityLabel(overrideLabel ? overrideLabelSample : nil)
        .accessibilityHint(customHint ? customHintSample : nil)
        .overrideTextColors(.init(
            title: titleColorOverride.color,
            subtitle: subtitleColorOverride.color,
            value: valueColorOverride.color,
            subvalue: subvalueColorOverride.color
        ))

        if isInteractive {
            row.onTap { tapCount += 1 }.disabled(!isEnabled)
        } else {
            row.disabled(!isEnabled)
        }
    }

    private func group<Content: View>(
        _ title: String,
        initiallyExpanded: Bool = false,
        @ViewBuilder content: () -> Content
    ) -> some View {
        let inner = content()
        return DisclosureGroup(isExpanded: expansionBinding(title, default: initiallyExpanded)) {
            VStack(alignment: .leading, spacing: 8) {
                inner
            }
            .font(.callout)
            .padding(.top, 4)
        } label: {
            Text(title)
                .font(.headline)
                .textCase(.uppercase)
                .foregroundStyle(DesignSystem.Color.textAccentViolet)
        }
    }

    private func stepperRow(_ title: String, value: Binding<Int>) -> some View {
        Stepper("\(title): \(value.wrappedValue)", value: value, in: 1 ... 4)
    }

    private func expansionBinding(_ key: String, default defaultValue: Bool) -> Binding<Bool> {
        Binding(
            get: { expanded[key] ?? defaultValue },
            set: { expanded[key] = $0 }
        )
    }

    private func pickerRow<Value: Hashable>(
        title: String,
        cases: [Value],
        binding: Binding<Value>,
        label: @escaping (Value) -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption)
            Picker(title, selection: binding) {
                ForEach(cases, id: \.self) { value in
                    Text(label(value)).tag(value)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

// MARK: - ShowcaseColor

private enum ShowcaseColor: CaseIterable, Hashable {
    case `default`
    case red
    case orange
    case green
    case purple

    var label: String {
        switch self {
        case .default: "default"
        case .red: "red"
        case .orange: "orange"
        case .green: "green"
        case .purple: "purple"
        }
    }

    var color: Color? {
        switch self {
        case .default: nil
        case .red: .red
        case .orange: .orange
        case .green: .green
        case .purple: .purple
        }
    }
}

// MARK: - Previews

#if DEBUG
private func tangemRowVAlignSample(_ alignment: TangemRowVerticalAlignment, extra: Bool) -> some View {
    TangemRow(title: "Title", subtitle: "Subtitle", value: "Value", subvalue: "Subvalue")
        .titleAccessory { TangemBadgeV2(label: "New", accessibilityLabel: nil) }
        .valueAccessory { TangemBadgeV2(label: "+2.3%", accessibilityLabel: nil).appearance(.success) }
        .start(icon: Assets.chevronRight)
        .end(icon: Assets.chevronRight)
        .extraBottom {
            if extra {
                Text("Extra bottom content")
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .contentLead(.end)
        .verticalAlignment(alignment)
        .showDivider()
}

#Preview("Showcase") {
    TangemRowShowcase()
}

#Preview("RTL") {
    VStack(spacing: 24) {
        TangemRow(title: "Title", subtitle: "Subtitle", value: "Value", subvalue: "Subvalue")
            .start(icon: Assets.chevronRight)
            .showDivider()

        TangemRow(title: "Title", subtitle: "Subtitle", value: "Value", subvalue: "Subvalue")
            .start(icon: Assets.chevronRight)
            .end(icon: Assets.chevronRight)
            .contentLead(.end)
            .showDivider()
    }
    .padding()
    .background(DesignSystem.Color.bgOpaquePrimary)
    .environment(\.layoutDirection, .rightToLeft)
}

#Preview("VAlign debug") {
    VStack(spacing: 24) {
        tangemRowVAlignSample(.center, extra: false)
        tangemRowVAlignSample(.center, extra: true)
        tangemRowVAlignSample(.top, extra: true)
    }
    .padding()
    .background(DesignSystem.Color.bgOpaquePrimary)
}
#endif // DEBUG
