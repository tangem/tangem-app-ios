//
//  StepsFlowNavBar.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

extension View {
    func stepsFlowNavBar(title: String?) -> some View {
        modifier(StepsFlowNavTitleModifier(title: title))
    }

    func stepsFlowNavBar<L: View, T: View>(
        leading: @escaping () -> L = { EmptyView() },
        trailing: @escaping () -> T = { EmptyView() }
    ) -> some View {
        modifier(StepsFlowNavBarModifier(
            leadingItem: StepsFlowNavBarItem(content: leading),
            trailingItem: StepsFlowNavBarItem(content: trailing)
        ))
    }
}

private struct StepsFlowNavTitleModifier: ViewModifier {
    @EnvironmentObject private var navBarEnvironment: StepsFlowNavBarEnvironment

    let title: String?

    func body(content: Content) -> some View {
        content
            .onAppear {
                navBarEnvironment.title = title
            }
            .onChange(of: title) { title in
                navBarEnvironment.title = title
            }
    }
}

private struct StepsFlowNavBarModifier: ViewModifier {
    @EnvironmentObject private var navBarEnvironment: StepsFlowNavBarEnvironment

    let leadingItem: StepsFlowNavBarItem
    let trailingItem: StepsFlowNavBarItem

    func body(content: Content) -> some View {
        content
            .onAppear {
                navBarEnvironment.leadingItem = leadingItem
                navBarEnvironment.trailingItem = trailingItem
            }
            .onChange(of: leadingItem) { item in
                navBarEnvironment.leadingItem = item
            }
            .onChange(of: trailingItem) { item in
                navBarEnvironment.trailingItem = item
            }
    }
}
