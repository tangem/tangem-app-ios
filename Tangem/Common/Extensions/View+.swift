//
//  VIew+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

extension View {
    func toAnyView() -> AnyView {
        AnyView(self)
    }

    @ViewBuilder func tintCompat(_ color: Color) -> some View {
        if #available(iOS 15.0, *) {
            self.tint(color)
        } else {
            self
        }
    }

    @ViewBuilder func toggleStyleCompat(_ color: Color) -> some View {
        if #available(iOS 15.0, *) {
            self.tint(color)
        } else if #available(iOS 14.0, *) {
            self.toggleStyle(SwitchToggleStyle(tint: color))
        } else {
            self
        }
    }

    @ViewBuilder func searchableCompat(text: Binding<String>) -> some View {
        if #available(iOS 15.0, *) {
            self.searchable(text: text, placement: .navigationBarDrawer(displayMode: .always))
        } else {
            self
        }
    }

    @ViewBuilder func ignoresKeyboard() -> some View {
        if #available(iOS 14.0, *) {
            self.ignoresSafeArea(.keyboard)
        } else {
            self
        }
    }

    @ViewBuilder func ignoresBottomArea() -> some View {
        if #available(iOS 14.0, *) {
            self.ignoresSafeArea(.container, edges: .bottom)
        } else {
            self.edgesIgnoringSafeArea(.bottom)
        }
    }

    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    @_disfavoredOverload
    @ViewBuilder public func onChange<V>(of value: V, perform action: @escaping (V) -> Void) -> some View where V: Equatable {
        if #available(iOS 14, *) {
            onChange(of: value, perform: action)
        } else {
            modifier(ChangeObserver(newValue: value, action: action))
        }
    }
}
