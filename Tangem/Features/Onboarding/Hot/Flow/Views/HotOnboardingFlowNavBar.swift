//
//  HotOnboardingFlowNavBar.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

private typealias LeadingNavBarModifier<Content: View> = HotOnboardingFlowNavBarViewModifier<HotOnboardingFlowNavBarLeadingItemKey, Content>
private typealias TrailingNavBarModifier<Content: View> = HotOnboardingFlowNavBarViewModifier<HotOnboardingFlowNavBarTrailingItemKey, Content>

extension View {
    func flowNavBar<Content: View>(@ViewBuilder leadingItem: @escaping () -> Content) -> some View {
        modifier(LeadingNavBarModifier(itemContent: leadingItem))
    }

    func flowNavBar<Content: View>(@ViewBuilder trailingItem: @escaping () -> Content) -> some View {
        modifier(TrailingNavBarModifier(itemContent: trailingItem))
    }

    func flowNavBar(title: String) -> some View {
        preference(key: HotOnboardingFlowNavBarTitleKey.self, value: title)
    }
}

// MARK: - HotOnboardingFlowNavBarItem

struct HotOnboardingFlowNavBarItem {
    private let id = UUID()
    @ViewBuilder let content: () -> AnyView

    init(content: @escaping () -> some View) {
        self.content = { AnyView(content()) }
    }
}

extension HotOnboardingFlowNavBarItem: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - HotOnboardingFlowNavBarViewModifier

private struct HotOnboardingFlowNavBarViewModifier<Key: HotOnboardingFlowNavBarItemKey, ItemContent: View>: ViewModifier {
    @ViewBuilder let itemContent: () -> ItemContent

    private var preferenceValue: HotOnboardingFlowNavBarItem {
        HotOnboardingFlowNavBarItem(content: itemContent)
    }

    func body(content: Content) -> some View {
        content
            .background {
                Color.clear.preference(
                    key: Key.self,
                    value: preferenceValue
                )
            }
    }
}

// MARK: - HotOnboardingFlowNavBar keys

protocol HotOnboardingFlowNavBarItemKey: PreferenceKey where Value == HotOnboardingFlowNavBarItem? {}

struct HotOnboardingFlowNavBarLeadingItemKey: HotOnboardingFlowNavBarItemKey {
    static var defaultValue: Value = nil

    static func reduce(value: inout Value, nextValue: () -> Value) {
        if let next = nextValue() {
            value = next
        }
    }
}

struct HotOnboardingFlowNavBarTrailingItemKey: HotOnboardingFlowNavBarItemKey {
    static var defaultValue: Value = nil

    static func reduce(value: inout Value, nextValue: () -> Value) {
        if let next = nextValue() {
            value = next
        }
    }
}

struct HotOnboardingFlowNavBarTitleKey: PreferenceKey {
    static var defaultValue: String = .empty

    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = nextValue()
    }
}
