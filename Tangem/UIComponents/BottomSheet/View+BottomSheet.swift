//
//  View+BottomSheet.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

extension View {
    /// - Parameters:
    ///   - item: It'ill be used for create the content
    ///   - settings: You can setup the sheet's appearance
    ///   - stateObject: You can use custom`Sheet.StateObject` for tracking the sheet changes
    ///   - sheetContent: View for `sheetContent`
    @ViewBuilder
    func bottomSheet<Item: Identifiable, ContentView: View>(
        item: Binding<Item?>,
        settings: BottomSheetContainer<ContentView>.Settings,
        stateObject: BottomSheetContainer<ContentView>.StateObject = .init(),
        @ViewBuilder sheetContent: @escaping (Item) -> ContentView
    ) -> some View {
        modifier(
            BottomSheetModifier(
                item: item,
                stateObject: stateObject,
                settings: settings,
                sheetContent: sheetContent
            )
        )
    }

    @ViewBuilder
    func bottomSheet<Item: Identifiable, ContentView: View>(
        item: Binding<Item?>,
        backgroundColor: Color,
        stateObject: BottomSheetContainer<ContentView>.StateObject = .init(),
        @ViewBuilder sheetContent: @escaping (Item) -> ContentView
    ) -> some View {
        modifier(
            BottomSheetModifier(
                item: item,
                stateObject: stateObject,
                settings: .init(backgroundColor: backgroundColor),
                sheetContent: sheetContent
            )
        )
    }
}
