//
//  CountrySelectionFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemPay

enum CountrySelectionFactory {
    @MainActor
    static func makeView(
        store: TangemPayGeoStore,
        configuration: GeoSelectionConfiguration,
        loadingItemIdPublisher: AnyPublisher<String?, Never> = Just(nil).eraseToAnyPublisher(),
        output: @escaping (CountrySelectionViewModel.Output) -> Void
    ) -> some View {
        CountrySelectionView(
            viewModel: CountrySelectionViewModel(
                store: store,
                configuration: configuration,
                loadingItemIdPublisher: loadingItemIdPublisher,
                output: output
            )
        )
    }
}
