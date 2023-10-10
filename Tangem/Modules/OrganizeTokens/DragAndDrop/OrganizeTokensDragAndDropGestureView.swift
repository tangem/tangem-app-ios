//
//  OrganizeTokensDragAndDropGestureView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

struct OrganizeTokensDragAndDropGestureView: UIViewRepresentable {
    typealias OnLongPressChanged = (_ isRecognized: Bool) -> Void
    typealias OnDragChanged = (_ translation: CGSize) -> Void
    typealias OnEnded = () -> Void

    var minimumPressDuration: TimeInterval = 0.5 // Same default value as `UILongPressGestureRecognizer` has
    var allowableMovement: CGFloat = 10.0 /// Same default value as `UILongPressGestureRecognizer` has
    var onLongPressChanged: OnLongPressChanged?
    var onDragChanged: OnDragChanged?
    var onEnded: OnEnded?

    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator()
        coordinator.onLongPressChanged = onLongPressChanged
        coordinator.onDragChanged = onDragChanged
        coordinator.onEnded = onEnded

        return coordinator
    }

    func makeUIView(context: Context) -> UIView {
        let coordinator = context.coordinator

        let gestureRecognizer = UILongPressGestureRecognizer(
            target: coordinator,
            action: #selector(Coordinator.longPressGestureHandler(_:))
        )
        gestureRecognizer.minimumPressDuration = minimumPressDuration
        gestureRecognizer.allowableMovement = allowableMovement
        gestureRecognizer.delegate = coordinator
        coordinator.gestureRecognizer = gestureRecognizer

        let uiView = UIView()
        uiView.addGestureRecognizer(gestureRecognizer)

        return uiView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        let coordinator = context.coordinator

        coordinator.onLongPressChanged = onLongPressChanged
        coordinator.onDragChanged = onDragChanged
        coordinator.onEnded = onEnded

        coordinator.gestureRecognizer?.minimumPressDuration = minimumPressDuration
        coordinator.gestureRecognizer?.allowableMovement = allowableMovement
    }
}

// MARK: - Coordinator

extension OrganizeTokensDragAndDropGestureView {
    final class Coordinator: NSObject {
        fileprivate var onLongPressChanged: OnLongPressChanged?
        fileprivate var onDragChanged: OnDragChanged?
        fileprivate var onEnded: OnEnded?
        fileprivate weak var gestureRecognizer: UILongPressGestureRecognizer?

        private var startLocation: CGPoint = .zero

        @objc
        fileprivate func longPressGestureHandler(_ gestureRecognizer: UILongPressGestureRecognizer) {
            switch gestureRecognizer.state {
            case .began:
                startLocation = gestureRecognizer.location(in: nil)
                onLongPressChanged?(true)
            case .changed:
                let currentLocation = gestureRecognizer.location(in: nil)
                let translation = CGSize(
                    width: currentLocation.x - startLocation.x,
                    height: currentLocation.y - startLocation.y
                )
                onDragChanged?(translation)
            case .ended:
                onEnded?()
            case .cancelled, .possible, .failed:
                break
            @unknown default:
                assertionFailure("Unknown state received \(gestureRecognizer.state)")
            }
        }
    }
}

// MARK: - UIGestureRecognizerDelegate protocol conformance

extension OrganizeTokensDragAndDropGestureView.Coordinator: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        onLongPressChanged?(false)

        return true
    }
}
