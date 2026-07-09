//
//  GeometryInfoReaderViewModifier.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

// MARK: - Convenience extensions

public extension View {
    /// Closure-based helper that observes the whole `GeometryInfo`.
    func readGeometry(
        inCoordinateSpace coordinateSpace: CoordinateSpace = .local,
        throttleInterval: GeometryInfo.ThrottleInterval = .zero,
        file: StaticString = #fileID,
        line: UInt = #line,
        onChange: @escaping (_ value: GeometryInfo) -> Void
    ) -> some View {
        readGeometry(
            \.self,
            inCoordinateSpace: coordinateSpace,
            throttleInterval: throttleInterval,
            file: file,
            line: line,
            onChange: onChange
        )
    }

    /// Closure-based helper. Pass a `keyPath` to observe a single property of `GeometryInfo`.
    func readGeometry<T>(
        _ keyPath: KeyPath<GeometryInfo, T>,
        inCoordinateSpace coordinateSpace: CoordinateSpace = .local,
        throttleInterval: GeometryInfo.ThrottleInterval = .zero,
        file: StaticString = #fileID,
        line: UInt = #line,
        onChange: @escaping (_ value: T) -> Void
    ) -> some View {
        modifier(
            GeometryInfoReaderViewModifier(
                coordinateSpace: coordinateSpace,
                throttleInterval: throttleInterval,
                file: file,
                line: line
            ) { geometryInfo in
                onChange(geometryInfo[keyPath: keyPath])
            }
        )
    }

    /// Binding-based helper that observes the whole `GeometryInfo`.
    func readGeometry(
        inCoordinateSpace coordinateSpace: CoordinateSpace = .local,
        throttleInterval: GeometryInfo.ThrottleInterval = .zero,
        file: StaticString = #fileID,
        line: UInt = #line,
        bindTo value: Binding<GeometryInfo>
    ) -> some View {
        readGeometry(
            \.self,
            inCoordinateSpace: coordinateSpace,
            throttleInterval: throttleInterval,
            file: file,
            line: line,
            bindTo: value
        )
    }

    /// Binding-based helper. Pass a `keyPath` to observe a single property of `GeometryInfo`.
    ///
    /// ```swift
    /// struct SomeView: View {
    ///     [REDACTED_USERNAME] private var frameMidX: CGFloat = .zero
    ///
    ///     var body: some View {
    ///         VStack() {
    ///             // Some content
    ///         }
    ///         .readGeometry(\.frame.midX, bindTo: $frameMidX)
    ///     }
    /// }
    /// ```
    func readGeometry<T>(
        _ keyPath: KeyPath<GeometryInfo, T>,
        inCoordinateSpace coordinateSpace: CoordinateSpace = .local,
        throttleInterval: GeometryInfo.ThrottleInterval = .zero,
        file: StaticString = #fileID,
        line: UInt = #line,
        bindTo value: Binding<T>
    ) -> some View {
        readGeometry(
            keyPath,
            inCoordinateSpace: coordinateSpace,
            throttleInterval: throttleInterval,
            file: file,
            line: line
        ) { newValue in
            value.wrappedValue = newValue
        }
    }
}

// MARK: - Auxiliary types

public struct GeometryInfo: Equatable {
    public static var zero: Self {
        return GeometryInfo(
            coordinateSpace: .local,
            frame: .zero,
            size: .zero,
            safeAreaInsets: .init()
        )
    }

    public let coordinateSpace: CoordinateSpace
    public let frame: CGRect
    public let size: CGSize
    public let safeAreaInsets: EdgeInsets

    fileprivate init(
        coordinateSpace: CoordinateSpace,
        frame: CGRect,
        size: CGSize,
        safeAreaInsets: EdgeInsets
    ) {
        self.coordinateSpace = coordinateSpace
        self.frame = frame
        self.size = size
        self.safeAreaInsets = safeAreaInsets
    }
}

