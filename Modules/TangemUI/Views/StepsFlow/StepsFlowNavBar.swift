//
//  StepsFlowNavBar.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
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

    func stepsFlow(isLoading: Bool) -> some View {
        modifier(StepsFlowLoadingModifier(isLoading: isLoading))
    }
}

private struct StepsFlowNavTitleModifier: ViewModifier {
    @EnvironmentObject private var environment: StepsFlowEnvironment

    let title: String?

    func body(content: Content) -> some View {
        content
            .onAppear {
                environment.navigationTitle = title
            }
            .onChange(of: title) { title in
                environment.navigationTitle = title
            }
    }
}

private struct StepsFlowNavBarModifier: ViewModifier {
    @EnvironmentObject private var environment: StepsFlowEnvironment

    let leadingItem: StepsFlowNavBarItem
    let trailingItem: StepsFlowNavBarItem

    func body(content: Content) -> some View {
        content
            .onAppear {
                environment.navigationLeadingItem = leadingItem
                environment.navigationTrailingItem = trailingItem
            }
            .onChange(of: leadingItem) { item in
                environment.navigationLeadingItem = item
            }
            .onChange(of: trailingItem) { item in
                environment.navigationTrailingItem = item
            }
    }
}

private struct StepsFlowLoadingModifier: ViewModifier {
    @EnvironmentObject private var environment: StepsFlowEnvironment

    let isLoading: Bool

    func body(content: Content) -> some View {
        content
            .onAppear {
                environment.isLoading = isLoading
            }
            .onChange(of: isLoading) { isLoading in
                environment.isLoading = isLoading
            }
    }
}
