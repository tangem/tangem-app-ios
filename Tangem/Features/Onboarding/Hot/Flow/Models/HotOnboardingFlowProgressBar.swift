//
//  HotOnboardingFlowProgressBar.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

extension View {
    func flowProgressBar(value: Double?) -> some View {
        preference(key: HotOnboardingFlowflowProgressBarValueKey.self, value: value)
    }
}

struct HotOnboardingFlowflowProgressBarValueKey: PreferenceKey {
    static var defaultValue: Double? = nil

    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = nextValue()
    }
}
