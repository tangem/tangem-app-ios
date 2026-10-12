//
//  FeedCoverView.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct FeedCoverView: View {
    let cover: FeedCover
    let namespace: Namespace.ID

    var body: some View {
        NavigationStack {
            FeedDestinationView(destination: cover.destination)
        }
        .feedZoomTransition(from: cover.zoomSource, in: namespace)
        .presentationBackground(DesignSystem.Color.bgPrimary)
        .environment(\.mainShtorkaSize, nil)
        .environment(\.mainShtorkaContentIsCollapsed, false)
    }
}
