//
//  OverlayContentContainerViewControllerAdapter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils

/// SwiftUI-compatible adapter for `OverlayContentContainerViewController`.
final class OverlayContentContainerViewControllerAdapter {
    private weak var containerViewController: OverlayContentContainerViewController?
}

extension OverlayContentContainerViewControllerAdapter: OverlayContentContainerInitializable {
    func set(_ containerViewController: OverlayContentContainerViewController) {
        self.containerViewController = containerViewController
    }
}

// MARK: - OverlayContentContainer protocol conformance

extension OverlayContentContainerViewControllerAdapter: OverlayContentContainer {
    var cornerRadius: CGFloat { containerViewController?.overlayCornerRadius ?? .zero }

    var isScrollViewLocked: Bool { containerViewController?.isScrollViewLocked ?? false }

    func installOverlay(_ overlayView: some View) {
        let overlayViewController: UIViewController

        if FeatureProvider.isAvailable(.redesign) {
            let hostingController = UIHostingController(
                rootView: VStack(spacing: 0) {
                    GrabberView(style: .redesigned)
                    overlayView
                        .mask {
                            RoundedCorner(radius: cornerRadius, corners: .topEdge)
                                .ignoresSafeArea(edges: .bottom)
                        }
                }
            )
            hostingController.view.backgroundColor = .clear
            overlayViewController = hostingController
        } else {
            overlayViewController = UIHostingController(
                rootView: overlayView
                    .overlay(alignment: .top) {
                        GrabberView()
                    }
            )
        }

        containerViewController?.installOverlay(overlayViewController)
    }

    func removeOverlay() {
        containerViewController?.removeOverlay()
    }

    func setOverlayHidden(_ isHidden: Bool) {
        containerViewController?.setOverlayHidden(isHidden)
    }
}

// MARK: - OverlayContentStateObserver protocol conformance

extension OverlayContentContainerViewControllerAdapter: OverlayContentStateObserver {
    func addObserver(_ observer: @escaping OverlayContentStateObserver.StateObserver, forToken token: any Hashable) {
        containerViewController?.addObserver(observer, forToken: token)
    }

    func addObserver(_ observer: @escaping OverlayContentStateObserver.ProgressObserver, forToken token: any Hashable) {
        containerViewController?.addObserver(observer, forToken: token)
    }

    func removeObserver(forToken token: any Hashable) {
        containerViewController?.removeObserver(forToken: token)
    }
}

// MARK: - OverlayContentStateController protocol conformance

extension OverlayContentContainerViewControllerAdapter: OverlayContentStateController {
    func collapse() {
        containerViewController?.collapse()
    }

    func expand() {
        containerViewController?.expand()
    }
}
