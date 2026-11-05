//
//  ButtonStackShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemAssets
import TangemUI

struct ButtonStackShowcase: View {
    @State private var amount: Amount = .three
    @State private var slotContent: SlotContent = .icon
    @State private var isLastSlotDisabled = false
    @State private var taps = 0

    var body: some View {
        DSShowcase("ButtonStack", background: .gradient) { controls in
            controls.picker("Amount", $amount, options: Amount.allCases, label: \.title)
            controls.picker("First slot", $slotContent, options: SlotContent.allCases, label: \.title)
            controls.toggle("Disable last slot", $isLastSlotDisabled)
            controls.readout("Taps", "\(taps)")
        } stage: {
            stack(amount: amount, slotContent: slotContent, isLastSlotDisabled: isLastSlotDisabled)
        } matrix: {
            DSShowcaseMatrix(
                rows: Amount.allCases,
                columns: SlotContent.allCases,
                rowLabel: { "Amount=\($0.title)" },
                columnLabel: \.title
            ) { amount, slotContent in
                stack(amount: amount, slotContent: slotContent, isLastSlotDisabled: false)
            }
        }
    }

    private func stack(amount: Amount, slotContent: SlotContent, isLastSlotDisabled: Bool) -> ButtonStack {
        let first = firstButton(slotContent)

        switch amount {
        case .one:
            return ButtonStack(first.enabled(!isLastSlotDisabled))
        case .two:
            return ButtonStack(first, searchButton.enabled(!isLastSlotDisabled))
        case .three:
            return ButtonStack(first, searchButton, moreButton.enabled(!isLastSlotDisabled))
        }
    }

    private func firstButton(_ content: SlotContent) -> TangemUI.Button {
        switch content {
        case .icon:
            TangemUI.Button(icon: DesignSystem.Icons.Bell.regular20, accessibilityLabel: "Notifications", action: tap)
        case .label:
            TangemUI.Button(label: "Manage", accessibilityLabel: nil, action: tap)
        case .labelWithIcon:
            TangemUI.Button(label: "Manage", accessibilityLabel: nil, action: tap)
                .iconStart(DesignSystem.Icons.Bell.regular20)
        }
    }

    private var searchButton: TangemUI.Button {
        TangemUI.Button(icon: DesignSystem.Icons.Search.regular20, accessibilityLabel: "Search", action: tap)
    }

    private var moreButton: TangemUI.Button {
        TangemUI.Button(icon: DesignSystem.Icons.DotsVertical.regular20, accessibilityLabel: "More", action: tap)
    }

    private func tap() {
        taps += 1
    }
}

// MARK: - Axes

private extension ButtonStackShowcase {
    enum Amount: CaseIterable, Hashable {
        case one
        case two
        case three

        var title: String {
            switch self {
            case .one: "1"
            case .two: "2"
            case .three: "3"
            }
        }
    }

    enum SlotContent: CaseIterable, Hashable {
        case icon
        case label
        case labelWithIcon

        var title: String {
            switch self {
            case .icon: "Icon Button Ghost"
            case .label: "Button Ghost"
            case .labelWithIcon: "Button Ghost + icon"
            }
        }
    }
}
#endif
