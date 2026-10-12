//
//  RegionSelectionFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemPay

enum RegionSelectionFactory {
    @MainActor
    static func makeView(
        store: TangemPayGeoStore,
        countryCode: String,
        configuration: GeoSelectionConfiguration,
        output: @escaping (RegionSelectionViewModel.Output) -> Void
    ) -> some View {
        RegionSelectionView(
            viewModel: RegionSelectionViewModel(
                store: store,
                countryCode: countryCode,
                configuration: configuration,
                output: output
            )
        )
    }
}
