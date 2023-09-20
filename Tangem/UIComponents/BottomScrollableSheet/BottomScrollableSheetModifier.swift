//
//  BottomScrollableSheetModifier.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

private struct BottomScrollableSheetModifier<SheetHeader, SheetContent>: ViewModifier where SheetHeader: View, SheetContent: View {
    let managesSourceViewAppearance: Bool
    @ViewBuilder let sheetHeader: () -> SheetHeader
    @ViewBuilder let sheetContent: () -> SheetContent

    @StateObject private var stateObject = BottomScrollableSheetStateObject()

    private var scale: CGFloat {
        let scale = abs(1.0 - stateObject.percent / 10.0)
        return scale.isFinite ? scale : 1.0 // [REDACTED_TODO_COMMENT]
    }

    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            if managesSourceViewAppearance {
                // [REDACTED_TODO_COMMENT]
                content
                    .debugBorder(color: .red, width: 5.0)
                    .cornerRadius(14.0)
                    .scaleEffect(scale)
                    .edgesIgnoringSafeArea(.all)
            } else {
                content
                    .debugBorder(color: .red, width: 5.0)
            }

            BottomScrollableSheet(
                stateObject: stateObject,
                header: sheetHeader,
                content: sheetContent
            )
        }
        .modifier(
            if: managesSourceViewAppearance,
            then: { $0.background(Color.black.edgesIgnoringSafeArea(.all)) },
            else: { $0.preference(key: _PreferenceKey.self, value: scale) }
        )
    }
}

// MARK: - Convenience extensions

extension View {
    func bottomScrollableSheet<Header, Content>(
        managesSourceViewAppearance: Bool,
        header: @escaping () -> Header,
        content: @escaping () -> Content
    ) -> some View where Header: View, Content: View {
        modifier(
            BottomScrollableSheetModifier(
                managesSourceViewAppearance: managesSourceViewAppearance,
                sheetHeader: header,
                sheetContent: content
            )
        )
    }
}

// MARK: - Auxiliary types

// [REDACTED_TODO_COMMENT]
struct _PreferenceKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue: Value { .init() }

    static func reduce(value: inout Value, nextValue: () -> Value) {}
}
