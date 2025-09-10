//
//  TangemIconRefreshControl.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation

struct TangemIconRefreshControl: View {
    let draggingStartFromTop: Bool
    let state: RefreshScrollViewStateObject.RefreshState
    let settings: RefreshScrollViewStateObject.Settings
    let offset: CGPoint

    private var progress: CGFloat {
        clamp(-offset.y.rounded() / settings.threshold, min: 0, max: 1)
    }

    private var isHidden: Bool {
        offset.y.rounded() > settings.refreshAreaHeight
    }

    private var isShowing: Bool {
        switch state {
        case .idle: draggingStartFromTop && progress > 0.4
        case .refreshing: true
        case .stillDragging: false
        }
    }

    private var isPulsing: Bool {
        switch state {
        case .idle: false
        case .refreshing, .stillDragging: true
        }
    }

    var body: some View {
        ZStack {
            if isShowing {
                icon
                    .hidden(isHidden)
                    .transition(.offset(y: -100).combined(with: .opacity))
                    .scaleEffect(isPulsing ? 1.3 : 1)
                    .animation(isPulsing ? .linear.repeatForever() : .none, value: isPulsing)
            }
        }
        .infinityFrame(axis: .horizontal)
        .frame(height: settings.refreshAreaHeight)
        .animation(.easeOut(duration: 0.1), value: isShowing)
    }

    var icon: some View {
        Assets.tangemIconMedium.image
            .renderingMode(.template)
            .foregroundStyle(Colors.Icon.primary1)
            .frame(height: settings.refreshAreaHeight / 2)
    }
}

#Preview {
    ContentView()
}

private struct ContentView: View {
    @State private var progress: CGFloat = 0.0
    @State private var refresh: Bool = false

    var body: some View {
        VStack {
            Slider(value: $progress)

            Button(
                refresh ? "Stop" : "Refresh",
                action: { refresh.toggle() }
            )

            TangemIconRefreshControl(
                draggingStartFromTop: true,
                state: refresh ? .refreshing {} : .idle,
                settings: .init(),
                offset: .init(x: 0, y: progress)
            )
        }
        .padding(.horizontal)
        .frame(alignment: .top)
    }
}
