//
//  CheckmarkSnapshotScenario.swift
//  TangemSnapshotTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemSnapshotTestSupport
import TangemUI

enum CheckmarkSnapshotScenario: String, SnapshotScenario {
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
            SnapshotGrid(stateCases(isEnabledCases: [true, false]), columns: Checkmark.Value.allCases.count) { sample in
                checkmark(sample.value, size: sample.size)
                    .disabled(!sample.isEnabled)
            }
        case .hitArea:
            SnapshotGrid(hitAreaCases, columns: Checkmark.Size.allCases.count) { sample in
                checkmark(.checked, size: sample.size)
                    .expandsHitArea(sample.expandsHitArea)
                    .background(DesignSystem.Color.bgSecondary)
            }
        case .statesLargeText:
            SnapshotGrid(stateCases(isEnabledCases: [true]), columns: Checkmark.Value.allCases.count) { sample in
                checkmark(sample.value, size: sample.size)
            }
        }
    }
}

@MainActor
private extension CheckmarkSnapshotScenario {
    func stateCases(isEnabledCases: [Bool]) -> [(value: Checkmark.Value, size: Checkmark.Size, isEnabled: Bool)] {
        isEnabledCases.flatMap { isEnabled in
            Checkmark.Size.allCases.flatMap { size in
                Checkmark.Value.allCases.map { ($0, size, isEnabled) }
            }
        }
    }

    var hitAreaCases: [(size: Checkmark.Size, expandsHitArea: Bool)] {
        [true, false].flatMap { expandsHitArea in
            Checkmark.Size.allCases.map { ($0, expandsHitArea) }
        }
    }

    func checkmark(_ value: Checkmark.Value, size: Checkmark.Size) -> Checkmark {
        Checkmark(value: value, action: {}).size(size)
    }
}
