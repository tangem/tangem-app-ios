//
//  CollectiblesInfoSheetView+Sheet.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

extension View {
    func collectiblesInfoSheet(viewModel: CollectiblesInfoSheetViewModel) -> some View {
        modifier(CollectiblesInfoSheetModifier(viewModel: viewModel))
    }
}

private struct CollectiblesInfoSheetModifier: ViewModifier {
    @ObservedObject var viewModel: CollectiblesInfoSheetViewModel

    func body(content: Content) -> some View {
        content.sheet(isPresented: $viewModel.isPresented, onDismiss: viewModel.didDismiss) {
            CollectiblesInfoSheetView(
                model: viewModel.model,
                onClose: viewModel.close,
                onPrimary: viewModel.primary,
                onSecondary: viewModel.secondary
            )
            .presentationDetents(idealHeight: CollectiblesInfoSheetView.Metrics.estimatedHeight)
            .presentationDragIndicator(.hidden)
        }
    }
}
