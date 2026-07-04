//
//  OnWindowAttachView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import UIKit

/// A marker view that reports each time it enters a window — the point at which it is guaranteed to be
/// in the live hierarchy, so `onAttachToWindow` can safely walk the superview chain. Fires again on
/// every re-attach; callers must be idempotent.
public final class OnWindowAttachView: UIView {
    public var onAttachToWindow: ((UIView) -> Void)?

    override public func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else { return }
        onAttachToWindow?(self)
    }
}
