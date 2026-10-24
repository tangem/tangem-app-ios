//
//  MessageBubbleShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemAssets
import TangemUI

struct MessageBubbleShowcase: View {
    @State private var variant: TangemMessageBubble.Variant = .success
    @State private var text = "Bitcoin is up 4.2% in the last 24 hours, the strongest move since March"
    @State private var hasIcon = true
    @State private var accessory: Accessory = .close
    @State private var frameWidth: CGFloat = 240
    @State private var closeTaps = 0

    var body: some View {
        DSShowcase("MessageBubble") { controls in
            controls.picker("Variant", $variant)
            controls.text("Text", $text)
            controls.toggle("Icon", $hasIcon)
            controls.picker("Trailing accessory", $accessory)
            controls.value("Frame width", $frameWidth, in: 80 ... 360, step: 1)
            controls.readout("Close taps", "\(closeTaps)")
        } stage: {
            TangemMessageBubble(text: text)
                .variant(variant)
                .icon(hasIcon ? DesignSystem.Icons.ChartLineVertical.regular16 : nil)
                .trailingAccessory(trailingAccessory(for: accessory) { closeTaps += 1 })
                .accessibilityIdentifier("messageBubble")
                .frame(width: frameWidth)
                .padding(.top, 8)
        } matrix: {
            DSShowcaseMatrix(rows: TangemMessageBubble.Variant.allCases, columns: Accessory.allCases) { variant, accessory in
                TangemMessageBubble(text: "Price alert set")
                    .variant(variant)
                    .icon(DesignSystem.Icons.ChartLineVertical.regular16)
                    .trailingAccessory(trailingAccessory(for: accessory) {})
                    .padding(.top, 8)
            }
        }
    }

    private func trailingAccessory(
        for accessory: Accessory,
        onClose: @escaping () -> Void
    ) -> TangemMessageBubble.TrailingAccessory? {
        switch accessory {
        case .close: .close(action: onClose)
        case .chevron: .chevron
        case .off: nil
        }
    }
}

private extension MessageBubbleShowcase {
    enum Accessory: CaseIterable {
        case close
        case chevron
        case off
    }
}
#endif
