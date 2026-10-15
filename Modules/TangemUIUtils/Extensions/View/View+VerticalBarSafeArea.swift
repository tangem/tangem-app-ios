//
//  View+VerticalBarSafeArea.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    func ignoresVerticalBarSafeArea(_ isEnabled: Bool = true) -> some View {
        modifier(VerticalBarSafeAreaIgnoringModifier(isEnabled: isEnabled))
    }

    func keepsVerticalBarDuringSearch() -> some View {
        modifier(VerticalBarSearchModifier())
    }

    @available(iOS, obsoleted: 17.0, message: "Drop this function and use safeAreaPadding directly.")
    @ViewBuilder
    func verticalBarSafeAreaPadding(_ insets: EdgeInsets) -> some View {
        if #available(iOS 17.0, *) {
            safeAreaPadding(insets)
        } else {
            self
        }
    }
}

private struct VerticalBarSafeAreaIgnoringModifier: ViewModifier {
    let isEnabled: Bool

    @Environment(\.verticalBarEdge) private var verticalBarEdge

    func body(content: Content) -> some View {
        content.ignoresSafeArea(.container, edges: ignoredEdges)
    }

    private var ignoredEdges: Edge.Set {
        guard isEnabled else { return [] }

        return switch verticalBarEdge {
        case .leading: .leading
        case .trailing: .trailing
        case nil: []
        }
    }
}

private struct VerticalBarSearchModifier: ViewModifier {
    @Environment(\.verticalBarEdge) private var verticalBarEdge

    @State private var barInset: CGFloat = .zero

    func body(content: Content) -> some View {
        if #available(iOS 17.1, *) {
            content
                .safeAreaPadding(stickyInsets)
                .ignoresSafeArea(.container, edges: ignoredEdges)
                .background {
                    Color.clear.onGeometryChange(for: CGFloat.self, of: measuredInset) { inset in
                        if inset > .zero {
                            barInset = inset
                        }
                    }
                }
                .searchPresentationToolbarBehavior(verticalBarEdge == nil ? .automatic : .avoidHidingContent)
        } else {
            content
        }
    }

    private var ignoredEdges: Edge.Set {
        switch verticalBarEdge {
        case .leading: .leading
        case .trailing: .trailing
        case nil: []
        }
    }

    private var stickyInsets: EdgeInsets {
        switch verticalBarEdge {
        case .leading: EdgeInsets(top: .zero, leading: barInset, bottom: .zero, trailing: .zero)
        case .trailing: EdgeInsets(top: .zero, leading: .zero, bottom: .zero, trailing: barInset)
        case nil: EdgeInsets()
        }
    }

    private func measuredInset(_ proxy: GeometryProxy) -> CGFloat {
        switch verticalBarEdge {
        case .leading: proxy.safeAreaInsets.leading
        case .trailing: proxy.safeAreaInsets.trailing
        case nil: .zero
        }
    }
}
