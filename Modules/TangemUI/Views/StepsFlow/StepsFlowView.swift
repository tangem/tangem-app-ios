//
//  StepsFlowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public struct StepsFlowView: View {
    @StateObject private var viewModel: StepsFlowViewModel

    @State private var navigationTitle: String?
    @State private var navigationLeadingItem: StepsFlowNavBarItem?
    @State private var navigationTrailingItem: StepsFlowNavBarItem?
    @State private var isLoading: Bool = false

    private let configuration: StepsFlowConfiguration

    public init(
        builder: StepsFlowBuilder,
        configuration: StepsFlowConfiguration
    ) {
        _viewModel = StateObject(wrappedValue: StepsFlowViewModel(builder: builder))
        self.configuration = configuration
    }

    public var body: some View {
        VStack(spacing: 0) {
            flowBar
            stepsContent
        }
        .overlay(StepsFlowLoading(isLoading: isLoading))
        .animation(.default, value: viewModel.currentStepId)
    }
}

// MARK: - Subviews

private extension StepsFlowView {
    var flowBar: some View {
        StepsFlowBar(
            title: navigationTitle,
            leadingItem: navigationLeadingItem,
            trailingItem: navigationTrailingItem,
            progressBarValue: viewModel.progressValue,
            configuration: configuration
        )
    }

    @ViewBuilder
    var stepsContent: some View {
        if #available(iOS 17.0, *) {
            scrollStepsContent
        } else {
            tabStepsContent
        }
    }

    @available(iOS 17.0, *)
    var scrollStepsContent: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(viewModel.steps, id: \.id) { step in
                    stepView(step)
                        .containerRelativeFrame(.horizontal)
                        .tag(step.id)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $viewModel.currentStepId)
        .scrollDisabled(true)
    }

    var tabStepsContent: some View {
        TabView(selection: $viewModel.currentStepId) {
            ForEach(viewModel.steps, id: \.id) { step in
                stepView(step)
                    .tag(step.id)
            }
        }
        .highPriorityGesture(DragGesture())
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    func stepView(_ step: StepsFlowStep) -> some View {
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
