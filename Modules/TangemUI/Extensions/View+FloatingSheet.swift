//
//  View+FloatingSheet.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    /// - Warning: This method maintains a strong reference to the given `observer` closure.
    /// Make sure to avoid retain cycles when using it.
    func floatingSheet(viewModel: (any FloatingSheetContentViewModel)?, dismissSheetAction: @escaping () -> Void = {}) -> some View {
        FloatingSheetView(viewModel: viewModel, dismissSheetAction: dismissSheetAction)
    }

    /// - Warning: This method maintains a strong reference to the given `observer` closure.
    /// Make sure to avoid retain cycles when using it.
    func floatingSheetContent<SheetContentViewModel: FloatingSheetContentViewModel>(
        for type: SheetContentViewModel.Type,
        @ViewBuilder viewBuilder: @escaping (SheetContentViewModel) -> some View
    ) -> some View {
        background(FloatingSheetRegisterer(type: type, viewBuilder: viewBuilder))
    }

    /// - Warning: This method maintains a strong reference to the given `observer` closure.
    /// Make sure to avoid retain cycles when using it.
    func floatingSheetConfiguration(_ configurationBuilder: (_ configuration: inout FloatingSheetConfiguration) -> Void) -> some View {
        var configuration = FloatingSheetConfiguration.default
        configurationBuilder(&configuration)
        return preference(key: FloatingSheetConfigurationPreferenceKey.self, value: configuration)
    }
}
