//
//  MobileOnboardingFlowNavBar.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

private typealias LeadingNavBarModifier<Content: View> = MobileOnboardingFlowNavBarViewModifier<MobileOnboardingFlowNavBarLeadingItemKey, Content>
private typealias TrailingNavBarModifier<Content: View> = MobileOnboardingFlowNavBarViewModifier<MobileOnboardingFlowNavBarTrailingItemKey, Content>

extension View {
    func flowNavBar<Content: View>(@ViewBuilder leadingItem: @escaping () -> Content) -> some View {
        modifier(LeadingNavBarModifier(itemContent: leadingItem))
    }

    func flowNavBar<Content: View>(@ViewBuilder trailingItem: @escaping () -> Content) -> some View {
        modifier(TrailingNavBarModifier(itemContent: trailingItem))
    }

    func flowNavBar(title: String) -> some View {
        preference(key: MobileOnboardingFlowNavBarTitleKey.self, value: title)
    }
}

// MARK: - MobileOnboardingFlowNavBarItem

struct MobileOnboardingFlowNavBarItem {
    private let id = UUID()
    @ViewBuilder let content: () -> AnyView

    init(content: @escaping () -> some View) {
        self.content = { AnyView(content()) }
    }
}

extension MobileOnboardingFlowNavBarItem: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - MobileOnboardingFlowNavBarViewModifier

private struct MobileOnboardingFlowNavBarViewModifier<Key: MobileOnboardingFlowNavBarItemKey, ItemContent: View>: ViewModifier {
    @ViewBuilder let itemContent: () -> ItemContent

    private var preferenceValue: MobileOnboardingFlowNavBarItem {
        MobileOnboardingFlowNavBarItem(content: itemContent)
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

// MARK: - MobileOnboardingFlowNavBar keys

protocol MobileOnboardingFlowNavBarItemKey: PreferenceKey where Value == MobileOnboardingFlowNavBarItem? {}

struct MobileOnboardingFlowNavBarLeadingItemKey: MobileOnboardingFlowNavBarItemKey {
    static var defaultValue: Value = nil

    static func reduce(value: inout Value, nextValue: () -> Value) {
        if let next = nextValue() {
            value = next
        }
    }
}

struct MobileOnboardingFlowNavBarTrailingItemKey: MobileOnboardingFlowNavBarItemKey {
    static var defaultValue: Value = nil

    static func reduce(value: inout Value, nextValue: () -> Value) {
        if let next = nextValue() {
            value = next
        }
    }
}

struct MobileOnboardingFlowNavBarTitleKey: PreferenceKey {
    static var defaultValue: String = .empty

    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = nextValue()
    }
}
