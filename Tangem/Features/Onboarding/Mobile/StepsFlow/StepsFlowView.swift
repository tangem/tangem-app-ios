//
//  StepsFlowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct StepsFlowView: View {
    @StateObject private var viewModel: StepsFlowViewModel
    @StateObject private var navBarEnvironment = StepsFlowNavBarEnvironment()

    @State private var isLoading: Bool = false

    private var navBarTitle: String {
        navBarEnvironment.title ?? .empty
    }

    private let configuration: StepsFlowConfiguration

    init(builder: StepsFlowBuilder, configuration: StepsFlowConfiguration) {
        _viewModel = StateObject(wrappedValue: StepsFlowViewModel(builder: builder))
        self.configuration = configuration
    }

    var body: some View {
        VStack(spacing: 0) {
            flowBar
            flowContent
        }
    }
}

// MARK: - Subviews

private extension StepsFlowView {
    var flowBar: some View {
        VStack(spacing: 4) {
            navBar

            if configuration.hasProgressBar {
                makeProgressBar(value: viewModel.progressValue)
                    .padding(.horizontal, configuration.progressBarPadding)
                    .animation(.default, value: viewModel.progressValue)
            }
        }
    }

    var flowContent: some View {
        StepsFlowContent(actions: viewModel.actions)
            .environmentObject(navBarEnvironment)
    }

    @ViewBuilder
    var loadingOverlay: some View {
        if isLoading {
            ZStack {
                Colors.Overlays.overlayPrimary
                    .ignoresSafeArea()
                ActivityIndicatorView()
            }
        }
    }
}

// MARK: - navBar

private extension StepsFlowView {
    var navBar: some View {
        NavigationBar(
            title: navBarTitle,
            settings: NavigationBar.Settings(
                backgroundColor: .clear,
                height: configuration.navigationBarHeight
            ),
            leftButtons: navBarLeadingItemView,
            rightButtons: navBarTrailingItemView
        )
    }

    func navBarLeadingItemView() -> some View {
        navBarEnvironment.leadingItem.map { $0.content() }
    }

    func navBarTrailingItemView() -> some View {
        navBarEnvironment.trailingItem.map { $0.content() }
    }
}

// MARK: - Progress bar

private extension StepsFlowView {
    func makeProgressBar(value: Double) -> some View {
        ProgressBar(
            height: configuration.progressBarHeight,
            currentProgress: value
        )
    }
}
