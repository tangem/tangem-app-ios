//
//  View+FeedZoomTransition.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

extension EnvironmentValues {
    @Entry var feedZoomNamespace: Namespace.ID?
}

extension View {
    func feedZoomSource(_ source: FeedZoomSource, cornerRadius: CGFloat) -> some View {
        modifier(FeedZoomSourceModifier(source: source, cornerRadius: cornerRadius))
    }

    @ViewBuilder
    func feedZoomTransition(from source: FeedZoomSource, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            navigationTransition(.zoom(sourceID: source, in: namespace))
        } else {
            self
        }
    }
}

private struct FeedZoomSourceModifier: ViewModifier {
    let source: FeedZoomSource
    let cornerRadius: CGFloat

    @Environment(\.feedZoomNamespace) private var namespace

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *), let namespace {
            content.matchedTransitionSource(id: source, in: namespace) { source in
                source
                    .background(DesignSystem.Color.bgSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            }
        } else {
            content
        }
    }
}
