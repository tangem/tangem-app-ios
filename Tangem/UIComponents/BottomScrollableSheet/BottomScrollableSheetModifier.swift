//
//  BottomScrollableSheetModifier.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

private struct BottomScrollableSheetModifier<SheetHeader, SheetContent>: ViewModifier where SheetHeader: View, SheetContent: View {
    let prefersGrabberVisible: Bool

    @ViewBuilder let sheetHeader: () -> SheetHeader
    @ViewBuilder let sheetContent: () -> SheetContent

    @StateObject private var stateObject = BottomScrollableSheetStateObject()

    private var scale: CGFloat {
        let scale = abs(1.0 - stateObject.percent / 10.0)
        return scale.isFinite ? scale : 1.0 // [REDACTED_TODO_COMMENT]
    }

    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            // [REDACTED_TODO_COMMENT]
            content
                .cornerRadius(14.0)
                .scaleEffect(scale)
                .edgesIgnoringSafeArea(.all)

            BottomScrollableSheet(
                stateObject: stateObject,
                header: sheetHeader,
                content: sheetContent
            )
            .prefersGrabberVisible(prefersGrabberVisible)
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}

// MARK: - Convenience extensions

extension View {
    func bottomScrollableSheet<Header, Content>(
        prefersGrabberVisible: Bool,
        @ViewBuilder header: @escaping () -> Header,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View where Header: View, Content: View {
        modifier(
            BottomScrollableSheetModifier(
                prefersGrabberVisible: prefersGrabberVisible,
                sheetHeader: header,
                sheetContent: content
            )
        )
    }
}
