//
//  View+ReadContentOffset.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

extension View {
    /// 1. Assign stable coordinate space to the scroll view itself.
    /// 2. Use this modifier on the container view (e.g. `VStack` or `HStack`) that is used inside the scroll view.
    ///
    /// ```
    /// struct SomeView: View {
    ///     private let name = UUID()
    ///     [REDACTED_USERNAME] private var contentOffset: CGPoint = .zero
    ///
    ///     func body(content: Content) -> some View {
    ///         ScrollView {
    ///             LazyVStack() {
    ///                 // Some scrollable content
    ///             }
    ///             .readContentOffset(inCoordinateSpace: .named(name), bindTo: $contentOffset)
    ///         }
    ///         .coordinateSpace(name: name)
    ///     }
    /// }
    /// ```
    func readContentOffset(
        inCoordinateSpace coordinateSpace: CoordinateSpace,
        bindTo contentOffsetBinding: Binding<CGPoint>
    ) -> some View {
        modifier(
            ContentOffsetReaderViewModifier(
                contentOffsetBinding: contentOffsetBinding,
                coordinateSpace: coordinateSpace
            )
        )
    }
}

// MARK: - Private implementation

private struct ContentOffsetReaderViewModifier: ViewModifier {
    let contentOffsetBinding: Binding<CGPoint>
    let coordinateSpace: CoordinateSpace

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: ContentOffsetReaderPreferenceKey.self,
                        value: proxy.frame(in: coordinateSpace).origin
                    )
                }
            )
            .onPreferenceChange(ContentOffsetReaderPreferenceKey.self) { value in
                contentOffsetBinding.wrappedValue = CGPoint(
                    x: -value.x,
                    y: -value.y
                )
            }
    }
}

private struct ContentOffsetReaderPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint { .zero }

    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {}
}
