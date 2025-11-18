//
//  MobileOnboardingFlowLoadingOverlay.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

extension View {
    func flowLoadingOverlay(isPresented: Bool) -> some View {
        background {
            Color.clear.preference(key: FlowLoadingOverlayKey.self, value: isPresented)
        }
    }
}

// MARK: - FlowLoadingOverlay keys

struct FlowLoadingOverlayKey: PreferenceKey {
    static var defaultValue: Bool = false

    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = value || nextValue()
    }
}
