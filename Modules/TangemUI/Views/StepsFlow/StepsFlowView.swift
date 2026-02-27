//
//  StepsFlowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils

public struct StepsFlowView: View {
    @StateObject private var viewModel: StepsFlowViewModel

    @Binding private var shouldFireConfetti: Bool

    @State private var navigationTitle: String?
    @State private var navigationLeadingItem: StepsFlowNavBarItem?
    @State private var navigationTrailingItem: StepsFlowNavBarItem?
    @State private var isLoading: Bool = false

    private let navigationRouter: NavigationRouter
    private let configuration: StepsFlowConfiguration

    public init(
        builder: StepsFlowBuilder,
        navigationRouter: NavigationRouter,
        shouldFireConfetti: Binding<Bool>,
        configuration: StepsFlowConfiguration
    ) {
        _viewModel = StateObject(wrappedValue: StepsFlowViewModel(builder: builder))
        _shouldFireConfetti = shouldFireConfetti
        self.navigationRouter = navigationRouter
        self.configuration = configuration
    }

    public var body: some View {
        rootView
            .navigationDestination(for: StepsFlowRoute.self, destination: destination)
            .overlay(StepsFlowLoading(isLoading: isLoading))
            .onReceive(viewModel.actionPublisher, perform: handleAction)
    }
}

// MARK: - Subviews

private extension StepsFlowView {
    @ViewBuilder
    var rootView: some View {
        if let step = viewModel.headStep {
            stepView(step)
        }
    }

    func destination(route: StepsFlowRoute) -> some View {
        stepView(route.step)
            .overlay {
                ConfettiView(shouldFireConfetti: $shouldFireConfetti)
            }
    }

    func stepView(_ step: StepsFlowStep) -> some View {
        VStack(spacing: 0) {
            StepsFlowBar(
                title: navigationTitle,
                leadingItem: navigationLeadingItem,
                trailingItem: navigationTrailingItem,
                progressBarValue: viewModel.progressValue,
                configuration: configuration
            )

            StepsFlowContent(
                step: step,
                onTitle: { navigationTitle = $0 },
                onLeadingItem: { navigationLeadingItem = $0 },
                onTrailingItem: { navigationTrailingItem = $0 },
                onLoading: { isLoading = $0 }
            )
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }
}

// MARK: - Navigation

private extension StepsFlowView {
    func handleAction(_ action: StepsFlowAction) {
        switch action {
        case .push(let node):
            let route = StepsFlowRoute(step: node.element)
            navigationRouter.push(route: route, animated: false)
        case .pop:
            navigationRouter.pop(animated: false)
        }
    }
}
