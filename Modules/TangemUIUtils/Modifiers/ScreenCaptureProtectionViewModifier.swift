//
//  ScreenCaptureProtectionViewModifier.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    /// Protects the given view from both screenshots and built-in screen recording.
    func screenCaptureProtection() -> some View {
        modifier(ScreenCaptureProtectionViewModifier())
    }
}

// MARK: - Private implementation iOS 16+

private struct ScreenCaptureProtectionViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        ScreenCaptureProtectionContainerView { content }
    }
}

private final class PreferredContentSizeForwardingUIHostingController<T>: UIHostingController<T> where T: View {
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let contentSize = view.bounds.size
        if contentSize != preferredContentSize {
            preferredContentSize = view.bounds.size
        }
    }
}

// MARK: - Private implementation common

private struct ScreenCaptureProtectionContainerView<Content: View>: UIViewControllerRepresentable {
    let content: () -> Content

    func makeUIViewController(context: Context) -> UIViewController {
        let containerViewController = ScreenCaptureProtectionContainerViewController()
        let contentViewController: UIViewControllerType

        let hostingViewController = PreferredContentSizeForwardingUIHostingController(rootView: content())
        hostingViewController.sizingOptions = .preferredContentSize
        contentViewController = hostingViewController

        containerViewController.addChild(contentViewController)

        let containerView = containerViewController.view!
        let contentView = contentViewController.view!

        contentView.backgroundColor = .clear
        contentView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: containerView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
        ])

        contentViewController.didMove(toParent: containerViewController)

        return containerViewController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}

private final class ScreenCaptureProtectionContainerViewController: UIViewController {
    private static var screenCaptureProtectionViewName = [
        "_",
        "UI",
        "Text",
        "Layout",
        "Canvas",
        "View",
    ].joined()

    /// This property also maintains a strong reference to the `UITextField` instance
    /// (necessary since this instance isn't embedded into the view hierarchy).
    private lazy var uiTextField: UITextField = {
        let uiTextField = UITextField()
        uiTextField.isSecureTextEntry = true
        return uiTextField
    }()

    private var screenCaptureProtectionView: UIView {
        let viewName = Self.screenCaptureProtectionViewName
        if let view: UIView = uiTextField.firstSubview(where: { NSStringFromClass(type(of: $0)) == viewName }) {
            return view
        }

        assertionFailure("Unable to find the view of type '\(viewName)' in the view hierarchy of '\(uiTextField)'")

        return uiTextField.subviews.first ?? UIView()
    }

    override func loadView() {
        view = screenCaptureProtectionView
        view.isUserInteractionEnabled = true
    }

    override func preferredContentSizeDidChange(forChildContentContainer container: any UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        preferredContentSize = container.preferredContentSize
    }
}

// MARK: - Convenience extensions

private extension UIView {
    func firstSubview<T>(where predicate: (_ subview: UIView) -> Bool) -> T? {
        for subview in subviews {
            if predicate(subview) {
                return subview as? T
            }

            if let firstSubview: T? = subview.firstSubview(where: predicate) {
                return firstSubview
            }
        }

        return nil
    }
}
