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
///
/// ## Behavior
/// - Fully expanded state corresponds to `ratio == 1`
/// - Fully collapsed state corresponds to `ratio == 0`
/// - During interaction the container applies:
///   - **resistance** while collapsing (rubber-band effect)
///   - **hugging** while expanding (soft snap-back effect)
/// - When scrolling ends, the container automatically snaps
///   to the nearest stable state (expanded or collapsed)
///
/// ## Layout
/// Internally, the container uses invisible top and bottom anchors together
/// with `ScrollViewReader` to perform snapping animations.
///
/// ## Content
/// The provided content builder receives the current expansion ratio:
///
/// ```swift
/// TangemElasticContainer { ratio in
///     HeaderView(expandRatio: ratio)
/// }
/// ```
///
/// ## Integration
/// The container does not own a `ScrollView` directly.
/// Instead, it attaches itself as a `UIScrollViewDelegate`,
/// making it compatible with:
/// - SwiftUI `ScrollView`
/// - UIKit `UIScrollView`
/// - hybrid UIKit / SwiftUI layouts
///
/// This design allows the container to remain fully decoupled
/// from the scroll view implementation.
///
/// - Note: The expansion ratio is guaranteed to stay within `0...1`.
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
