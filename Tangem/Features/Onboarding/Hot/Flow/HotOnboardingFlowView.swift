//
//  HotOnboardingFlowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct HotOnboardingFlowView: View {
    @ObservedObject var builder: HotOnboardingFlowBuilder

    @State private var navBarTitle: String = .empty
    @State private var navBarLeadingItem: HotOnboardingFlowNavBarItem?
    @State private var navBarTrailingItem: HotOnboardingFlowNavBarItem?
    @State private var progressBarValue: Double?

    private let navigationBarHeight = OnboardingLayoutConstants.navbarSize.height
    private let progressBarHeight = OnboardingLayoutConstants.progressBarHeight

    var body: some View {
        content
            .animation(.default) // connect with value
            .onPreferenceChange(HotOnboardingFlowNavBarTitleKey.self) { navBarTitle = $0 }
            .onPreferenceChange(HotOnboardingFlowNavBarLeadingItemKey.self) { navBarLeadingItem = $0 }
            .onPreferenceChange(HotOnboardingFlowNavBarTrailingItemKey.self) { navBarTrailingItem = $0 }
            .onPreferenceChange(HotOnboardingFlowflowProgressBarValueKey.self) { progressBarValue = $0 }
    }
}

// MARK: - Subviews

private extension HotOnboardingFlowView {
    var content: some View {
        VStack(spacing: 0) {
            bar

            builder.content
                .frame(maxHeight: .infinity, alignment: .top)
                .transition(.opacity)
        }
    }

    var bar: some View {
        VStack(spacing: 4) {
            navBar

            if builder.hasProgressBar {
                progressBar
                    .padding(.horizontal, 8)
            }
        }
    }
}

// MARK: - navBar

private extension HotOnboardingFlowView {
    var navBar: some View {
        NavigationBar(
            title: navBarTitle,
            settings: NavigationBar.Settings(
                backgroundColor: .clear,
                height: navigationBarHeight
            ),
            leftButtons: navBarLeadingItemView,
            rightButtons: navBarTrailingItemView
        )
    }

    @ViewBuilder
    func navBarLeadingItemView() -> some View {
        navBarLeadingItem.map { $0.content() }
    }

    @ViewBuilder
    func navBarTrailingItemView() -> some View {
        navBarTrailingItem.map { $0.content() }
    }
}

// MARK: - progressBar

private extension HotOnboardingFlowView {
    var progressBar: some View {
        ProgressBar(
            height: progressBarHeight,
            currentProgress: progressBarValue ?? 0
        )
    }
}
