//
//  TangemElasticContainer.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

/// Container view that provides an elastic expand / collapse behavior
/// driven by a vertical `ScrollView`.
///
/// `TangemElasticContainer` observes the scroll offset of an external
/// `UIScrollView` and transforms it into a normalized expansion `ratio` (0...1),
/// allowing content to react smoothly to scroll-driven expansion and collapse.
public struct TangemElasticContainer<Content: View>: View {
    @StateObject private var viewModel: TangemElasticContainerModel

    private let content: Content

    public init(
        onAddScrollViewObserver: @escaping (RefreshScrollViewObserver) -> Void,
        onRemoveScrollViewObserver: @escaping (RefreshScrollViewObserver) -> Void,
        content: Content
    ) {
        _viewModel = StateObject(wrappedValue: TangemElasticContainerModel(
            onAddScrollViewObserver: onAddScrollViewObserver,
            onRemoveScrollViewObserver: onRemoveScrollViewObserver
        ))
        self.content = content
    }

    public var body: some View {
        content
            .readGeometry { geometryInfo in
                viewModel.onGeometry(frame: geometryInfo.frame)
            }
            .preference(key: TangemElasticContainerHeightRatio.self, value: viewModel.heightRatio)
    }
}
