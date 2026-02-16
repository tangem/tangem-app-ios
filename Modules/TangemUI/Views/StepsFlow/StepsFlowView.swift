//
//  StepsFlowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public struct StepsFlowView: View {
    @StateObject private var environment = StepsFlowEnvironment()

    private var navBarTitle: String {
        environment.navigationTitle ?? .empty
    }

    private var progressValue: Double {
        guard
            let position = builder.currentPosition,
            position.total > 0
        else {
            return 0
        }

        return Double(position.index + 1) / Double(position.total)
    }

    private let builder: StepsFlowBuilder
    private let configuration: StepsFlowConfiguration

    public init(builder: StepsFlowBuilder, configuration: StepsFlowConfiguration) {
        self.builder = builder
        self.configuration = configuration
    }

    public var body: some View {
        VStack(spacing: 0) {
            flowBar
            flowContent
        }
        .overlay(loadingOverlay)
    }
}

// MARK: - Subviews

private extension StepsFlowView {
    var flowBar: some View {
        VStack(spacing: 4) {
            navBar

            if configuration.hasProgressBar {
                makeProgressBar(value: progressValue)
                    .padding(.horizontal, configuration.progressBarPadding)
                    .animation(.default, value: progressValue)
            }
        }
    }

    var flowContent: some View {
        StepsFlowContent(builder: builder)
            .environmentObject(environment)
    }

    @ViewBuilder
    var loadingOverlay: some View {
        if environment.isLoading {
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
        environment.navigationLeadingItem.map { $0.content() }
    }

    func navBarTrailingItemView() -> some View {
        environment.navigationTrailingItem.map { $0.content() }
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
