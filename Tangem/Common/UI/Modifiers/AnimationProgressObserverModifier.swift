//
//  AnimationProgressObserverModifier.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

/// An animatable modifier that is used for observing animations for a given animatable value.
struct AnimationProgressObserverModifier<Value>: AnimatableModifier where Value: VectorArithmetic {
    typealias ValueComparator = (_ lhs: Value, _ rhs: Value) -> Bool

    /// While animating, SwiftUI changes the old input value to the new target value using this property.
    var animatableData: Value {
        didSet { notifyIfNeeded() }
    }

    /// The target value for which we're observing. This value is directly set once the animation starts.
    private let targetValue: Value

    /// Called when `valueComparator` returns `true` comparing `observedValue` and `targetValue`.
    private let action: () -> Void

    /// Used to compare `observedValue` (current value of an animatable property) and
    /// `targetValue` (final value of an animatable property).
    private let valueComparator: ValueComparator

    init(
        observedValue: Value,
        targetValue: Value? = nil,
        valueComparator: @escaping ValueComparator = (==),
        action: @escaping () -> Void
    ) {
        animatableData = observedValue
        self.targetValue = targetValue ?? observedValue
        self.valueComparator = valueComparator
        self.action = action
    }

    /// Compares the current animation and target values using value comparator and calls the action callback if comparator return `true`.
    private func notifyIfNeeded() {
        guard valueComparator(animatableData, targetValue) else { return }

        /// Dispatching is needed to take the next runloop for the action callback.
        /// This prevents errors like "Modifying state during view update, this will cause undefined behavior."
        DispatchQueue.main.async {
            action()
        }
    }

    func body(content: Content) -> some View {
        /// We're not really modifying the view so we can directly return the original input value.
        return content
    }
}

// MARK: - Convenience extensions

extension View {
    /// Calls the completion handler whenever an animation on the given value completes.
    /// - Parameters:
    ///   - value: The value to observe for animations.
    ///   - completion: The completion callback to call once the animation completes.
    /// - Returns: A modified `View` instance with the observer attached.
    @ViewBuilder
    func onAnimationCompleted<Value: VectorArithmetic>(
        for value: Value,
        completion: @escaping () -> Void
    ) -> some View {
        modifier(AnimationProgressObserverModifier(observedValue: value, action: completion))
    }

    @ViewBuilder
    func onAnimationCompleted<Value: VectorArithmetic>(
        forOptional value: Value?,
        completion: @escaping () -> Void
    ) -> some View {
        if let value = value {
            onAnimationCompleted(for: value, completion: completion)
        } else {
            self
        }
    }

    @ViewBuilder
    func onAnimationCompleted(
        for value: Bool,
        completion: @escaping () -> Void
    ) -> some View {
        let value = VectorArithmeticBox(wrapped: value ? 1.0 : 0.0)
        modifier(AnimationProgressObserverModifier(observedValue: value, action: completion))
    }
}

// MARK: - Private implementation

/// Some animatable types, like `Bool` for example, don't conform to the `VectorArithmetic` protocol
/// and therefore can't be used with the `.onAnimationCompleted` helper.
/// This wrapper helps to overcome this issue.
struct VectorArithmeticBox<T>: VectorArithmetic where T: VectorArithmetic {
    static var zero: Self { Self(wrapped: T.zero) }

    var wrapped: T

    var magnitudeSquared: Double { wrapped.magnitudeSquared }

    static func - (lhs: Self, rhs: Self) -> Self {
        return Self(wrapped: lhs.wrapped - rhs.wrapped)
    }

    static func + (lhs: Self, rhs: Self) -> Self {
        return Self(wrapped: lhs.wrapped + rhs.wrapped)
    }

    mutating func scale(by rhs: Double) {
        wrapped.scale(by: rhs)
    }
}
