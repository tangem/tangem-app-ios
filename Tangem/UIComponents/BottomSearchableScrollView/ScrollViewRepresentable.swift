//
//  ScrollViewRepresentable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

extension ScrollViewRepresentable: Setupable {
    func isScrollDisabled(_ disabled: Bool) -> Self {
        map { $0.isScrollDisabled = disabled }
    }
}

protocol ScrollViewRepresentableDelegate: AnyObject {
    func contentOffsetDidChanged(contentOffset: CGPoint)
    func gesture(onChanged value: UIPanGestureRecognizer.Value)
    func gesture(onEnded value: UIPanGestureRecognizer.Value)
}

struct ScrollViewRepresentable<Content: View>: UIViewRepresentable {
    private weak var delegate: ScrollViewRepresentableDelegate?
    private let content: () -> Content

    private var isScrollDisabled: Bool = false

    init(
        delegate: ScrollViewRepresentableDelegate,
        content: @escaping () -> Content
    ) {
        self.delegate = delegate
        self.content = content
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.isScrollEnabled = !isScrollDisabled
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.showsVerticalScrollIndicator = true
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.alwaysBounceVertical = true

        guard let contentView = context.coordinator.hostingController.view else {
            assertionFailure("HostingController haven't rootView")
            return scrollView
        }

        scrollView.addSubview(contentView)

        let gesture = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.gestureRecognizerPanned)
        )

        gesture.delegate = context.coordinator
        scrollView.addGestureRecognizer(gesture)

        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        uiView.isScrollEnabled = !isScrollDisabled

        // Use it for handle SwiftUI view updating
        context.coordinator.hostingController.rootView = content()

        guard let contentView = context.coordinator.hostingController.view else {
            assertionFailure("HostingController haven't rootView")
            return
        }

        let screenSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        let contentSize = contentView.sizeThatFits(screenSize)
        contentView.frame = CGRect(x: 0, y: 0, width: contentSize.width, height: contentSize.height)

        uiView.contentSize = contentSize
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(
            hostingController: UIHostingController(rootView: content()),
            delegate: delegate
        )
    }
}

// MARK: - Coordinator

extension ScrollViewRepresentable {
    class Coordinator: NSObject, UIScrollViewDelegate, UIGestureRecognizerDelegate {
        var hostingController: UIHostingController<Content>
        weak var delegate: ScrollViewRepresentableDelegate?

        private var startLocation = CGPoint.zero
        private var contentOffset = CGPoint.zero

        init(
            hostingController: UIHostingController<Content>,
            delegate: ScrollViewRepresentableDelegate?
        ) {
            self.hostingController = hostingController
            self.delegate = delegate
        }

        // MARK: - UIScrollViewDelegate

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            contentOffset = scrollView.contentOffset
            delegate?.contentOffsetDidChanged(contentOffset: scrollView.contentOffset)
        }

        // MARK: - UIGestureRecognizerDelegate

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
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
                let value = UIPanGestureRecognizer.Value(
                    time: Date(),
                    location: gesture.location(in: view),
                    startLocation: startLocation,
                    velocity: gesture.velocity(in: view)
                )
                delegate?.gesture(onChanged: value)

            case .ended:
                let value = UIPanGestureRecognizer.Value(
                    time: Date(),
                    location: gesture.location(in: view),
                    startLocation: startLocation,
                    velocity: gesture.velocity(in: view)
                )
                delegate?.gesture(onEnded: value)
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
}

// MARK: - Value

public extension UIPanGestureRecognizer {
    /// This API is meant to mirror DragGesture,.Value as that has no accessible initializers
    struct Value {
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
}
