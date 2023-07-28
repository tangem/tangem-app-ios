//
//  ClearDragGestureView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

public struct ClearDragGestureView: UIViewRepresentable {
    public let onChanged: (ClearDragGestureView.Value) -> Void
    public let onEnded: (ClearDragGestureView.Value) -> Void

    /// This API is meant to mirror DragGesture,.Value as that has no accessible initializers
    public struct Value {
        /// The time associated with the current event.
        public let time: Date

        /// The location of the current event.
        public let location: CGPoint

        /// The location of the first event.
        public let startLocation: CGPoint

        public let velocity: CGPoint

        /// The total translation from the first event to the current
        /// event. Equivalent to `location.{x,y} -
        /// startLocation.{x,y}`.
        public var translation: CGSize {
            return CGSize(width: location.x - startLocation.x, height: location.y - startLocation.y)
        }

        /// A prediction of where the final location would be if
        /// dragging stopped now, based on the current drag velocity.
        public var predictedEndLocation: CGPoint {
            let endTranslation = predictedEndTranslation
            return CGPoint(x: location.x + endTranslation.width, y: location.y + endTranslation.height)
        }

        public var predictedEndTranslation: CGSize {
            return CGSize(width: estimatedTranslation(fromVelocity: velocity.x), height: estimatedTranslation(fromVelocity: velocity.y))
        }

        private func estimatedTranslation(fromVelocity velocity: CGFloat) -> CGFloat {
            // This is a guess. I couldn't find any documentation anywhere on what this should be
            let acceleration: CGFloat = 500
            let timeToStop = velocity / acceleration
            return velocity * timeToStop / 2
        }
    }

    public class Coordinator: NSObject, UIGestureRecognizerDelegate {
        let onChanged: (ClearDragGestureView.Value) -> Void
        let onEnded: (ClearDragGestureView.Value) -> Void

        private var startLocation = CGPoint.zero

        init(onChanged: @escaping (ClearDragGestureView.Value) -> Void, onEnded: @escaping (ClearDragGestureView.Value) -> Void) {
            self.onChanged = onChanged
            self.onEnded = onEnded
        }

        public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }

        @objc
        func gestureRecognizerPanned(_ gesture: UIPanGestureRecognizer) {
            guard let view = getGlobalView() else {
                assertionFailure("Missing view on gesture")
                return
            }

            switch gesture.state {
            case .possible, .cancelled, .failed:
                break
            case .began:
                startLocation = gesture.location(in: view)
            case .changed:
                let value = ClearDragGestureView.Value(
                    time: Date(),
                    location: gesture.location(in: view),
                    startLocation: startLocation,
                    velocity: gesture.velocity(in: view)
                )
                onChanged(value)
            case .ended:
                let value = ClearDragGestureView.Value(
                    time: Date(),
                    location: gesture.location(in: view),
                    startLocation: startLocation,
                    velocity: gesture.velocity(in: view)
                )
                onEnded(value)
            @unknown default:
                break
            }
        }

        func getGlobalView() -> UIView? {
            //        getting the all scenes
            let scenes = UIApplication.shared.connectedScenes
            //        getting windowScene from scenes
            let windowScene = scenes.first as? UIWindowScene
            //        getting window from windowScene
            let window = windowScene?.windows.first
            //        getting the root view controller
            let rootVC = window?.rootViewController

            return rootVC?.view
        }
    }

    public func makeCoordinator() -> ClearDragGestureView.Coordinator {
        return Coordinator(onChanged: onChanged, onEnded: onEnded)
    }

    public func makeUIView(context: UIViewRepresentableContext<ClearDragGestureView>) -> UIView {
        let view = context.coordinator.getGlobalView()!
//        view.backgroundColor = .purple.withAlphaComponent(0.5)
//        view.isUserInteractionEnabled = true

        let drag = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.gestureRecognizerPanned))
        drag.delegate = context.coordinator
//        let tapGesture = UITapGestureRecognizer()
//        tapGesture.delegate = context.coordinator

//        view.addGestureRecognizer(tapGesture)
        view.addGestureRecognizer(drag)

        let view2 = UIView()
        view2.backgroundColor = .clear
        return view2
    }

    public func updateUIView(
        _ uiView: UIView,
        context: UIViewRepresentableContext<ClearDragGestureView>
    ) {}
}
