//
//  OverlayViewPresenterModifier.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct OverlayViewPresenterModifier: ViewModifier {
    @ObservedObject var viewModel: OverlayViewPresenterViewModel
    var depth: Int = 0

    func body(content: Content) -> some View {
        content
            .sheet(item: viewModel.sheet(at: depth)) { item in
                OverlayStackPresentedView(item: item, viewModel: viewModel, nextDepth: depth + 1)
            }
            .fullScreenCover(item: viewModel.fullScreenCover(at: depth)) { item in
                OverlayStackPresentedView(item: item, viewModel: viewModel, nextDepth: depth + 1)
            }
    }
}

/// Wraps a presented overlay view and re-applies the modifier so it can host the next stacked level.
private struct OverlayStackPresentedView: View {
    let item: OverlayView
    @ObservedObject var viewModel: OverlayViewPresenterViewModel
    let nextDepth: Int

    var body: some View {
        item.view
            .modifier(OverlayViewPresenterModifier(viewModel: viewModel, depth: nextDepth))
    }
}
