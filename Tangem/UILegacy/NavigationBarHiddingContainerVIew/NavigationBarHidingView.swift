//
//  NavigationBarHidingView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct NavigationBarHidingView<Content: View>: View {
    var shouldWrapInNavigationView: Bool
    var content: Content

    var body: some View {
        if shouldWrapInNavigationView {
            NavigationView {
                content
                    .toolbarBackground(.hidden, for: .navigationBar)
            }
        } else {
            content
                .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    init(shouldWrapInNavigationView: Bool, @ViewBuilder contentBuilder: () -> Content) {
        self.shouldWrapInNavigationView = shouldWrapInNavigationView
        content = contentBuilder()
    }
}
