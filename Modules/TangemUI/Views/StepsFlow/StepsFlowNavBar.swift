//
//  StepsFlowNavBar.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    func stepsFlowNavBar(title: String?) -> some View {
        background { Color.clear.preference(
            key: StepsFlowNavTitlePreferenceKey.self,
            value: title
        ) }
    }

    func stepsFlowNavBar<L: View>(leading: @escaping () -> L) -> some View {
        background { Color.clear.preference(
            key: StepsFlowNavLeadingItemPreferenceKey.self,
            value: StepsFlowNavBarItem(content: leading)
        ) }
    }

    func stepsFlowNavBar<T: View>(trailing: @escaping () -> T) -> some View {
        background { Color.clear.preference(
            key: StepsFlowNavTrailingItemPreferenceKey.self,
            value: StepsFlowNavBarItem(content: trailing)
        ) }
    }

    func stepsFlowNavBar<L: View, T: View>(
        leading: @escaping () -> L,
        trailing: @escaping () -> T
    ) -> some View {
        stepsFlowNavBar(leading: leading).stepsFlowNavBar(trailing: trailing)
    }

    func stepsFlow(isLoading: Bool) -> some View {
        background { Color.clear.preference(
            key: StepsFlowLoadingPreferenceKey.self,
            value: isLoading
        ) }
    }
}

struct StepsFlowNavTitlePreferenceKey: PreferenceKey {
    static var defaultValue: String?

    static func reduce(value: inout Value, nextValue: () -> Value) {
        guard let nextValue = nextValue() else { return }
        value = nextValue
    }
}

struct StepsFlowNavLeadingItemPreferenceKey: PreferenceKey {
    static var defaultValue: StepsFlowNavBarItem?

    static func reduce(value: inout Value, nextValue: () -> Value) {
        guard let nextValue = nextValue() else { return }
        value = nextValue
    }
}

struct StepsFlowNavTrailingItemPreferenceKey: PreferenceKey {
    static var defaultValue: StepsFlowNavBarItem?

    static func reduce(value: inout Value, nextValue: () -> Value) {
        guard let nextValue = nextValue() else { return }
        value = nextValue
    }
}

struct StepsFlowLoadingPreferenceKey: PreferenceKey {
    static var defaultValue: Bool = false

    static func reduce(value: inout Value, nextValue: () -> Value) {}
}
