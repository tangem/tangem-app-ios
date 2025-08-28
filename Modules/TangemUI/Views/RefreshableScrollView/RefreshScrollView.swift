//
//  RefreshScrollView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils
import TangemFoundation

public struct RefreshScrollView<Content: View>: View {
    // Init

    @ObservedObject private var stateObject: RefreshScrollViewStateObject
    private let content: () -> Content

    // Internal

    @State private var introspectResponderChainID = UUID()
    private let spacename = UUID()

    public init(stateObject: RefreshScrollViewStateObject, content: @escaping () -> Content) {
        self.stateObject = stateObject
        self.content = content
    }

    public var body: some View {
        ZStack(alignment: .top) {
            refreshControl()

            ScrollView {
                LazyVStack(spacing: 8) {
                    content()
                }
                .offset(y: stateObject.contentOffset)
                .readContentOffset(inCoordinateSpace: .named(spacename), bindTo: $stateObject.offset)
            }
            .coordinateSpace(name: spacename)
            .introspectResponderChain(
                introspectedType: UIScrollView.self,
                includeSubviews: true,
                updateOnChangeOf: introspectResponderChainID,
                action: { introspectedInstance in
                    introspectedInstance.delegate = stateObject.scrollViewDelegate
                }
            )
//                .onScrollPhaseChange { oldPhase, newPhase, context in
//                    print("oldphase: \(oldPhase), newPhase: \(newPhase)")
//                }
//                .onScrollGeometryChange(for: CGPoint.self, of: { geometry in
//                    return geometry.contentOffset
//                }, action: { oldValue, newValue in
//                    print("geometry.contentOffset ->>", oldValue, newValue)
//                })
            .onDidAppear {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    introspectResponderChainID = .init()
//                }
            }
        }
//        .readGeometry(bindTo: $stateObject.geometryInfo)
    }

    var dragGesture: some Gesture {
        DragGesture(coordinateSpace: .global)
            .onChanged { value in stateObject.dragging = true }
            .onEnded { _ in stateObject.dragging = false }
    }

    @ViewBuilder
    func refreshControl() -> some View {
        let progress = clamp(stateObject.correctYOffset / stateObject.settings.threshold, min: 0, max: 1)
        RefreshControl(state: stateObject.state, settings: stateObject.settings, progress: progress)
    }
}

struct RefreshControl: View {
    let state: RefreshScrollViewStateObject.RefreshState
    let settings: RefreshScrollViewStateObject.Settings
    let progress: CGFloat

    var body: some View {
        Rectangle()
            .fill(Color.red.opacity(0.5))
            .frame(height: settings.refreshAreaHeight)
            .overlay {
                switch state {
                case .idle:
                    ProgressView(value: progress).padding(.horizontal, 16)
                    // TangemRefreshableIcon(progress: progress, isAnimating: false)
                case .refreshing:
                    ProgressView().scaleEffect(2)
                    // TangemRefreshableIcon(progress: 1, isAnimating: true)
                case .afterRefreshing:
                    Text("STOP DRAGGING")
                }
            }
    }
}
