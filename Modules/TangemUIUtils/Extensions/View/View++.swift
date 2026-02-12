//
//  View++.swift
//  TangemUIUtils
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

public extension View { // [REDACTED_TODO_COMMENT]
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
