//
//  MarketsView+NavigationController.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils

extension View {
    func injectMarketsNavigationControllerConfigurator() -> some View {
        modifier(MarketsNavigationControllerConfiguratorViewModifier())
    }
}

private struct MarketsNavigationControllerConfiguratorViewModifier: ViewModifier {
    @StateObject private var navigationControllerDelegate = UINavigationControllerMulticastDelegate(
        customDelegate: MarketsViewNavigationControllerConfigurator()
    )

    @State private var responderChainIntrospectionTrigger = UUID()

    func body(content: Content) -> some View {
        content
            .onWillAppear {
                responderChainIntrospectionTrigger = UUID()
            }
            .onAppear {
                responderChainIntrospectionTrigger = UUID()
            }
            .introspectResponderChain(
                introspectedType: UINavigationController.self,
                updateOnChangeOf: responderChainIntrospectionTrigger,
                action: { [weak navigationControllerDelegate] navigationController in
                    navigationController.setNavigationBarAlwaysHidden()

                    // [REDACTED_USERNAME], dispatching for the next runloop iteration is required, due to onWillAppear usage.
                    // Installing the delegate immediately may interfere with in-flight navigation transitions and animations.
                    DispatchQueue.main.async {
                        navigationController.set(multicastDelegate: navigationControllerDelegate)
                    }
                }
            )
    }
}

private final class MarketsViewNavigationControllerConfigurator: NSObject, UINavigationControllerDelegate {
    private let cornerRadius: CGFloat

    override init() {
        cornerRadius = UIDevice.current.hasHomeScreenIndicator
            ? RootViewControllerFactory.Constants.notchDevicesOverlayCornerRadius
            : RootViewControllerFactory.Constants.notchlessDevicesOverlayCornerRadius
    }

    func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
    ) {
        // Rounded corners should be applied only to children VCs, leaving the root VC intact
        guard viewController !== navigationController.viewControllers.first else {
            return
        }

        if !viewController.isViewLoaded {
            AppLogger.info("Configurator will force load the root view of the view controller \(viewController)")
        }

        // Applying rounded corners in SwiftUI still leaves a white background underneath, so we're left with UIKit
        viewController.view.layer.cornerRadius(cornerRadius, corners: .topEdge)
    }
}
