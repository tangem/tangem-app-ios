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

    @ViewBuilder
    func tintCompat(_ color: Color) -> some View {
        if #available(iOS 15.0, *) {
            self.tint(color)
        } else {
            self
        }
    }

    @ViewBuilder
    func toggleStyleCompat(_ color: Color) -> some View {
        if #available(iOS 15.0, *) {
            self.tint(color)
        } else {
            toggleStyle(SwitchToggleStyle(tint: color))
        }
    }

    @ViewBuilder
    func searchableCompat(text: Binding<String>) -> some View {
        if #available(iOS 15.0, *) {
            self.searchable(text: text, placement: .navigationBarDrawer(displayMode: .always))
        } else {
            self
        }
    }

    @ViewBuilder
    func interactiveDismissDisabledCompat() -> some View {
        if #available(iOS 15, *) {
            self.interactiveDismissDisabled()
        } else {
            self
        }
    }

    @ViewBuilder
    func kerningCompat(_ kerning: CGFloat) -> some View {
        if #available(iOS 16, *) {
            self.kerning(kerning)
        } else {
            self
        }
    }

    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    func style(_ font: Font, color: Color) -> some View {
        self.font(font).foregroundColor(color)
    }

    /// A way to hide a SwiftUI view without altering the structural identity.
    /// See https://developer.apple.com/tutorials/swiftui-concepts/choosing-the-right-way-to-hide-a-view for details
    func hidden(_ shouldHide: Bool) -> some View {
        opacity(shouldHide ? 0.0 : 1.0)
    }
}
