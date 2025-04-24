//
//  View+ReadContentOffset.swift
//  TangemUIUtils
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils

public extension View {
    /// 1. Assign stable coordinate space to the scroll view itself.
    /// 2. Use this modifier on the container view (e.g. `VStack` or `HStack`) that is used inside the scroll view.
    ///
    /// ```
    /// struct SomeView: View {
    ///     private let name = UUID()
    ///     [REDACTED_USERNAME] private var contentOffset: CGPoint = .zero
    ///
    ///     var body: some View {
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
        throttleInterval: GeometryInfo.ThrottleInterval = .zero,
        bindTo contentOffset: Binding<CGPoint>
    ) -> some View {
        modifier(
            ContentOffsetReaderViewModifier(
                coordinateSpace: coordinateSpace,
                throttleInterval: throttleInterval
            ) { contentOffset.wrappedValue = $0 }
        )
    }

    func readContentOffset(
        inCoordinateSpace coordinateSpace: CoordinateSpace,
        throttleInterval: GeometryInfo.ThrottleInterval = .standard,
        onChange: @escaping (_ value: CGPoint) -> Void
    ) -> some View {
        modifier(
            ContentOffsetReaderViewModifier(
                coordinateSpace: coordinateSpace,
                throttleInterval: throttleInterval,
                onChange: onChange
            )
        )
    }
}

// MARK: - Private implementation

private struct ContentOffsetReaderViewModifier: ViewModifier {
    let coordinateSpace: CoordinateSpace
    let throttleInterval: GeometryInfo.ThrottleInterval
    let onChange: (_ geometryInfo: CGPoint) -> Void

    func body(content: Content) -> some View {
        content
            .readGeometry(
                \.frame.origin,
                inCoordinateSpace: coordinateSpace,
                throttleInterval: throttleInterval
            ) { onChange(CGPoint(x: -$0.x, y: -$0.y)) }
    }
}
