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
        behaviour: IntrospectResponderChainBehaviour,
        updateOnChangeOf: AnyHashable? = nil,
        action: @escaping (_ introspectedInstance: IntrospectedType) -> Void
    ) -> some View {
        modifier(
            IntrospectResponderChainViewModifier(
                introspectedType: introspectedType,
                behaviour: behaviour,
                updateOnChangeOf: updateOnChangeOf,
                action: action
            )
        )
    }
}

public enum IntrospectResponderChainBehaviour {
    case responderChain
    case subviewTree
}

// MARK: - Private implementation

private struct IntrospectResponderChainViewModifier<IntrospectedType>: ViewModifier {
    typealias Action = (_ introspectedInstance: IntrospectedType) -> Void

    let introspectedType: IntrospectedType.Type
    let behaviour: IntrospectResponderChainBehaviour
    let updateOnChangeOf: AnyHashable?
    let action: Action

    func body(content: Content) -> some View {
        content.overlay {
            IntrospectView(introspectedType: introspectedType, behaviour: behaviour, action: action)
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
        let behaviour: IntrospectResponderChainBehaviour
        let action: Action

        func makeUIView(context: Context) -> UIViewType {
            return UIView()
        }

        func updateUIView(_ uiView: UIViewType, context: Context) {
            switch behaviour {
            case .responderChain:
                searchInResponders(uiView)
            case .subviewTree:
                searchInSubviews(uiView)
            }
        }

        private func searchInResponders(_ uiView: UIView) {
            var nextResponder = uiView.next

            while let responder = nextResponder {
                if let introspectedInstance = responder as? IntrospectedType {
                    action(introspectedInstance)
                    break
                }

                nextResponder = nextResponder?.next
            }
        }

        private func searchInSubviews(_ uiView: UIView) {
            var stack: [UIView] = [uiView]

            while !stack.isEmpty {
                let view = stack.removeLast()

                if let match = view as? IntrospectedType {
                    action(match)
                }

                for sub in view.subviews {
                    stack.append(sub)
                }
            }
        }
    }
}
