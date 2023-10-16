//
//  SheetModifier.swift
//  Recipes
//
//  Created by [REDACTED_AUTHOR]
//

import SwiftUI

struct SheetModifier<Item: Identifiable, Destination: View>: ViewModifier {
    // MARK: Stored Properties

    private let item: Binding<Item?>
    private let fullScreen: Bool
    private let destination: (Item) -> Destination

    // MARK: Initialization

    init(
        item: Binding<Item?>,
        fullScreen: Bool = false,
        @ViewBuilder content: @escaping (Item) -> Destination
    ) {
        self.item = item
        self.fullScreen = fullScreen
        destination = content
    }

    // MARK: Methods

    func body(content: Content) -> some View {
        if fullScreen {
            content.fullScreenCover(item: item, content: destination)
        } else {
            content.sheet(item: item, content: destination)
        }
    }
}

extension View {
    @ViewBuilder
    func sheet<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        fullScreen: Bool,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        modifier(SheetModifier(item: item, fullScreen: fullScreen, content: content))
    }
}
