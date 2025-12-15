//
//  View+DetentBottomSheet.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

extension View {
    /// - Parameters:
    ///   - item: It'ill be used for create the content
    ///   - detents: Map detents list for any ios version
    ///   - settings: You can setup the sheet's appearance
    ///   - sheetContent: View for `sheetContent`
    func detentBottomSheet<Item: Identifiable, ContentView: View>(
        item: Binding<Item?>,
        detents: Set<PresentationDetent> = [.large],
        backgroundColor: Color = Colors.Background.tertiary,
        presentationCornerRadius: CGFloat = 24,
        @ViewBuilder sheetContent: @escaping (Item) -> ContentView
    ) -> some View {
        sheet(item: item) { item in
            VStack(spacing: 0) {
                GrabberView()

                sheetContent(item)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(backgroundColor)
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(presentationCornerRadius)
            .presentationDetents(detents)
        }
    }
}
