//
//  View+CollectiblesRegionRestrictions.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

extension View {
    func collectiblesRegionRestrictionsSheet(isRestricted: Binding<Bool>, isRequested: Binding<Bool>) -> some View {
        modifier(CollectiblesRegionRestrictionsSheetModifier(isRestricted: isRestricted, isRequested: isRequested))
    }
}

private struct CollectiblesRegionRestrictionsSheetModifier: ViewModifier {
    @Binding var isRestricted: Bool
    @Binding var isRequested: Bool

    @StateObject private var viewModel = CollectiblesGeoblockViewModel()

    func body(content: Content) -> some View {
        content
            .task {
                await viewModel.load()
                isRestricted = viewModel.isRestricted
            }
            .onChange(of: isRequested) { isRequested in
                guard isRequested else { return }

                viewModel.presentRestrictions()
                self.isRequested = false
            }
            .collectiblesInfoSheet(viewModel: viewModel.restrictionsSheetViewModel)
    }
}
