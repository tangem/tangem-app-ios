//
//  View+ConditionalModifiers.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    /// Applies a modifier to a view
    ///
    /// - Parameters:
    ///   - content: The modifier to apply to the view.
    /// - Returns: The modified view.
    func modifyView<T: View>(@ViewBuilder content: (Self) -> T) -> some View {
        content(self)
    }

    /// Applies a modifier to a view conditionally.
    ///
    /// - Parameters:
    ///   - ifLet: The optional value.
    ///   - content: The modifier to apply to the view in optionalValue is inwrapped.
    /// - Returns: The modified view.
    @ViewBuilder
    func modifier<Content: View, Value>(
        ifLet optionalValue: Value?,
        @ViewBuilder then content: (Self, Value) -> Content
    ) -> some View {
        if let optionalValue = optionalValue {
            content(self, optionalValue)
        } else {
            self
        }
    }

    /// Applies a modifier to a view conditionally.
    ///
    /// - Parameters:
    ///   - condition: The condition to determine if the content should be applied.
    ///   - transform: The modifier to apply to the view.
    /// - Returns: The modified view.
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Applies a modifier to a view conditionally.
    ///
    /// - Parameters:
    ///   - condition: The condition to determine the content to be applied.
    ///   - trueContent: The modifier to apply to the view if the condition passes.
    ///   - falseContent: The modifier to apply to the view if the condition fails.
    /// - Returns: The modified view.
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        then: (Self) -> TrueContent,
        else: (Self) -> FalseContent
    ) -> some View {
        if condition {
            then(self)
        } else {
            `else`(self)
        }
    }
}
