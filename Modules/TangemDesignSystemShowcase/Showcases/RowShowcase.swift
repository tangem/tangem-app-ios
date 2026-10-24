//
//  RowShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct RowShowcase: View {
    @State private var contentLead: RowContentLead = .equal
    @State private var verticalAlignment: RowVerticalAlignment = .top
    @State private var lineOrder: RowLineOrder = .primaryFirst

    @State private var showDivider = true
    @State private var includeInnerPadding = true
    @State private var focusRing = false
    @State private var isInteractive = true
    @State private var isEnabled = true
    @State private var overflow = false

    @State private var showTitle = true
    @State private var showSubtitle = true
    @State private var showValue = true
    @State private var showSubvalue = true

    @State private var titleLineLimit = 1
    @State private var subtitleLineLimit = 1
    @State private var valueLineLimit = 1
    @State private var subvalueLineLimit = 1

    @State private var showStartIcon = false
    @State private var showEndIcon = true
    @State private var showTitleAccessory = false
    @State private var showSubtitleAccessory = false
    @State private var showValueAccessory = false
    @State private var showSubvalueAccessory = false
    @State private var showExtraBottom = false

    @State private var overrideLabel = false
    @State private var customHint = false

    @State private var titleColor: TextColorOverride?
    @State private var subtitleColor: TextColorOverride?
    @State private var valueColor: TextColorOverride?
    @State private var subvalueColor: TextColorOverride?

    @State private var tapCount = 0

    var body: some View {
        DSShowcase("Row") { controls in
            DSShowcaseGroup("Layout") {
                controls.picker("Content lead", $contentLead)
                controls.picker("Vertical alignment", $verticalAlignment)
                controls.picker("Line order", $lineOrder)
            }

            DSShowcaseGroup("State") {
                controls.toggle("Divider", $showDivider)
                controls.toggle("Inner padding", $includeInnerPadding)
                controls.toggle("Focus ring", $focusRing)
                controls.toggle("Interactive (onTap)", $isInteractive)
                controls.toggle("Enabled", $isEnabled)
                controls.toggle("Overflow text", $overflow)
                controls.readout("Taps", "\(tapCount)")
            }

            DSShowcaseGroup("Content lines") {
                controls.toggle("Title", $showTitle)
                controls.toggle("Subtitle", $showSubtitle)
                controls.toggle("Value", $showValue)
                controls.toggle("Subvalue", $showSubvalue)
            }

            DSShowcaseGroup("Line limits") {
                controls.value("Title", $titleLineLimit, in: 1 ... 4)
                controls.value("Subtitle", $subtitleLineLimit, in: 1 ... 4)
                controls.value("Value", $valueLineLimit, in: 1 ... 4)
                controls.value("Subvalue", $subvalueLineLimit, in: 1 ... 4)
            }

            DSShowcaseGroup("Accessories & slots") {
                controls.toggle("Start icon", $showStartIcon)
                controls.toggle("End icon", $showEndIcon)
                controls.toggle("Title accessory", $showTitleAccessory)
                controls.toggle("Subtitle accessory", $showSubtitleAccessory)
                controls.toggle("Value accessory", $showValueAccessory)
                controls.toggle("Subvalue accessory", $showSubvalueAccessory)
                controls.toggle("Extra bottom", $showExtraBottom)
            }

            DSShowcaseGroup("Text color overrides") {
                controls.picker("Title", $titleColor)
                controls.picker("Subtitle", $subtitleColor)
                controls.picker("Value", $valueColor)
                controls.picker("Subvalue", $subvalueColor)
            }

            DSShowcaseGroup("Accessibility (VoiceOver)") {
                controls.toggle("Override label", $overrideLabel)
                controls.toggle("Custom hint", $customHint)
                controls.note("Content element reads: \u{201C}\(contentElementReading)\u{201D}")

                if showExtraBottom {
                    controls.note("Extra bottom reads: \u{201C}\(Sample.extraBottom)\u{201D}")
                }

                if showEndIcon {
                    controls.note("end(icon:) is decorative — accessibility-hidden, no separate element.")
                }

                controls.note("Slots and accessories are opaque views — the reading is predicted from the samples; badge labels are read only if the badge isn't accessibility-hidden.")
            }
        } stage: {
            livePreview
        } matrix: {
            DSShowcaseGroup("Content lead") {
                DSShowcaseMatrix(rows: RowContentLead.allCases) { lead in
                    sampleRow(contentLead: lead)
                }
            }

            DSShowcaseGroup("Vertical alignment") {
                DSShowcaseMatrix(
                    rows: RowVerticalAlignment.allCases,
                    columns: [false, true],
                    columnLabel: { $0 ? "extra bottom" : "plain" }
                ) { alignment, hasExtraBottom in
                    sampleRow(contentLead: .end, verticalAlignment: alignment, extraBottom: hasExtraBottom)
                }
            }

            DSShowcaseGroup("Line order") {
                DSShowcaseMatrix(rows: RowLineOrder.allCases) { order in
                    sampleRow(lineOrder: order)
                }
            }

            DSShowcaseGroup("State") {
                DSShowcaseMatrix(rows: MatrixState.allCases) { state in
                    sampleRow(isFocused: state == .focused)
                        .disabled(state == .disabled)
                }
            }
        }
    }

    @ViewBuilder
    private var livePreview: some View {
        let row = Row(
            title: showTitle ? titleSample : nil,
            subtitle: showSubtitle ? subtitleSample : nil,
            value: showValue ? valueSample : nil,
            subvalue: showSubvalue ? subvalueSample : nil
        )
        .titleAccessory {
            if showTitleAccessory {
                Badge(label: Sample.titleAccessory, accessibilityLabel: nil)
            }
        }
        .subtitleAccessory {
            if showSubtitleAccessory {
                Badge(label: Sample.subtitleAccessory, accessibilityLabel: nil)
                    .size(.x4)
            }
        }
        .valueAccessory {
            if showValueAccessory {
                Badge(label: Sample.valueAccessory, accessibilityLabel: nil)
                    .appearance(.success)
            }
        }
        .subvalueAccessory {
            if showSubvalueAccessory {
                Badge(label: Sample.subvalueAccessory, accessibilityLabel: nil)
                    .size(.x4)
            }
        }
        .start(icon: showStartIcon ? Assets.chevronRight : nil)
        .end(icon: showEndIcon ? Assets.chevronRight : nil)
        .extraBottom {
            if showExtraBottom {
                extraBottomContent
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
        .accessibilityLabel(overrideLabel ? Sample.overrideLabel : nil)
        .accessibilityHint(customHint ? Sample.customHint : nil)
        .overrideTextColors(RowOverrideTextColors(
            title: titleColor?.color,
            subtitle: subtitleColor?.color,
            value: valueColor?.color,
            subvalue: subvalueColor?.color
        ))

        if isInteractive {
            row.onTap { tapCount += 1 }.disabled(!isEnabled)
        } else {
            row.disabled(!isEnabled)
        }
    }

    private func sampleRow(
        contentLead: RowContentLead = .equal,
        verticalAlignment: RowVerticalAlignment = .top,
        lineOrder: RowLineOrder = .primaryFirst,
        extraBottom: Bool = false,
        isFocused: Bool = false
    ) -> some View {
        Row(title: Sample.title, subtitle: Sample.subtitle, value: Sample.value, subvalue: Sample.subvalue)
            .titleAccessory { Badge(label: Sample.titleAccessory, accessibilityLabel: nil) }
            .valueAccessory { Badge(label: Sample.valueAccessory, accessibilityLabel: nil).appearance(.success) }
            .start(icon: Assets.chevronRight)
            .end(icon: Assets.chevronRight)
            .extraBottom {
                if extraBottom {
                    extraBottomContent
                }
            }
            .contentLead(contentLead)
            .verticalAlignment(verticalAlignment)
            .lineOrder(lineOrder)
            .focusRing(isFocused)
            .showDivider()
            .onTap {}
            .frame(width: 320)
    }

    private var extraBottomContent: some View {
        Text(Sample.extraBottom)
            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Predicted VoiceOver output

    private var contentElementReading: String {
        let segments: [String]
        if overrideLabel {
            segments = [Sample.overrideLabel]
        } else {
            let titleColumn = orderedLines(
                primary: line(text: showTitle ? titleSample : nil, accessory: showTitleAccessory ? Sample.titleAccessory : nil),
                secondary: line(text: showSubtitle ? subtitleSample : nil, accessory: showSubtitleAccessory ? Sample.subtitleAccessory : nil)
            )
            let valueColumn = orderedLines(
                primary: line(text: showValue ? valueSample : nil, accessory: showValueAccessory ? Sample.valueAccessory : nil),
                secondary: line(text: showSubvalue ? subvalueSample : nil, accessory: showSubvalueAccessory ? Sample.subvalueAccessory : nil)
            )
            segments = (titleColumn + valueColumn).compactMap { $0 }
        }

        var traits: [String] = []
        if isInteractive { traits.append("Button") }
        if focusRing { traits.append("Selected") }
        if !isEnabled { traits.append("Dimmed") }

        var pieces = [segments.joined(separator: ", ")]
        if !traits.isEmpty { pieces.append(traits.joined(separator: ", ")) }
        if customHint { pieces.append(Sample.customHint) }

        return pieces.filter { !$0.isEmpty }.joined(separator: ". ")
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

    private var titleSample: String { overflow ? Sample.longTitle : Sample.title }
    private var subtitleSample: String { overflow ? Sample.longSubtitle : Sample.subtitle }
    private var valueSample: String { overflow ? Sample.longValue : Sample.value }
    private var subvalueSample: String { overflow ? Sample.longSubvalue : Sample.subvalue }
}

private extension RowShowcase {
    enum Sample {
        static var title: String { "Ethereum" }
        static var subtitle: String { "Main account" }
        static var value: String { "$2,184.20" }
        static var subvalue: String { "0.8421 ETH" }
        static var longTitle: String { "Wrapped Staked Ether on Arbitrum One via the Lido liquid staking protocol" }
        static var longSubtitle: String { "Main account · Ethereum, Arbitrum One, Optimism and Base networks" }
        static var longValue: String { "$1,284,902,184.20" }
        static var longSubvalue: String { "421,038.84210937 wstETH" }
        static var titleAccessory: String { "New" }
        static var subtitleAccessory: String { "Staking" }
        static var valueAccessory: String { "+2.3%" }
        static var subvalueAccessory: String { "≈" }
        static var extraBottom: String { "Rewards are paid out every 24 hours" }
        static var overrideLabel: String { "Ethereum, 2,184 dollars" }
        static var customHint: String { "The service is not available right now" }
    }

    enum TextColorOverride: CaseIterable {
        case error
        case warning
        case success
        case accent

        var color: Color {
            switch self {
            case .error: DesignSystem.Color.textStatusError
            case .warning: DesignSystem.Color.textStatusWarning
            case .success: DesignSystem.Color.textStatusSuccess
            case .accent: DesignSystem.Color.textAccentViolet
            }
        }
    }

    enum MatrixState: CaseIterable {
        case enabled
        case focused
        case disabled
    }
}
#endif
