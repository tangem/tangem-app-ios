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
    @State private var refreshScrollViewStateObject: RefreshScrollViewStateObject = .init(
        settings: .init(stopRefreshingDelay: 1, refreshTaskTimeout: 120),
        refreshable: {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
        }
    )

    var body: some View {
        RefreshScrollView(
            stateObject: refreshScrollViewStateObject,
            contentSettings: .simpleContent,
            content: makePageContent
        )
    }

    private func makePageContent() -> some View {
        TangemElasticContainer(
            onAddScrollViewDelegate: refreshScrollViewStateObject.addDelegate,
            onRemoveScrollViewDelegate: refreshScrollViewStateObject.removeDelegate,
            content: makeElasticContent
        )
    }

    private func makeElasticContent(ratio: CGFloat) -> some View {
        HStack(spacing: 24) {
            TangemButton(
                content: .icon(Assets.arrowDownMini.image),
                action: {}
            )
            .setStyleType(.primary)

            TangemButton(
                content: .icon(Assets.swappingIcon.image),
                action: {}
            )
            .setStyleType(.primary)

            TangemButton(
                content: .icon(Assets.dollarMini.image),
                action: {}
            )
            .setStyleType(.primary)
        }
        .scaleEffect(ratio)
        .opacity(ratio)
    }
}

#Preview {
    TangemElasticContainerPreview()
}
#endif
