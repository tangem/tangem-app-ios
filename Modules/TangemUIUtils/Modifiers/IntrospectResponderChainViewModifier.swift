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
        includeSubviews: Bool = false,
        updateOnChangeOf: AnyHashable? = nil,
        action: @escaping (_ introspectedInstance: IntrospectedType) -> Void
    ) -> some View {
        modifier(
            IntrospectResponderChainViewModifier(
                introspectedType: introspectedType,
                includeSubviews: includeSubviews,
                updateOnChangeOf: updateOnChangeOf,
                action: action
            )
        )
    }
}

// MARK: - Private implementation

private struct IntrospectResponderChainViewModifier<IntrospectedType>: ViewModifier {
    typealias Action = (_ introspectedInstance: IntrospectedType) -> Void

    let introspectedType: IntrospectedType.Type
    let includeSubviews: Bool
    let updateOnChangeOf: AnyHashable?
    let action: Action

    func body(content: Content) -> some View {
        content.overlay {
            IntrospectView(introspectedType: introspectedType, includeSubviews: includeSubviews, action: action)
                .frame(size: .zero)
                .allowsHitTesting(false)
                .accessibility(hidden: true)
                .ifLet(updateOnChangeOf) { view, id in
                    view.id(id)
                }
        }
    }
}

// MARK: - Auxiliary types

private extension IntrospectResponderChainViewModifier {
    struct IntrospectView: UIViewRepresentable {
        typealias UIViewType = UIView

        let introspectedType: IntrospectedType.Type
        let includeSubviews: Bool
        let action: Action

        func makeUIView(context: Context) -> UIViewType {
            return UIView()
        }

        func updateUIView(_ uiView: UIViewType, context: Context) {
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
}
