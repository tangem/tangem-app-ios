//
//  MobileOnboardingFlowProgressBar.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

extension View {
    func flowProgressBar(value: Double) -> some View {
        modifier(MobileOnboardingFlowProgressBarViewModifier(value: value))
    }
}

// MARK: - MobileOnboardingFlowNavBarViewModifier

private struct MobileOnboardingFlowProgressBarViewModifier: ViewModifier {
    let value: Double

    private var preferenceValue: MobileOnboardingFlowProgressBarItem {
        MobileOnboardingFlowProgressBarItem(value: value)
    }

    func body(content: Content) -> some View {
        content
            .background {
                Color.clear.preference(
                    key: MobileOnboardingFlowProgressBarValueKey.self,
                    value: preferenceValue
                )
            }
    }
}

// MARK: - MobileOnboardingFlowProgressBarItem

struct MobileOnboardingFlowProgressBarItem {
    private let id = UUID()
    let value: Double
}

extension MobileOnboardingFlowProgressBarItem: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

struct MobileOnboardingFlowProgressBarValueKey: PreferenceKey {
    static var defaultValue: MobileOnboardingFlowProgressBarItem? = nil

    static func reduce(value: inout Value, nextValue: () -> Value) {
        if let next = nextValue() {
            value = next
        }
    }
}
