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
    @State private var horizontalSafeAreaInsets = EdgeInsets()

    private let configuration: StepsFlowConfiguration

    private var flowBarEdgeInsets: EdgeInsets {
        EdgeInsets(
            top: configuration.navigationBarTopPadding,
            leading: 16,
            bottom: 16,
            trailing: 16
        )
    }

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
                .padding(flowBarEdgeInsets)
                .displayCornerPadding()
                .background(viewModel.currentBackgroundColor?.ignoresSafeArea())

            stepsContent
        }
        .overlay(StepsFlowLoading(isLoading: viewModel.currentIsLoading))
        .animation(.default, value: viewModel.currentStepId)
        .onChange(of: viewModel.currentStepId) { _ in
            // Steps live side by side in a paging container, so a step scrolled off-screen
            // is never removed and its disappear lifecycle never fires. Dismiss any active
            // keyboard here so an input step (e.g. the access code) doesn't leave it hanging.
            UIApplication.shared.endEditing()
        }
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
                        .safeAreaPadding(horizontalSafeAreaInsets)
                        .containerRelativeFrame(.horizontal)
                        .tag(step.id)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $viewModel.currentStepId)
        .scrollDisabled(true)
        .ignoresSafeArea(.container, edges: .horizontal)
        .onGeometryChange(for: EdgeInsets.self, of: horizontalSafeAreaInsets(in:)) { insets in
            horizontalSafeAreaInsets = insets
        }
    }

    func horizontalSafeAreaInsets(in proxy: GeometryProxy) -> EdgeInsets {
        EdgeInsets(top: .zero, leading: proxy.safeAreaInsets.leading, bottom: .zero, trailing: proxy.safeAreaInsets.trailing)
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
            isActive: step.id == viewModel.currentStepId,
            onTitle: { viewModel.update(stepId: step.id, title: $0) },
            onLeadingItem: { viewModel.update(stepId: step.id, leadingItem: $0) },
            onTrailingItem: { viewModel.update(stepId: step.id, trailingItem: $0) },
            onBackgroundColor: { viewModel.update(stepId: step.id, backgroundColor: $0) },
            onLoading: { viewModel.update(stepId: step.id, isLoading: $0) }
        )
        .frame(maxHeight: .infinity, alignment: .top)
    }
}
