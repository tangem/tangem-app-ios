//
//  ModalDetentModifier.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils

struct ModalDetentModifier: ViewModifier {
    let size: ModalSize
    let contentLayout: ModalContentLayout
    let height: CGFloat?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var detents: Set<PresentationDetent>
    @State private var selection: PresentationDetent
    @State private var animationRevision: CGFloat = 0
    @State private var hasMeasuredHeight: Bool

    init(size: ModalSize, contentLayout: ModalContentLayout, height: CGFloat?) {
        self.size = size
        self.contentLayout = contentLayout
        self.height = height
        let detent = Self.detent(size: size, contentLayout: contentLayout, height: height)
        _detents = State(initialValue: [detent])
        _selection = State(initialValue: detent)
        _hasMeasuredHeight = State(initialValue: height != nil || size == .full || contentLayout == .fill)
    }

    func body(content: Content) -> some View {
        // Detents are discrete; this value lets SwiftUI observe the same animation through to completion.
        let revision = animationRevision

        content
            .presentationDetents(detents, selection: $selection)
            .onChange(of: detent) { target in
                if reduceMotion || !hasMeasuredHeight {
                    // Resolve the first native-bar measurement before animating subsequent content changes.
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        detents = [target]
                        selection = target
                        hasMeasuredHeight = true
                    }
                } else {
                    // Both endpoints must exist for SwiftUI to animate the selected detent.
                    detents.insert(target)
                    if #available(iOS 17.0, *) {
                        let revision = animationRevision + 1
                        withAnimation(.spring(response: 0.35, dampingFraction: 1), completionCriteria: .removed) {
                            selection = target
                            animationRevision = revision
                        } completion: {
                            finishTransition(to: target, revision: revision)
                        }
                    } else {
                        withAnimation(.spring(response: 0.35, dampingFraction: 1)) {
                            selection = target
                            animationRevision += 1
                        }
                    }
                }
            }
            .onAnimationCompleted(for: revision) {
                if #unavailable(iOS 17.0) {
                    finishTransition(to: detent, revision: revision)
                }
            }
            .onChange(of: reduceMotion) { reduceMotion in
                guard reduceMotion else { return }
                animationRevision += 1
                selection = detent
                detents = [detent]
            }
            .transaction { transaction in
                if reduceMotion {
                    transaction.disablesAnimations = true
                }
            }
    }

    private func finishTransition(to target: PresentationDetent, revision: CGFloat) {
        // An interrupted transition must not remove the endpoints of its replacement.
        guard revision == animationRevision else { return }
        selection = target
        detents = [target]
    }

    private var detent: PresentationDetent {
        Self.detent(size: size, contentLayout: contentLayout, height: height)
    }

    private static func detent(size: ModalSize, contentLayout: ModalContentLayout, height: CGFloat?) -> PresentationDetent {
        switch size {
        case .flexible:
            contentLayout == .fill ? .medium : height.map(PresentationDetent.height) ?? .medium
        case .full:
            .large
        }
    }
}
