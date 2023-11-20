//
//  ExpressProvidersBottomSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemSwapping

final class ExpressProvidersBottomSheetViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published var providerViewModels: [ProviderRowViewModel] = []

    // MARK: - Dependencies

    private var selectedProviderId: Int?
    private let quotes: [ExpectedQuote]

    private let expressProviderFormatter: ExpressProviderFormatter
    private unowned let expressInteractor: ExpressInteractor
    private unowned let coordinator: ExpressProvidersBottomSheetRoutable

    private var bag: Set<AnyCancellable> = []

    init(
        input: InputModel,
        expressProviderFormatter: ExpressProviderFormatter,
        expressInteractor: ExpressInteractor,
        coordinator: ExpressProvidersBottomSheetRoutable
    ) {
        selectedProviderId = input.selectedProviderId
        quotes = input.quotes

        self.expressProviderFormatter = expressProviderFormatter
        self.expressInteractor = expressInteractor
        self.coordinator = coordinator

        setupView()
    }

    func setupView() {
        updateView(quotes: quotes)
    }

    func updateView(quotes: [ExpectedQuote]) {
        providerViewModels = quotes.map { quote in
            mapToProviderRowViewModel(quote: quote)
        }
    }

    func mapToProviderRowViewModel(quote: ExpectedQuote) -> ProviderRowViewModel {
        let destinationCurrencyCode = expressInteractor.getDestination()?.tokenItem.currencySymbol
        let subtitle = expressProviderFormatter.mapToRateSubtitle(
            quote: quote,
            option: .destination(destinationCurrencyCode: destinationCurrencyCode)
        )

        let provider = quote.provider

        return ProviderRowViewModel(
            provider: expressProviderFormatter.mapToProvider(provider: provider),
            isDisabled: !quote.isAvailable,
            badge: provider.type == .dex ? .permissionNeeded : .none,
            subtitles: [subtitle],
            detailsType: selectedProviderId == provider.id ? .selected : .none,
            tapAction: { [weak self] in
                self?.selectedProviderId = provider.id
                self?.expressInteractor.updateProvider(provider: provider)
                self?.coordinator.closeExpressProvidersBottomSheet()
            }
        )
    }
}

extension ExpressProvidersBottomSheetViewModel {
    struct InputModel {
        let selectedProviderId: Int?
        let quotes: [ExpectedQuote]
    }
}