public extension GeometryInfo {
    struct ThrottleInterval: ExpressibleByFloatLiteral {
        /// No throttling at all.
        public static let zero = ThrottleInterval(0.0)
        /// Aggressive throttling, use for non-precision tasks.
        public static let aggressive = ThrottleInterval(1.0 / 30.0)
        /// Standard 60 FPS (single frame duration: ~16msec).
        public static let standard = ThrottleInterval(1.0 / 60.0)
        /// 120 FPS on ProMotion capable devices (single frame duration: ~8msec).
        public static let proMotion = ThrottleInterval(1.0 / 120.0)

        fileprivate let value: CFTimeInterval

        public init(_ value: CFTimeInterval) {
            self.value = value
        }

        public init(floatLiteral value: CFTimeInterval) {
            self.value = value
        }
    }
}

// MARK: - Private implementation

private struct GeometryInfoReaderViewModifier: ViewModifier {
    let coordinateSpace: CoordinateSpace
    let throttleInterval: GeometryInfo.ThrottleInterval
    let file: StaticString
    let line: UInt
    let onChange: (_ geometryInfo: GeometryInfo) -> Void

    #if DEBUG
    @State private var loopDetector = GeometryFeedbackLoopDetector()
    #endif

    init(
        coordinateSpace: CoordinateSpace,
        throttleInterval: GeometryInfo.ThrottleInterval,
        file: StaticString,
        line: UInt,
        onChange: @escaping (_ geometryInfo: GeometryInfo) -> Void
    ) {
        self.coordinateSpace = coordinateSpace
        self.throttleInterval = throttleInterval
        self.file = file
        self.line = line
        self.onChange = onChange
    }

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
                    let container = TimeStampContainer(
                        timeStamp: CACurrentMediaTime(),
                        throttleInterval: throttleInterval.value,
                        geometryInfo: geometryInfo
                    )
                    Color.clear
                        .preference(key: GeometryInfoReaderPreferenceKey.self, value: container)
                }
            )
            .onPreferenceChange(GeometryInfoReaderPreferenceKey.self) { newValue in
                #if DEBUG
                loopDetector.recordUpdate(file: file, line: line)
                #endif
                onChange(newValue.geometryInfo)
            }
    }
}

#if DEBUG
/// Trips when a single `readGeometry` instance updates far faster than any real scroll or animation
/// can drive it — the signature of a geometry → state → layout feedback loop ([REDACTED_INFO]).
///
/// A class on purpose: lives in `@State` so recording updates doesn't invalidate the observed view.
private final class GeometryFeedbackLoopDetector {
    private var windowStart: CFTimeInterval = .zero
    private var updatesInWindow = 0
    private var didReport = false

    func recordUpdate(file: StaticString, line: UInt) {
        guard !didReport else { return }

        let now = CACurrentMediaTime()
        if now - windowStart > Constants.window {
            windowStart = now
            updatesInWindow = 0
        }

        updatesInWindow += 1
        if updatesInWindow >= Constants.updatesThreshold {
            didReport = true
            assertionFailure(
                "readGeometry at \(file):\(line) fired \(updatesInWindow) times in \(Constants.window)s. "
                    + "The measured geometry is most likely written into state that changes the measured layout. "
                    + "Round the written value via roundedToDeviceScale() or break the feedback (see [REDACTED_INFO])."
            )
        }
    }

    private enum Constants {
        /// 120 Hz scrolling drives at most ~30 updates per window; a feedback loop produces hundreds.
        static let window: CFTimeInterval = 0.25
        static let updatesThreshold = 120
    }
}
#endif // DEBUG

// MARK: - Auxiliary types

private struct GeometryInfoReaderPreferenceKey: PreferenceKey {
    typealias Value = TimeStampContainer

    static var defaultValue: Value {
        return Value(timeStamp: .zero, throttleInterval: .zero, geometryInfo: .zero)
    }

    static func reduce(value: inout Value, nextValue: () -> Value) {}
}

private struct TimeStampContainer: Equatable {
    let timeStamp: CFTimeInterval
    let throttleInterval: CFTimeInterval
    let geometryInfo: GeometryInfo

    static func == (lhs: Self, rhs: Self) -> Bool {
        if abs(lhs.timeStamp - rhs.timeStamp) < rhs.throttleInterval {
            return true
        }

        return lhs.geometryInfo == rhs.geometryInfo
    }
}
