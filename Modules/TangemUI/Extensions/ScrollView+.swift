//
//  ScrollView+.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    /// Backports ``View.scrollDisabled(_:)``.
    /// - Attention: No-op for iOS 15.
    /// - Parameter isDisabled: A Boolean that indicates whether scrolling is disabled.
    @available(iOS, obsoleted: 16.0, message: "Use native View.scrollDisabled(_:) instead.")
    @ViewBuilder
    func scrollDisabledBackport(_ isDisabled: Bool) -> some View {
        if #available(iOS 16.0, *) {
            scrollDisabled(isDisabled)
        } else {
            self
        }
    }

    /// Backports ``View.scrollBounceBehavior(_:axes:)``.
    /// - Attention: No-op for iOS < 16.4.
    /// - Parameters:
    ///   - behavior: The bounce behavior to apply to any scrollable views
    ///     within the configured view. Use one of the ``ScrollBounceBehavior``
    ///     values.
    ///   - axes: The set of axes to apply `behavior` to. The default is
    ///     ``Axis/vertical``.
    ///
    /// - Returns: A view that's configured with the specified scroll bounce
    ///   behavior.
    @available(iOS, obsoleted: 16.4, message: "Use native View.scrollBounceBehavior(_:axes:) instead.")
    @ViewBuilder
    func scrollBounceBehaviorBackport(_ behavior: ScrollBounceBehaviorBackport) -> some View {
        if #available(iOS 16.4, *) {
            self.scrollBounceBehavior(behavior.toNativeBounceBehavior)
        } else {
            self
        }
    }
}

@available(iOS, obsoleted: 16.4, message: "Use native ScrollBounceBehavior instead.")
public enum ScrollBounceBehaviorBackport {
    /// The automatic behavior.
    ///
    /// The scrollable view automatically chooses whether content bounces when
    /// people scroll to the end of the view's content. By default, scrollable
    /// views use the ``ScrollBounceBehavior/always`` behavior.
    case automatic

    /// The scrollable view always bounces.
    ///
    /// The scrollable view always bounces along the specified axis,
    /// regardless of the size of the content.
    case always

    /// The scrollable view bounces when its content is large enough to require
    /// scrolling.
    ///
    /// The scrollable view bounces along the specified axis if the size of
    /// the content exceeds the size of the scrollable view in that axis.
    case basedOnSize

    @available(iOS 16.4, *)
    var toNativeBounceBehavior: ScrollBounceBehavior {
        switch self {
        case .automatic: .automatic
        case .always: .always
        case .basedOnSize: .basedOnSize
        }
    }
}
