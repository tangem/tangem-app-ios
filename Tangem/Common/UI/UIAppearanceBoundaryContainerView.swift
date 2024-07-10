//
//  UIAppearanceBoundaryContainerView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import UIKit

/// Wrapper to limit propagation of changes made by using the `UIAppearance` API.
///
/// `BoundaryMarker` type must be unique within the boundaries of a particular namespace.
/// Some examples of namespaces are the app target itself, a SPM module, and a static/dynamic library.
///
/// Consider the following example:
/// ```
/// struct SomeView: View {
///     private static var didSetupUIAppearance = false
///
///     var body: some View {
///         UIAppearanceBoundaryContainerView(boundaryMarker: DummyMarkOnlyUIViewControllerSubclass.self) {
///             List(0..<10) { element in
///                 Text(String(describing: element))
///             }
///             .onAppear { Self.setupUIAppearanceIfNeeded() }
///         }
///     }
///
///     private static func setupUIAppearanceIfNeeded() {
///         if didSetupUIAppearance {
///             return
///         }
///         didSetupUIAppearance = true
///
///         let uiAppearance = UICollectionView.appearance(whenContainedInInstancesOf: [DummyMarkOnlyUIViewControllerSubclass.self])
///         uiAppearance.isScrollEnabled = false
///     }
/// }
///
/// private final class DummyMarkOnlyUIViewControllerSubclass: UIViewController {}
/// ```
/// Without using `UIAppearanceBoundaryContainerView` every `UICollectionView` in the app will have scroll disabled.
struct UIAppearanceBoundaryContainerView<BoundaryMarker, Content>: UIViewControllerRepresentable where
    Content: View,
    BoundaryMarker: UIViewController {
    private let content: () -> Content
    private let scale: Double

    /// Convenience constructor to avoid explicit generic specialization by the caller.
    init(
        boundaryMarker: BoundaryMarker.Type,
        scale: Double,
        content: @escaping () -> Content
    ) {
        self.scale = scale
        self.content = content
    }

    func makeUIViewController(context: Context) -> BoundaryMarker {
        let _ = print("\(#function) called at \(CACurrentMediaTime())")
        let containerController = BoundaryMarker()
        let hostingController = UIHostingController(rootView: content())
        containerController.addChild(hostingController)

        let containerView = containerController.view!
        let hostingView = hostingController.view!
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        hostingView.layer.cornerRadius = 14.0
        containerView.addSubview(hostingView)
        containerView.layer.cornerRadius = 14.0

        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: containerView.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
        ])

        hostingController.didMove(toParent: containerController)

        return containerController
    }

    func updateUIViewController(_ uiViewController: BoundaryMarker, context: Context) {
        let _ = print("\(#function) called at \(CACurrentMediaTime()) with \(scale)")
        if abs(scale - 0.92) <= .ulpOfOne || abs(scale - 1.0) <= .ulpOfOne {
            uiViewController.children.first?.view.layer.add(CABasicAnimation(keyPath: "transform"), forKey: "trans_anim")
        }
        uiViewController.children.first?.view.layer.setAffineTransform(.init(scaleX: scale, y: scale))
    }
}
