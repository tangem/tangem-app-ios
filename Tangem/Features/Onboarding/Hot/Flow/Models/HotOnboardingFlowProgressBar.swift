//
//  HotOnboardingFlowProgressBar.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

extension View {
    func flowProgressBar(value: Double) -> some View {
        modifier(HotOnboardingFlowProgressBarViewModifier(value: value))
    }
}

// MARK: - HotOnboardingFlowNavBarViewModifier

private struct HotOnboardingFlowProgressBarViewModifier: ViewModifier {
    let value: Double

    private var preferenceValue: HotOnboardingFlowProgressBarItem {
        HotOnboardingFlowProgressBarItem(value: value)
    }

    func body(content: Content) -> some View {
        content
            .background {
                Color.clear.preference(
                    key: HotOnboardingFlowflowProgressBarValueKey.self,
                    value: preferenceValue
                )
            }
    }
}

// MARK: - HotOnboardingFlowProgressBarItem

struct HotOnboardingFlowProgressBarItem {
    private let id = UUID()
    let value: Double
}

extension HotOnboardingFlowProgressBarItem: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

struct HotOnboardingFlowflowProgressBarValueKey: PreferenceKey {
    static var defaultValue: HotOnboardingFlowProgressBarItem? = nil

    static func reduce(value: inout Value, nextValue: () -> Value) {
        if let next = nextValue() {
            value = next
        }
    }
}
