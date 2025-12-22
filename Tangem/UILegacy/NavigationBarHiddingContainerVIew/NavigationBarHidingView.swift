//
//  NavigationBarHidingView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct NavigationBarHidingView<Content: View>: View {
    var shouldWrapInNavigationStack: Bool
    var content: Content

    var body: some View {
        if shouldWrapInNavigationStack {
            NavigationStack {
                content
                    .toolbarBackground(.hidden, for: .navigationBar)
            }
        } else {
            content
                .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    init(shouldWrapInNavigationStack: Bool, @ViewBuilder contentBuilder: () -> Content) {
        self.shouldWrapInNavigationStack = shouldWrapInNavigationStack
        content = contentBuilder()
    }
}
