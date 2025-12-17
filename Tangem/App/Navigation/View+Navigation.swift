//
//  View+Navigation.swift
//  Recipes
//
//  Created by [REDACTED_AUTHOR]
//

import SwiftUI

extension View {
    @available(
        iOS,
        deprecated: 100000.0,
        message: """
            This navigation approach is kept for backwards compatibility reasons.        
            Consider structuring your navigation using `navigationDestination(for:destination:)` or `NavigationStack.init(path:root:)` instead.
        """
    )
    func navigation<Item, Destination: View>(
        item: Binding<Item?>,
        @ViewBuilder destination: (Item) -> Destination
    ) -> some View {
        navigationDestination(
            isPresented: Binding(
                get: { item.wrappedValue != nil },
                set: { isPresented in
                    if !isPresented {
                        item.wrappedValue = nil
                    }
                }
            ),
            destination: {
                if let unwrappedItem = item.wrappedValue {
                    destination(unwrappedItem)
                }
            }
        )
    }

    func navigationLinks<Links: View>(_ links: Links) -> some View {
        background(links)
    }
}
