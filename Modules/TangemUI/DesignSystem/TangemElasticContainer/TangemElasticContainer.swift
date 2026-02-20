//
//  TangemElasticContainer.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

public struct TangemElasticContainer<Content: View>: View {
    public typealias ContentBuilder = (_ expandRatio: CGFloat) -> Content

    @StateObject private var viewModel: TangemElasticContainerModel

    private let content: ContentBuilder

    public init(
        onAddScrollViewDelegate: @escaping (UIScrollViewDelegate) -> Void,
        onRemoveScrollViewDelegate: @escaping (UIScrollViewDelegate) -> Void,
        @ViewBuilder content: @escaping ContentBuilder
    ) {
        _viewModel = StateObject(wrappedValue: TangemElasticContainerModel(
            onAddScrollViewDelegate: onAddScrollViewDelegate,
            onRemoveScrollViewDelegate: onRemoveScrollViewDelegate
        ))
        self.content = content
    }

    public var body: some View {
        ScrollViewReader { scrollProxy in
            bodyContent
                .readGeometry { geometryInfo in
                    viewModel.onGeometry(frame: geometryInfo.frame)
                }
                .onReceive(viewModel.scrollToIdPublisher) { scrollToId in
                    withAnimation {
                        scrollProxy.scrollTo(scrollToId, anchor: .top)
                    }
                }
        }
        .preference(key: TangemElasticContainerStatePreference.self, value: viewModel.state)
    }
}

// MARK: - Subviews

private extension TangemElasticContainer {
    var bodyContent: some View {
        VStack(spacing: 0) {
            anchor(id: viewModel.topAnchorId)

            content(viewModel.state.ratio)
                .padding(.top, viewModel.topPadding)

            anchor(id: viewModel.bottomAnchorId)
        }
    }

    func anchor(id: AnyHashable) -> some View {
        Color.clear
            .frame(height: 0)
            .id(id)
    }
}
