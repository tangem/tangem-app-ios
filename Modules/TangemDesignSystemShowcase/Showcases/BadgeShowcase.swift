//
//  BadgeShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemAssets
import TangemUI

struct BadgeShowcase: View {
    @State private var size: BadgeSize = .x6
    @State private var variant: BadgeVariant = .tinted
    @State private var appearance: BadgeAppearance = .neutral
    @State private var slotStartMode: SlotMode = .off
    @State private var slotEndMode: SlotMode = .off
    @State private var label = "Staking APY 4.8%"

    var body: some View {
        DSShowcase("Badge") { controls in
            controls.picker("Size", $size)
            controls.picker("Variant", $variant)
            controls.picker("Appearance", $appearance)
            controls.picker("Slot start", $slotStartMode)
            controls.picker("Slot end", $slotEndMode)
            controls.text("Label", $label)
        } stage: {
            configuredBadge
                .id(size)
        } matrix: {
            DSShowcaseGroup("Variant × Appearance") {
                DSShowcaseMatrix(rows: BadgeVariant.allCases, columns: BadgeAppearance.allCases) { variant, appearance in
                    Badge(label: DSShowcaseLabel.text(appearance), accessibilityLabel: nil)
                        .variant(variant)
                        .appearance(appearance)
                }
            }

            DSShowcaseGroup("Sizes") {
                DSShowcaseMatrix(rows: BadgeSize.allCases, columns: SizeSample.allCases) { size, sample in
                    sizeSample(sample, size: size)
                }
            }
        }
    }

    @ViewBuilder
    private var configuredBadge: some View {
        let base = Badge(label: label, accessibilityLabel: nil)
            .size(size)
            .variant(variant)
            .appearance(appearance)

        switch (slotStartMode, slotEndMode) {
        case (.off, .off): base
        case (.icon, .off): base.slotStart(size.slotIcon)
        case (.custom, .off): base.slotStart { customSlotContent }
        case (.off, .icon): base.slotEnd(size.slotIcon)
        case (.icon, .icon): base.slotStart(size.slotIcon).slotEnd(size.slotIcon)
        case (.custom, .icon): base.slotStart { customSlotContent }.slotEnd(size.slotIcon)
        case (.off, .custom): base.slotEnd { customSlotContent }
        case (.icon, .custom): base.slotStart(size.slotIcon).slotEnd { customSlotContent }
        case (.custom, .custom): base.slotStart { customSlotContent }.slotEnd { customSlotContent }
        }
    }

    private var customSlotContent: some View {
        Circle()
            .fill(DesignSystem.Color.iconBrand)
            .aspectRatio(1, contentMode: .fit)
    }

    @ViewBuilder
    private func sizeSample(_ sample: SizeSample, size: BadgeSize) -> some View {
        let base = Badge(label: "USDT", accessibilityLabel: nil).size(size)

        switch sample {
        case .plain:
            base
        case .slotStart:
            base.slotStart(size.slotIcon)
        case .bothSlots:
            base.slotStart(size.slotIcon).slotEnd(size.slotIcon)
        case .solidSuccess:
            base.variant(.solid).appearance(.success).slotStart(size.slotIcon)
        }
    }
}

private extension BadgeShowcase {
    enum SlotMode: CaseIterable {
        case off
        case icon
        case custom
    }

    enum SizeSample: CaseIterable {
        case plain
        case slotStart
        case bothSlots
        case solidSuccess
    }
}

private extension BadgeSize {
    var slotIcon: ImageType {
        switch self {
        case .x9: DesignSystem.Icons.SignUsd.regular20
        case .x6: DesignSystem.Icons.SignUsd.regular16
        case .x4: DesignSystem.Icons.SignUsd.regular12
        }
    }
}
#endif
