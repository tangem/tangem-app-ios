//
//  FloatingSheetView+ContentFrameUpdate.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

extension View {
    public func floatingSheetContentFrameUpdateTrigger(_ trigger: some Hashable) -> some View {
        self.preference(key: FloatingSheetFrameUpdateTriggerPreferenceKey.self, value: trigger.hashValue)
    }

    public func floatingSheetContentFrameUpdateTrigger(_ trigger: Int) -> some View {
        self.preference(key: FloatingSheetFrameUpdateTriggerPreferenceKey.self, value: trigger)
    }

    public func floatingSheetContentFrameUpdateAnimation<TState>(for state: TState, animationForState: (TState) -> Animation) -> some View {
        self.preference(key: FloatingSheetFrameUpdateAnimationPreferenceKey.self, value: animationForState(state))
    }
}

public struct FloatingSheetFrameUpdateAnimationPreferenceKey: PreferenceKey {
    public static let defaultValue: Animation? = nil

    public static func reduce(value: inout Animation?, nextValue: () -> Animation?) {
        value = nextValue()
    }
}

public struct FloatingSheetFrameUpdateTriggerPreferenceKey: PreferenceKey {
    public static let defaultValue: Int = 0

    public static func reduce(value: inout Int, nextValue: () -> Int) {
        value = nextValue()
    }
}
