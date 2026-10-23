//
//  View+Footer.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    func footer(_ footer: () -> Footer) -> some View {
        let footer = footer()
        return modifier(FooterModifier(footer: footer, search: footer.search))
    }

    // [REDACTED_TODO_COMMENT]
    func legacyFooter<FooterView: View>(@ViewBuilder _ footer: () -> FooterView) -> some View {
        modifier(FooterModifier(footer: footer(), search: nil))
    }
}

private struct FooterModifier<FooterView: View>: ViewModifier {
    let footer: FooterView
    let search: Search?

    @Environment(\.footerHost) private var host
    @Environment(\.self) private var environment
    @State private var isSearchPresented = false

    func body(content: Content) -> some View {
        if host.isModal {
            content
                .background { nativeSearch }
                .preference(key: ModalFooterPreferenceKey.self, value: usesNativeSearch ? nil : hostedFooter)
                .preference(key: ModalSearchPresentedPreferenceKey.self, value: usesNativeSearch && isPresented.wrappedValue)
        } else {
            content
                .background { nativeSearch }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if !usesNativeSearch {
                        footer
                    }
                }
        }
    }

    private var hostedFooter: ModalFooterItem {
        ModalFooterItem(view: AnyView(footer.environment(\.self, environment)))
    }

    private var isPresented: Binding<Bool> {
        search?.isActive ?? $isSearchPresented
    }

    private var usesNativeSearch: Bool {
        guard #available(iOS 26.0, *) else {
            return false
        }

        return host.supportsNativeSearch && search != nil
    }

    @ViewBuilder
    private var nativeSearch: some View {
        if #available(iOS 26.0, *), usesNativeSearch, let search {
            Color.clear
                .tangemSearchable(
                    text: search.$text,
                    isActive: isPresented,
                    prompt: search.placeholderText,
                    placement: .bottom
                )
                .searchPresentationToolbarBehavior(host.isModal ? .avoidHidingContent : .automatic)
        }
    }
}

private extension Footer {
    var search: Search? {
        guard case .search(let search) = content.kind else {
            return nil
        }

        return search
    }
}

struct FooterHost {
    var modalSurface: Color?
    var supportsNativeSearch = true

    var isModal: Bool {
        modalSurface != nil
    }
}

// [REDACTED_TODO_COMMENT]
struct ModalFooterItem {
    let view: AnyView
}

struct ModalFooterPreferenceKey: PreferenceKey {
    static var defaultValue: ModalFooterItem? { nil }

    static func reduce(value: inout ModalFooterItem?, nextValue: () -> ModalFooterItem?) {
        value = nextValue() ?? value
    }
}

struct ModalSearchPresentedPreferenceKey: PreferenceKey {
    static var defaultValue: Bool { false }

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

extension EnvironmentValues {
    @Entry var footerHost = FooterHost()
}
