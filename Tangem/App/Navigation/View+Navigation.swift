//
//  View+Navigation.swift
//  Recipes
//
//  Created by [REDACTED_AUTHOR]
//

import SwiftUI

extension View {
    func navigation<Item, Destination: View>(
        item: Binding<Item?>,
        @ViewBuilder destination: (Item) -> Destination
    ) -> some View {
        overlay(
            NavigationLink(
                destination: item.wrappedValue.map(destination),
                isActive: Binding(
                    get: { item.wrappedValue != nil },
                    set: { value in
                        if !value {
                            item.wrappedValue = nil
                        }
                    }
                ),
                label: { EmptyView() }
            )
        )
    }

    func navigationLinks<Links: View>(_ links: Links) -> some View {
        background(links)
    }
}
