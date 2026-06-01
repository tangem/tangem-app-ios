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
        .overlay(StepsFlowLoading(isLoading: viewModel.currentIsLoading))
        .animation(.default, value: viewModel.currentStepId)
    }
}

// MARK: - Subviews

private extension StepsFlowView {
    var flowBar: some View {
        StepsFlowBar(
            title: viewModel.currentTitle,
            leadingItem: viewModel.currentLeadingItem,
            trailingItem: viewModel.currentTrailingItem,
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
            onTitle: { viewModel.update(stepId: step.id, title: $0) },
            onLeadingItem: { viewModel.update(stepId: step.id, leadingItem: $0) },
            onTrailingItem: { viewModel.update(stepId: step.id, trailingItem: $0) },
            onLoading: { viewModel.update(stepId: step.id, isLoading: $0) }
        )
        .frame(maxHeight: .infinity, alignment: .top)
    }
}
