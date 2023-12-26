//
//  DetentBottomSheetModifier.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct DetentBottomSheetModifier<Item: Identifiable, ContentView: View>: ViewModifier {
    typealias Sheet = DetentBottomSheetContainer<ContentView>

    @Binding private var item: Item?

    private let detents: Set<Sheet.Detent>
    private let settings: Sheet.Settings
    private var sheetContent: (Item) -> ContentView

    init(
        item: Binding<Item?>,
        detents: Set<Sheet.Detent>,
        settings: Sheet.Settings,
        sheetContent: @escaping (Item) -> ContentView
    ) {
        _item = item
        self.detents = detents
        self.settings = settings
        self.sheetContent = sheetContent
    }

    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            aboveIOS16SheetUpdate(item: item, on: content)
        } else if #available(iOS 15.0, *) {
            beforeIOS16SheetUpdate(item: item, on: content)
        } else {
            beforeIOS15SheetUpdate(item: item, on: content)
        }
    }
}

// MARK: - Above iOS_16.4 UIKit Implementation BottomSheet

@available(iOS 16.4, *)
private extension DetentBottomSheetModifier {
    func aboveIOS16SheetUpdate(item: Item?, on content: Content) -> some View {
        content
            .sheet(item: $item) { item in
                DetentBottomSheetContainer(settings: settings) {
                    sheetContent(item)
                }
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(settings.cornerRadius)
                .presentationDetents(detents.map { $0.detentsAbove_16_0 }.toSet())
            }
    }
}

// MARK: - Before iOS_16.4 UIKit Implementation BottomSheet

@available(iOS 15.0, *)
private extension DetentBottomSheetModifier {
    func beforeIOS16SheetUpdate(item: Item?, on content: Content) -> some View {
        content
            .sheet(item: $item) { item in
                DetentBottomSheetContainer(settings: settings) {
                    sheetContent(item)
                }
                .presentationConfiguration { controller in
                    controller.detents = detents.map { $0.detentsAbove_15_0 }
                    controller.preferredCornerRadius = settings.cornerRadius
                }
            }
    }
}

// MARK: - Before iOS_15 UIKit Implementation BottomSheet

@available(iOS 14.0, *)
private extension DetentBottomSheetModifier {
    func beforeIOS15SheetUpdate(item: Item?, on content: Content) -> some View {
        content
            .sheet(item: $item) { item in
                DetentBottomSheetContainer(settings: settings) {
                    sheetContent(item)
                }
            }
    }
}
