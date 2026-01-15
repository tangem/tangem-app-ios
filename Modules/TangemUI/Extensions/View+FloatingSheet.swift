//
//  View+FloatingSheet.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    func floatingSheet(viewModel: (any FloatingSheetContentViewModel)?, dismissSheetAction: @escaping () -> Void = {}) -> some View {
        FloatingSheetView(viewModel: viewModel, dismissSheetAction: dismissSheetAction)
    }

    func floatingSheetContent<SheetContentViewModel: FloatingSheetContentViewModel>(
        for type: SheetContentViewModel.Type,
        @ViewBuilder viewBuilder: @escaping (SheetContentViewModel) -> some View
    ) -> some View {
        background(FloatingSheetRegisterer(type: type, viewBuilder: viewBuilder))
            .modifier(FloatingSheetVisibilityModifier(type: type))
    }

    func floatingSheetConfiguration(_ configurationBuilder: (_ configuration: inout FloatingSheetConfiguration) -> Void) -> some View {
        var configuration = FloatingSheetConfiguration.default
        configurationBuilder(&configuration)
        return preference(key: FloatingSheetConfigurationPreferenceKey.self, value: configuration)
    }
}
