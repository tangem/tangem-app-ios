//
//  EnhanceScrollView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils

public struct EnhanceScrollView<Content: View>: View {
    private let axis: Axis
    private let showsIndicators: Bool
    private let content: () -> Content

    private let coordinateSpaceName = UUID()
    private var contentOffset: Binding<CGPoint>?

    public init(
        _ axis: Axis = .vertical,
        showsIndicators: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.axis = axis
        self.showsIndicators = showsIndicators
        self.content = content
    }

    public var body: some View {
        if #available(iOS 18.0, *) {
            scrollView
        } else {
            legacyScrollView
        }
    }

    @available(iOS 18.0, *)
    var scrollView: some View {
        ScrollView(.vertical) {
            content()
        }
        .scrollIndicators(showsIndicators ? .automatic : .hidden)
        .ifLet(contentOffset) { scrollView, contentOffset in
            scrollView.onScrollGeometryChange(for: ScrollGeometry.self, of: \.self) { _, newValue in
                let yOffset = newValue.contentOffset.y + newValue.contentInsets.top

                contentOffset.wrappedValue = .init(x: newValue.contentOffset.x, y: yOffset)
            }
        }
    }

    var legacyScrollView: some View {
        ScrollView(.vertical, showsIndicators: showsIndicators) {
            content()
                .ifLet(contentOffset) { scrollView, contentOffset in
                    scrollView.readContentOffset(
                        inCoordinateSpace: .named(coordinateSpaceName),
                        bindTo: contentOffset
                    )
                }
        }
        .coordinateSpace(name: coordinateSpaceName)
    }
}

// MARK: - Setupable

extension EnhanceScrollView: Setupable {
    public func readContentOffset(contentOffset: Binding<CGPoint>) -> Self {
        map { $0.contentOffset = contentOffset }
    }
}
