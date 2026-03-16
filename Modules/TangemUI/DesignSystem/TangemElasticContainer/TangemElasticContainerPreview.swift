//
//  TangemElasticContainerPreview.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

#if DEBUG
struct TangemElasticContainerPreview: View {
    @State private var heightRatio: CGFloat?

    @State private var refreshScrollViewStateObject: RefreshScrollViewStateObject = .init(
        settings: .init(stopRefreshingDelay: 1, refreshTaskTimeout: 120),
        refreshable: {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
        }
    )

    private var scaleRatio: CGFloat {
        max(0.5, heightRatio ?? 1.0)
    }

    private var opacityRatio: CGFloat {
        heightRatio ?? 1.0
    }

    var body: some View {
        RefreshScrollView(
            stateObject: refreshScrollViewStateObject,
            contentSettings: .simpleContent,
            content: makePageContent
        )
    }

    private func makePageContent() -> some View {
        TangemElasticContainer(
            onAddScrollViewObserver: refreshScrollViewStateObject.addObserver,
            onRemoveScrollViewObserver: refreshScrollViewStateObject.removeObserver,
            content: elasticContent
        )
        .onPreferenceChange(TangemElasticContainerHeightRatio.self) { heightRatio = $0 }
    }

    private var elasticContent: some View {
        HStack(spacing: 24) {
            TangemButton(
                content: .icon(Assets.arrowDownMini),
                action: {}
            )
            .setStyleType(.primary)

            TangemButton(
                content: .icon(Assets.swappingIcon),
                action: {}
            )
            .setStyleType(.primary)

            TangemButton(
                content: .icon(Assets.dollarMini),
                action: {}
            )
            .setStyleType(.primary)
        }
        .scaleEffect(scaleRatio)
        .opacity(opacityRatio)
    }
}

#Preview {
    TangemElasticContainerPreview()
}
#endif
