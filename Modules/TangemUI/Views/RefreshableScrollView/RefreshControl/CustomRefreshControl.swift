//
//  CustomRefreshControl.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation
import TangemAccessibilityIdentifiers

class CustomRefreshControlStateObject: ObservableObject {
    typealias State = RefreshScrollViewStateObject.RefreshState

    @Published private(set) var progress: CGFloat = 0
    @Published private(set) var state: State = .idle
    @Published private(set) var isHidden: Bool = false

    var isSpinning: Bool {
        switch state {
        case .idle, .willStartRefreshing: false
        case .refreshing, .stillDragging: true
        }
    }

    let settings: RefreshScrollViewStateObject.Settings

    init(settings: RefreshScrollViewStateObject.Settings) {
        self.settings = settings
    }

    func update(offset: CGPoint) {
        switch state {
        case .idle:
            isHidden = false
            progress = clamp(-offset.y.rounded() / settings.threshold, min: 0, max: 1)
        case .refreshing:
            isHidden = offset.y.rounded() > settings.refreshAreaHeight
        case .stillDragging:
            isHidden = true
        case .willStartRefreshing:
            break
        }
    }

    func update(state: State) {
        self.state = state
    }
}

struct CustomRefreshControl: View {
    @ObservedObject var stateObject: CustomRefreshControlStateObject

    var body: some View {
        ZStack {
            PetalProgressView(mode: stateObject.isSpinning ? .spinning : .progress(stateObject.progress))
                .hidden(stateObject.isHidden)
                .animation(.linear(duration: 0.1), value: stateObject.isHidden)
        }
        .infinityFrame(axis: .horizontal)
        .frame(height: stateObject.settings.refreshAreaHeight)
        .accessibilityIdentifier(refreshStateIdentifier)
    }

    private var refreshStateIdentifier: String {
        switch stateObject.state {
        case .idle:
            return MainAccessibilityIdentifiers.refreshStateIdle
        case .refreshing:
            return MainAccessibilityIdentifiers.refreshStateRefreshing
        case .stillDragging:
            return MainAccessibilityIdentifiers.refreshStateRefreshing // Still considered refreshing
        case .willStartRefreshing:
            return MainAccessibilityIdentifiers.refreshStateWillStartRefreshing
        }
    }
}
