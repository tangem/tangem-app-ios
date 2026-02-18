//
//  View+Touches.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import UIKit

/// A handler that receives touch events from the underlying UIView.
public typealias ViewTouchesHandler = (_ uiView: UIView?, _ touches: Set<UITouch>, _ event: UIEvent?) -> Void

public extension View {
    /// Attaches touch event handlers to the view using an underlying UIKit view.
    ///
    /// This method allows you to observe low-level UIKit touch events
    /// (`began`, `moved`, `ended`, `cancelled`) from a SwiftUI view.
    ///
    /// - Parameters:
    ///   - isMultipleTouchEnabled: A Boolean value that determines whether the view can receive multiple touches simultaneously.
    ///   - began: A closure called when touches begin.
    ///   - moved: A closure called when touches move.
    ///   - ended: A closure called when touches end.
    ///   - cancelled: A closure called when touches are cancelled.
    /// - Returns: A view that overlays a touch-tracking UIView.
    func onTouches(
        isMultipleTouchEnabled: Bool = true,
        began: ViewTouchesHandler? = nil,
        moved: ViewTouchesHandler? = nil,
        ended: ViewTouchesHandler? = nil,
        cancelled: ViewTouchesHandler? = nil
    ) -> some View {
        overlay(
            TouchTrackableView(
                isMultipleTouchEnabled: isMultipleTouchEnabled,
                onTouchesBegan: began,
                onTouchesMoved: moved,
                onTouchesEnded: ended,
                onTouchesCancelled: cancelled
            )
        )
    }

    /// Attaches a single handler that is invoked for all touch phases.
    ///
    /// This is a convenience overload when the same logic should handle
    /// all touch events (`began`, `moved`, `ended`, `cancelled`).
    ///
    /// - Parameters:
    ///   - isMultipleTouchEnabled: A Boolean value that determines whether the view can receive multiple touches simultaneously.
    ///   - handler: A closure invoked for every touch event.
    /// - Returns: A view that overlays a touch-tracking UIView.
    func onTouches(
        isMultipleTouchEnabled: Bool = true,
        perform handler: @escaping ViewTouchesHandler
    ) -> some View {
        onTouches(
            isMultipleTouchEnabled: isMultipleTouchEnabled,
            began: handler,
            moved: handler,
            ended: handler,
            cancelled: handler
        )
    }
}

/// A SwiftUI wrapper that hosts a UIKit view capable of tracking touch events.
struct TouchTrackableView: UIViewRepresentable {
    let isMultipleTouchEnabled: Bool
    let onTouchesBegan: ViewTouchesHandler?
    let onTouchesMoved: ViewTouchesHandler?
    let onTouchesEnded: ViewTouchesHandler?
    let onTouchesCancelled: ViewTouchesHandler?

    /// Creates and configures the underlying UIKit view.
    func makeUIView(context: Context) -> UIView {
        let view = TouchTrackableUIView()
        view.isMultipleTouchEnabled = isMultipleTouchEnabled
        view.onTouchesBegan = onTouchesBegan
        view.onTouchesMoved = onTouchesMoved
        view.onTouchesEnded = onTouchesEnded
        view.onTouchesCancelled = onTouchesCancelled
        return view
    }

    /// Updates the UIKit view when SwiftUI state changes.
    ///
    /// Currently no-op because the view does not depend on dynamic state updates.
    func updateUIView(_ uiView: UIView, context: Context) {}
}

/// A UIKit view that forwards touch events via closures.
private class TouchTrackableUIView: UIView {
    var onTouchesBegan: ViewTouchesHandler?
    var onTouchesMoved: ViewTouchesHandler?
    var onTouchesEnded: ViewTouchesHandler?
    var onTouchesCancelled: ViewTouchesHandler?

    /// Called when one or more fingers touch down in the view.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        onTouchesBegan?(self, touches, event)
    }

    /// Called when one or more fingers move within the view.
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        onTouchesMoved?(self, touches, event)
    }

    /// Called when one or more fingers are lifted from the view.
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        onTouchesEnded?(self, touches, event)
    }

    /// Called when the system cancels tracking of touches (e.g. due to interruption).
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        onTouchesCancelled?(self, touches, event)
    }
}
