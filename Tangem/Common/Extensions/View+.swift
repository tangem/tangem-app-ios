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

    func visible(_ shouldShow: Bool) -> some View {
        opacity(shouldShow ? 1 : 0)
    }

    /// Two separate methods exist for iOS <16.0 and >=16.0 because they must be applied at the different levels
    /// of the view hierarchy in order to work.
    ///
    /// This method must be used on the content view INSIDE `ScrollView`, otherwise it won't work.
    /// See an example below:
    /// ```
    /// struct SomeView: View {
    ///     [REDACTED_USERNAME] private var isScrollDisabled = false
    ///
    ///     var body: some View {
    ///         ScrollView {
    ///             LazyVStack() {
    ///                 // Some scrollable content
    ///             }
    ///             .ios15AndBelowScrollDisabledCompat(isScrollDisabled)
    ///         }
    ///     }
    /// }
    /// ```
    @available(iOS, obsoleted: 16.0, message: "Replace with native 'scrollDisabled(_:)' when the minimum deployment target reaches 16.0")
    @ViewBuilder
    func ios15AndBelowScrollDisabledCompat(_ disabled: Bool) -> some View {
        if #available(iOS 16.0, *) {
            self
        } else {
            modifier(IOS15AndBelowScrollDisabledModifier(isDisabled: disabled))
        }
    }

    /// Two separate methods exist for iOS <16.0 and >=16.0 because they must be applied at the different levels
    /// of the view hierarchy in order to work.
    ///
    /// This method  must be used OUTSIDE of `ScrollView` (as well as the native `scrollDisabled(_:)`) , otherwise it won't work.
    /// See an example below:
    /// ```
    /// struct SomeView: View {
    ///     [REDACTED_USERNAME] private var isScrollDisabled = false
    ///
    ///     var body: some View {
    ///         ScrollView {
    ///             LazyVStack() {
    ///                 // Some scrollable content
    ///             }
    ///         }
    ///         .ios16AndAboveScrollDisabledCompat(isScrollDisabled)
    ///     }
    /// }
    /// ```
    @available(iOS, obsoleted: 16.0, message: "Replace with native 'scrollDisabled(_:)' when the minimum deployment target reaches 16.0")
    @ViewBuilder
    func ios16AndAboveScrollDisabledCompat(_ disabled: Bool) -> some View {
        if #available(iOS 16.0, *) {
            scrollDisabled(disabled)
        } else {
            self
        }
    }

    @ViewBuilder
    func matchedGeometryEffectOptional<ID>(id: ID?, in namespace: Namespace.ID?, properties: MatchedGeometryProperties = .frame, anchor: UnitPoint = .center, isSource: Bool = true) -> some View where ID: Hashable {
        if let id, let namespace {
            matchedGeometryEffect(id: id, in: namespace, properties: properties, anchor: anchor, isSource: isSource)
        } else if id == nil, namespace == nil {
            self
        } else {
            #if DEBUG
            fatalError("You must set either both ID and namespace or neither")
            #else
            self
            #endif
        }
    }

    // [REDACTED_TODO_COMMENT]
    @available(*, deprecated, message: "For test purposes only, remove when not needed")
    @ViewBuilder
    func printSize(_ prefix: String) -> some View {
        readGeometry(\.size) { print(prefix, $0) }
    }

    // [REDACTED_TODO_COMMENT]
    @available(*, deprecated, message: "For test purposes only, remove when not needed")
    @inline(__always)
    static func printChanges(
        file: StaticString = #fileID,
        line: UInt = #line,
        column: UInt = #column
    ) {
        #if DEBUG
        if #available(iOS 15.0, *) {
            Self._printChanges()
        } else {
            print("View body computed in \(file):\(line):\(column)")
        }
        #endif
    }

    // [REDACTED_TODO_COMMENT]
    @available(*, deprecated, message: "For test purposes only, remove when not needed")
    func debugBorder(color: Color, width: CGFloat = 1.0 / UIScreen.main.scale) -> some View {
        modifier(DebugBorderViewModifier(color: color, width: width))
    }
}

// MARK: - Auxiliary types

// [REDACTED_TODO_COMMENT]
private struct DebugBorderViewModifier: ViewModifier {
    let color: Color
    let width: CGFloat

    func body(content: Content) -> some View {
        #if DEBUG
        let showDebugBorders = UserDefaults.standard.bool(forKey: "com.tangem.ShowDebugBorders")

        return content.border(
            showDebugBorders ? color : .clear,
            width: showDebugBorders ? width : 0.0
        )
        #else
        return content
        #endif
    }
}

// MARK: - Convenience extensions

// [REDACTED_TODO_COMMENT]
extension Color {
    @available(*, deprecated, message: "For test purposes only, remove when not needed")
    static var random: Self {
        return Color(
            hue: .random(in: 0.0 ... 1.0),
            saturation: 1.0,
            brightness: 1.0
        )
    }
}
