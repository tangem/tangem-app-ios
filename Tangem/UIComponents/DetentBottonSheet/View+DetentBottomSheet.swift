//
//  View+DetentBottomSheet.swift
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
    @available(iOS 14.0, *)
    @ViewBuilder
    func detentBottomSheet<Item: Identifiable, ContentView: View>(
        item: Binding<Item?>,
        settings: DetentBottomSheetContainer<ContentView>.Settings = .init(),
        @ViewBuilder sheetContent: @escaping (Item) -> ContentView
    ) -> some View {
        modifier(
            DetentBottomSheetModifier(
                item: item,
                settings: settings,
                sheetContent: sheetContent
            )
        )
    }
}
