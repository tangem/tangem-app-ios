//
//  View+ReadGeometry.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct GeometryInfo: Equatable {
    static var zero: Self {
        .init(
            coordinateSpace: .global,
            frame: .zero,
            size: .zero,
            safeAreaInsets: .init()
        )
    }

    let coordinateSpace: CoordinateSpace
    let frame: CGRect
    let size: CGSize
    let safeAreaInsets: EdgeInsets
}

extension View {
    /// Closure-based helper. Use optional parameter `transform` if needed.
    func readGeometry<T>(
        inCoordinateSpace coordinateSpace: CoordinateSpace = .global,
        transform: KeyPath<GeometryInfo, T> = \.self,
        onChange: @escaping (_ value: T) -> Void
    ) -> some View {
        modifier(
            GeometryInfoReaderViewModifier(coordinateSpace: coordinateSpace) { geometryInfo in
                onChange(geometryInfo[keyPath: transform])
            }
        )
    }

    /// Binding-based helper. Use optional parameter `transform` if needed.
    ///
    /// ```swift
    /// struct SomeView: View {
    ///     [REDACTED_USERNAME] private var frameMidX: CGFloat = .zero
    ///
    ///     var body: some View {
    ///         VStack() {
    ///             // Some content
    ///         }
    ///         .readGeometry(to: $frameMidX, transform: \.frame.midX)
    ///     }
    /// }
    /// ```
    func readGeometry<T>(
        inCoordinateSpace coordinateSpace: CoordinateSpace = .global,
        to contentOffsetBinding: Binding<T>,
        transform: KeyPath<GeometryInfo, T> = \.self
    ) -> some View {
        readGeometry(inCoordinateSpace: coordinateSpace, transform: transform) { value in
            contentOffsetBinding.wrappedValue = value
        }
    }
}

// MARK: - Private implementation

private struct GeometryInfoReaderViewModifier: ViewModifier {
    let coordinateSpace: CoordinateSpace
    let onChange: (_ contentOffset: GeometryInfo) -> Void

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometryProxy in
                    let geometryInfo = GeometryInfo(
                        coordinateSpace: coordinateSpace,
                        frame: geometryProxy.frame(in: coordinateSpace),
                        size: geometryProxy.size,
                        safeAreaInsets: geometryProxy.safeAreaInsets
                    )
                    Color.clear
                        .preference(key: GeometryInfoReaderPreferenceKey.self, value: geometryInfo)
                }
            )
            .onPreferenceChange(GeometryInfoReaderPreferenceKey.self, perform: onChange)
    }
}

private struct GeometryInfoReaderPreferenceKey: PreferenceKey {
    static var defaultValue: GeometryInfo { .zero }

    static func reduce(value: inout GeometryInfo, nextValue: () -> GeometryInfo) {}
}
