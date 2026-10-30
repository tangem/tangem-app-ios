//
//  BadgeSnapshotScenario.swift
//  TangemSnapshotTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemSnapshotTestSupport
import TangemUI

enum BadgeSnapshotScenario: String, SnapshotScenario {
    case appearances
    case sizes
    case slots
    case slotsRTL

    var layoutDirection: LayoutDirection {
        self == .slotsRTL ? .rightToLeft : .leftToRight
    }

    @MainActor
    @ViewBuilder
    var body: some View {
        switch self {
        case .appearances:
            SnapshotGrid(appearanceCases, columns: 5) { sample in
                variantAppearance(sample.variant, sample.appearance)
            }
        case .sizes:
            SnapshotGrid(sizeCases, columns: 4) { sample in
                sizeSample(sample.sample, size: sample.size)
            }
        case .slots, .slotsRTL:
            SnapshotGrid(slotCases, columns: 3) { sample in
                badge(slotStart: sample.start, slotEnd: sample.end)
            }
        }
    }
}

@MainActor
private extension BadgeSnapshotScenario {
    enum SlotMode: CaseIterable, Hashable {
        case off
        case icon
        case custom
    }

    enum SizeSample: CaseIterable, Hashable {
        case plain
        case slotStart
        case bothSlots
        case solidSuccess
    }

    var appearanceCases: [(variant: BadgeVariant, appearance: BadgeAppearance)] {
        BadgeVariant.allCases.flatMap { variant in
            BadgeAppearance.allCases.map { (variant, $0) }
        }
    }

    var sizeCases: [(size: BadgeSize, sample: SizeSample)] {
        BadgeSize.allCases.flatMap { size in
            SizeSample.allCases.map { (size, $0) }
        }
    }

    var slotCases: [(start: SlotMode, end: SlotMode)] {
        SlotMode.allCases.flatMap { start in
            SlotMode.allCases.map { (start, $0) }
        }
    }

    func variantAppearance(_ variant: BadgeVariant, _ appearance: BadgeAppearance) -> some View {
        Badge(label: String(describing: appearance), accessibilityLabel: nil)
            .variant(variant)
            .appearance(appearance)
    }

    @ViewBuilder
    func sizeSample(_ sample: SizeSample, size: BadgeSize) -> some View {
        let base = Badge(label: "USDT", accessibilityLabel: nil).size(size)

        switch sample {
        case .plain:
            base
        case .slotStart:
            base.slotStart(slotIcon(for: size))
        case .bothSlots:
            base.slotStart(slotIcon(for: size)).slotEnd(slotIcon(for: size))
        case .solidSuccess:
            base.variant(.solid).appearance(.success).slotStart(slotIcon(for: size))
        }
    }

    @ViewBuilder
    func badge(
        label: String = "Badge",
        size: BadgeSize = .x6,
        variant: BadgeVariant = .tinted,
        appearance: BadgeAppearance = .neutral,
        slotStart: SlotMode = .off,
        slotEnd: SlotMode = .off
    ) -> some View {
        let base = Badge(label: label, accessibilityLabel: nil)
            .size(size)
            .variant(variant)
            .appearance(appearance)

        switch (slotStart, slotEnd) {
        case (.off, .off): base
        case (.icon, .off): base.slotStart(slotIcon(for: size))
        case (.custom, .off): base.slotStart { customSlotContent }
        case (.off, .icon): base.slotEnd(slotIcon(for: size))
        case (.icon, .icon): base.slotStart(slotIcon(for: size)).slotEnd(slotIcon(for: size))
        case (.custom, .icon): base.slotStart { customSlotContent }.slotEnd(slotIcon(for: size))
        case (.off, .custom): base.slotEnd { customSlotContent }
        case (.icon, .custom): base.slotStart(slotIcon(for: size)).slotEnd { customSlotContent }
        case (.custom, .custom): base.slotStart { customSlotContent }.slotEnd { customSlotContent }
        }
    }

    var customSlotContent: some View {
        Circle()
            .fill(DesignSystem.Color.iconBrand)
            .aspectRatio(1, contentMode: .fit)
    }

    func slotIcon(for size: BadgeSize) -> ImageType {
        switch size {
        case .x9: DesignSystem.Icons.SignUsd.regular20
        case .x6: DesignSystem.Icons.SignUsd.regular16
        case .x4: DesignSystem.Icons.SignUsd.regular12
        }
    }
}
