//
//  IntrospectResponderChainViewModifier.swift
//  TangemUIUtils
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

// MARK: - Convenience extensions

public extension View {
    @ViewBuilder
    func introspectResponderChain<IntrospectedType>(
        introspectedType: IntrospectedType.Type,
        introspectionTriggers: [IntrospectionTrigger],
        includeSubviews: Bool = false,
        action: @escaping (_ introspectedInstance: IntrospectedType) -> Void
    ) -> some View {
        modifier(
            IntrospectResponderChainViewModifier(
                introspectedType: introspectedType,
                introspectionTriggers: introspectionTriggers,
                includeSubviews: includeSubviews,
                action: action
            )
        )
    }
}

public enum IntrospectionTrigger {
    case willAppear
    case didAppear
}

// MARK: - Private implementation

private struct IntrospectResponderChainViewModifier<IntrospectedType>: ViewModifier {
    typealias Action = (_ introspectedInstance: IntrospectedType) -> Void

    let introspectedType: IntrospectedType.Type
    let introspectionTriggers: [IntrospectionTrigger]
    let includeSubviews: Bool
    let action: Action

    func body(content: Content) -> some View {
        content.background {
            IntrospectView(
                introspectedType: introspectedType,
                introspectionTriggers: introspectionTriggers,
                includeSubviews: includeSubviews,
                action: action
            )
            .frame(size: .zero)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

// MARK: - Auxiliary types

private extension IntrospectResponderChainViewModifier {
    struct IntrospectView: UIViewControllerRepresentable {
        typealias ViewController = IntrospectViewController

        let introspectedType: IntrospectedType.Type
        let introspectionTriggers: [IntrospectionTrigger]
        let includeSubviews: Bool
        let action: Action

        func makeUIViewController(context: Context) -> ViewController {
            ViewController { trigger, view in
                if introspectionTriggers.contains(trigger) {
                    searchIn(uiView: view)
                }
            }
        }

        func updateUIViewController(_ viewController: ViewController, context: Context) {}

        private func searchIn(uiView: UIView) {
            var nextResponder = uiView.next
            while let responder = nextResponder {
                if let introspectedInstance = responder as? IntrospectedType {
                    action(introspectedInstance)
                    break
                }

                // if responder is a UIView, search its subview tree as well
                // (many UIKit internals put the useful views as children)
                if includeSubviews, let view = responder as? UIView {
                    if let introspectedInstance = searchInSubviews(view) {
                        action(introspectedInstance)
                        break
                    }
                }

                nextResponder = nextResponder?.next
            }
        }

        private func searchInSubviews(_ root: UIView) -> IntrospectedType? {
            var stack: [UIView] = [root]

            while !stack.isEmpty {
                let view = stack.removeLast()

                if let match = view as? IntrospectedType {
                    return match
                }

                for sub in view.subviews {
                    stack.append(sub)
                }
            }

            return nil
        }
    }

    class IntrospectViewController: UIViewController {
        typealias Handler = (IntrospectionTrigger, UIView) -> Void

        private var handler: Handler?

        init(handler: @escaping Handler) {
            super.init(nibName: nil, bundle: nil)
            self.handler = handler
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            handler?(.willAppear, view)
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            handler?(.didAppear, view)
        }
    }
}
