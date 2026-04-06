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

    @State private var refreshScrollViewStateObject: RefreshScrollViewStateObject
    @State private var viewModel: TangemElasticContainerModel

    private var scaleRatio: CGFloat {
        max(0.5, heightRatio ?? 1.0)
    }

    private var opacityRatio: CGFloat {
        heightRatio ?? 1.0
    }

    init() {
        let refreshScrollViewStateObject = RefreshScrollViewStateObject(
            settings: .init(stopRefreshingDelay: 1, refreshTaskTimeout: 120),
            refreshable: {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
            }
        )
        let viewModel = TangemElasticContainerModel(
            scrollViewInteractor: refreshScrollViewStateObject.scrollViewInteractor
        )

        self.refreshScrollViewStateObject = refreshScrollViewStateObject
        self.viewModel = viewModel
    }

    var body: some View {
        RefreshScrollView(
            stateObject: refreshScrollViewStateObject,
            contentSettings: .simpleContent,
            content: makePageContent
        )
        .onReceive(viewModel.heightRatioPublisher) { heightRatio = $0 }
    }

    private func makePageContent() -> some View {
        TangemElasticContainer(
            viewModel: viewModel,
            content: elasticContent
        )
    }

    private var elasticContent: some View {
        HStack(spacing: 24) {
            TangemButton(
                content: .icon(Assets.DesignSystem.arrowDown),
                action: {}
            )
            .setStyleType(.primary)

            TangemButton(
                content: .icon(Assets.DesignSystem.exchange),
                action: {}
            )
            .setStyleType(.primary)

            TangemButton(
                content: .icon(Assets.DesignSystem.dollar),
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
