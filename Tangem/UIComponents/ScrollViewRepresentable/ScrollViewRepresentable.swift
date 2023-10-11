//
//  ScrollViewRepresentable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct ScrollViewRepresentable<Content: View>: UIViewRepresentable {
    private let content: () -> Content
    private var isScrollDisabled: Bool = false

    private weak var delegate: ScrollViewRepresentableDelegate?

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
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceVertical = true

        guard let contentView = context.coordinator.hostingController.view else {
            assertionFailure("HostingController haven't rootView")
            return scrollView
        }

        scrollView.addSubview(contentView)
        scrollView.contentSize = context.coordinator.contentSize()

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

        let hostingController = context.coordinator.hostingController
        // Use it for handle SwiftUI view updating
        hostingController.rootView = content()

        uiView.contentSize = context.coordinator.contentSize()

        if let safeAreaInsets = delegate?.getSafeAreaInsets() {
            uiView.contentInset = safeAreaInsets
            uiView.verticalScrollIndicatorInsets = safeAreaInsets
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            hostingController: UIHostingController(rootView: content()),
            delegate: delegate
        )
    }
}

// MARK: - Setupable protocol conformance

extension ScrollViewRepresentable: Setupable {
    func isScrollDisabled(_ disabled: Bool) -> Self {
        map { $0.isScrollDisabled = disabled }
    }
}

// MARK: - Coordinator

extension ScrollViewRepresentable {
    class Coordinator: NSObject, UIScrollViewDelegate, UIGestureRecognizerDelegate {
        let hostingController: UIHostingController<Content>

        private var startLocation: CGPoint = .zero

        private weak var delegate: ScrollViewRepresentableDelegate?

        init(
            hostingController: UIHostingController<Content>,
            delegate: ScrollViewRepresentableDelegate?
        ) {
            self.hostingController = hostingController
            self.delegate = delegate
        }

        func contentSize() -> CGSize {
            guard let contentView = hostingController.view else {
                assertionFailure("HostingController doesn't have a rootView")
                return .zero
            }

            let screenSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            let contentSize = contentView.sizeThatFits(screenSize)

            // Update size inside contentView
            contentView.frame = CGRect(origin: .zero, size: contentSize)

            return contentSize
        }

        // MARK: - UIScrollViewDelegate

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            delegate?.contentOffsetDidChanged(contentOffset: scrollView.contentOffset)
        }

        // MARK: - UIGestureRecognizerDelegate

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            return true
        }

        @objc
        func gestureRecognizerPanned(_ gesture: UIPanGestureRecognizer) {
            guard let view = getGlobalView() else {
                assertionFailure("Can't get a global view")
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

        private func getGlobalView() -> UIView? {
            // getting the all scenes
            let scenes = UIApplication.shared.connectedScenes
            // getting windowScene from scenes
            let windowScene = scenes.first as? UIWindowScene
            // getting window from windowScene
            let window = windowScene?.windows.first
            // getting the root view controller
            let rootVC = window?.rootViewController

            return rootVC?.view
        }
    }
}

// MARK: - UIPanGestureRecognizer.Value

extension UIPanGestureRecognizer {
    /// This API is meant to mirror DragGesture,.Value as that has no accessible initializers
    struct Value {
        /// The time associated with the current event.
        let time: Date

        /// The location of the current event.
        let location: CGPoint

        /// The location of the first event.
        let startLocation: CGPoint

        let velocity: CGPoint

        /// The total translation from the first event to the current
        /// event. Equivalent to `location.{x,y} -
        /// startLocation.{x,y}`.
        var translation: CGSize {
            return CGSize(width: location.x - startLocation.x, height: location.y - startLocation.y)
        }

        /// A prediction of where the final location would be if
        /// dragging stopped now, based on the current drag velocity.
        var predictedEndLocation: CGPoint {
            let endTranslation = predictedEndTranslation
            return CGPoint(x: location.x + endTranslation.width, y: location.y + endTranslation.height)
        }

        var predictedEndTranslation: CGSize {
            return CGSize(
                width: estimatedTranslation(fromVelocity: velocity.x),
                height: estimatedTranslation(fromVelocity: velocity.y)
            )
        }

        private func estimatedTranslation(fromVelocity velocity: CGFloat) -> CGFloat {
            // This is a guess. I couldn't find any documentation anywhere on what this should be
            let acceleration: CGFloat = 500.0
            let timeToStop = velocity / acceleration
            return velocity * timeToStop / 2.0
        }
    }
}
