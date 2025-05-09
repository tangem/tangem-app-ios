//
//  PassThroughWindow.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import UIKit

public final class PassThroughWindow: UIWindow {
    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let superHitTestView = super.hitTest(point, with: event)
        let hitTestView: UIView?

        if #available(iOS 18, *) {
            hitTestView = _defaultHitTest(point, event: event)
        } else {
            hitTestView = superHitTestView
        }

        // [REDACTED_USERNAME], if hitTestView is rootViewController.view, it means that no SwiftUI.View responded to touch.
        let noSwiftUIViewRespondedToTouchEvent = hitTestView == rootViewController?.view

        // for such a case we want to pass the touch event down to application main window, by returning nil here.
        return noSwiftUIViewRespondedToTouchEvent ? nil : superHitTestView
    }
}

private extension UIView {
    func _defaultHitTest(_ point: CGPoint, event: UIEvent?) -> UIView? {
        guard
            isUserInteractionEnabled,
            !isHidden,
            alpha >= 0.01,
            self.point(inside: point, with: event)
        else {
            return nil
        }

        for subview in subviews.reversed() {
            let convertedPoint = subview.convert(point, from: self)

            if let hitView = subview._defaultHitTest(convertedPoint, event: event) {
                return hitView
            }
        }

        return self
    }
}
