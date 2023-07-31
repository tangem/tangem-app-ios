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
    init(
        isScrollDisabled: Binding<Bool>,
        contentOffset: @escaping (CGPoint) -> Void,
        onChanged: @escaping (ClearDragGestureView.Value) -> Void,
        onEnded: @escaping (ClearDragGestureView.Value) -> Void,
        content: @escaping () -> Content
    ) {
        _isScrollDisabled = isScrollDisabled
        self.contentOffset = contentOffset
        self.onChanged = onChanged
        self.onEnded = onEnded
        self.content = content
    }

    @Binding var isScrollDisabled: Bool
    public let contentOffset: (CGPoint) -> Void
    public let onChanged: (ClearDragGestureView.Value) -> Void
    public let onEnded: (ClearDragGestureView.Value) -> Void
    public let content: () -> Content

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.isScrollEnabled = !isScrollDisabled
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.showsVerticalScrollIndicator = true
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.alwaysBounceVertical = true

        let controller = context.coordinator.hostingController
        let contentView = controller.view!
        contentView.backgroundColor = .red.withAlphaComponent(0.3)

        scrollView.addSubview(contentView)
//        let screenSize = CGSize(width: UIScreen.main.bounds.width, height: scrollViewSize)
//        let contentSize = contentView.sizeThatFits(screenSize)
//
//        contentView.frame = CGRect(x: 0, y: 0, width: contentSize.width, height: contentSize.height)
//        scrollView.contentSize = contentSize

        let drag = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.gestureRecognizerPanned))
        drag.delegate = context.coordinator
        scrollView.addGestureRecognizer(drag)

        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        uiView.isScrollEnabled = !isScrollDisabled
        context.coordinator.hostingController.rootView = content()

        let controller = context.coordinator.hostingController
        let contentView = controller.view!
        let screenSize = CGSize(width: UIScreen.main.bounds.width, height: .greatestFiniteMagnitude)
        let contentSize = contentView.sizeThatFits(screenSize)
        contentView.frame = CGRect(x: 0, y: 0, width: contentSize.width, height: contentSize.height)
        uiView.contentSize = contentSize
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            hostingController: UIHostingController(rootView: content()),
            contentOffset: contentOffset,
            onChanged: onChanged,
            onEnded: onEnded
        )
    }
}

extension ScrollViewRepresentable {
    class Coordinator: NSObject, UIScrollViewDelegate, UIGestureRecognizerDelegate {
        let hostingController: UIHostingController<Content>
        public let contentOffset: (CGPoint) -> Void
        public let onChanged: (ClearDragGestureView.Value) -> Void
        public let onEnded: (ClearDragGestureView.Value) -> Void

        init(
            hostingController: UIHostingController<Content>,
            contentOffset: @escaping (CGPoint) -> Void,
            onChanged: @escaping (ClearDragGestureView.Value) -> Void,
            onEnded: @escaping (ClearDragGestureView.Value) -> Void
        ) {
            self.hostingController = hostingController
            self.contentOffset = contentOffset
            self.onChanged = onChanged
            self.onEnded = onEnded
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            contentOffset(scrollView.contentOffset)
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//            onEnded(scrollView.contentOffset)
            print(#function)
        }

        func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
            print(#function, velocity)
        }

        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            print(#function, "decelerate", decelerate)
            if !decelerate {
//                onEnded(scrollView.contentOffset)
            }
        }

        private var startLocation = CGPoint.zero

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
}

extension ScrollViewRepresentable {
    struct Value {
        let offset: CGPoint
    }
}
