//
//  CheckboxSnapshotScenario.swift
//  TangemSnapshotTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemSnapshotTestSupport
import TangemUI

enum CheckboxSnapshotScenario: String, SnapshotScenario {
    case states
    case hitArea
    case statesLargeText

    var dynamicTypeSize: DynamicTypeSize {
        self == .statesLargeText ? .accessibility2 : .large
    }

    @MainActor
    @ViewBuilder
    var body: some View {
        switch self {
        case .states:
            SnapshotGrid(stateCases(isEnabledCases: [true, false]), columns: Checkbox.Value.allCases.count) { sample in
                checkbox(sample.value, size: sample.size)
                    .disabled(!sample.isEnabled)
            }
        case .hitArea:
            SnapshotGrid(hitAreaCases, columns: Checkbox.Size.allCases.count) { sample in
                checkbox(.checked, size: sample.size)
                    .expandsHitArea(sample.expandsHitArea)
                    .background(DesignSystem.Color.bgSecondary)
            }
        case .statesLargeText:
            SnapshotGrid(stateCases(isEnabledCases: [true]), columns: Checkbox.Value.allCases.count) { sample in
                checkbox(sample.value, size: sample.size)
            }
        }
    }
}

@MainActor
private extension CheckboxSnapshotScenario {
    func stateCases(isEnabledCases: [Bool]) -> [(value: Checkbox.Value, size: Checkbox.Size, isEnabled: Bool)] {
        isEnabledCases.flatMap { isEnabled in
            Checkbox.Size.allCases.flatMap { size in
                Checkbox.Value.allCases.map { ($0, size, isEnabled) }
            }
        }
    }

    var hitAreaCases: [(size: Checkbox.Size, expandsHitArea: Bool)] {
        [true, false].flatMap { expandsHitArea in
            Checkbox.Size.allCases.map { ($0, expandsHitArea) }
        }
    }

    func checkbox(_ value: Checkbox.Value, size: Checkbox.Size) -> Checkbox {
        Checkbox(value: value, action: {}).size(size)
    }
}
