//
//  ShapeBuilder.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

// MARK: - ShapeBuilder

/// A result builder that enables conditional shape composition with type erasure.
///
/// `ShapeBuilder` allows you to use `if/else` and `switch` statements to return
/// different `InsettableShape` types from a single computed property or closure,
/// which is not normally possible due to Swift's type system.
///
/// ## Usage
///
/// ### As a computed property:
/// ```swift
/// [REDACTED_USERNAME]
/// private var myShape: AnyInsettableShape {
///     switch style {
///     case .rounded:
///         Capsule()
///     case .rectangular:
///         RoundedRectangle(cornerRadius: 8)
///     case .sharp:
///         Rectangle()
///     }
/// }
/// ```
///
/// ### With View extensions:
/// ```swift
/// var body: some View {
///     content
///         .background(color) { myShape }
///         .clipShape { myShape }
/// }
/// ```
///
/// ### Inline usage:
/// ```swift
/// .clipShape {
///     if isRounded {
///         Capsule()
///     } else {
///         RoundedRectangle(cornerRadius: 8)
///     }
/// }
/// ```
///
/// - Note: All shapes are type-erased to `AnyInsettableShape`.
/// - Note: Only `InsettableShape` conforming types are supported.
@resultBuilder
enum ShapeBuilder {
    static func buildExpression<S: InsettableShape>(_ shape: S) -> AnyInsettableShape {
        AnyInsettableShape(shape)
    }

    static func buildBlock(_ shape: AnyInsettableShape) -> AnyInsettableShape { shape }
    static func buildEither(first: AnyInsettableShape) -> AnyInsettableShape { first }
    static func buildEither(second: AnyInsettableShape) -> AnyInsettableShape { second }
}

// MARK: - AnyInsettableShape

/// A type-erased wrapper for any `InsettableShape`.
///
/// Use this type when you need to store or return shapes of different concrete types.
/// Created automatically by `@ShapeBuilder`.
struct AnyInsettableShape: InsettableShape {
    private let pathClosure: @Sendable (CGRect) -> Path
    private let insetClosure: @Sendable (CGFloat) -> AnyInsettableShape

    init<S: InsettableShape>(_ shape: S) {
        pathClosure = { rect in shape.path(in: rect) }
        insetClosure = { amount in AnyInsettableShape(shape.inset(by: amount)) }
    }

    func path(in rect: CGRect) -> Path { pathClosure(rect) }
    func inset(by amount: CGFloat) -> AnyInsettableShape { insetClosure(amount) }
}

// MARK: - View Extensions

extension View {
    /// Clips this view to a shape built using `@ShapeBuilder`.
    ///
    /// ```swift
    /// content.clipShape {
    ///     if isRounded {
    ///         Capsule()
    ///     } else {
    ///         RoundedRectangle(cornerRadius: 8)
    ///     }
    /// }
    /// ```
    func clipShape(@ShapeBuilder _ shape: () -> AnyInsettableShape) -> some View {
        clipShape(shape())
    }

    /// Sets the background with a color and shape built using `@ShapeBuilder`.
    ///
    /// ```swift
    /// content.background(.blue) {
    ///     if isRounded {
    ///         Capsule()
    ///     } else {
    ///         RoundedRectangle(cornerRadius: 8)
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - color: The background color. Pass `nil` for transparent.
    ///   - shape: A `@ShapeBuilder` closure returning the background shape.
    func background(_ color: Color?, @ShapeBuilder in shape: () -> AnyInsettableShape) -> some View {
        background(color ?? .clear, in: shape())
    }
}
