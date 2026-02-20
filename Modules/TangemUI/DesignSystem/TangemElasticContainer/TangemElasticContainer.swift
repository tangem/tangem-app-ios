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
    @StateObject private var viewModel: TangemElasticContainerModel

    private let content: (TangemElasticContainerState) -> Content

    public init(
        onAddScrollViewDelegate: @escaping (UIScrollViewDelegate) -> Void,
        onRemoveScrollViewDelegate: @escaping (UIScrollViewDelegate) -> Void,
        @ViewBuilder content: @escaping (TangemElasticContainerState) -> Content
    ) {
        _viewModel = StateObject(wrappedValue: TangemElasticContainerModel(
            onAddScrollViewDelegate: onAddScrollViewDelegate,
            onRemoveScrollViewDelegate: onRemoveScrollViewDelegate
        ))
        self.content = content
    }

    public var body: some View {
        ScrollViewReader { proxy in
            bodyContent
                .readGeometry { geometryInfo in
                    viewModel.onGeometry(frame: geometryInfo.frame)
                }
                .onReceive(viewModel.scrollToIdPublisher) { scrollToId in
                    withAnimation {
                        proxy.scrollTo(scrollToId, anchor: .top)
                    }
                }
        }
    }
}

// MARK: - Subviews

private extension TangemElasticContainer {
    var bodyContent: some View {
        VStack(spacing: 0) {
            anchor(id: viewModel.topAnchorId)

            content(viewModel.state)
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
