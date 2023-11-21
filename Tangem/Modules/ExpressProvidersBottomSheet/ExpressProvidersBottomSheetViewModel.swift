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

    private let percentFormatter: PercentFormatter
    private let expressProviderFormatter: ExpressProviderFormatter
    private unowned let expressInteractor: ExpressInteractor
    private unowned let coordinator: ExpressProvidersBottomSheetRoutable

    private var bag: Set<AnyCancellable> = []

    init(
        input: InputModel,
        percentFormatter: PercentFormatter,
        expressProviderFormatter: ExpressProviderFormatter,
        expressInteractor: ExpressInteractor,
        coordinator: ExpressProvidersBottomSheetRoutable
    ) {
        selectedProviderId = input.selectedProviderId
        quotes = input.quotes

        self.percentFormatter = percentFormatter
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
        let senderCurrencyCode = expressInteractor.getSender().tokenItem.currencySymbol
        let destinationCurrencyCode = expressInteractor.getDestination()?.tokenItem.currencySymbol
        var subtitles: [ProviderRowViewModel.Subtitle] = []

        subtitles.append(
            expressProviderFormatter.mapToRateSubtitle(
                quote: quote,
                senderCurrencyCode: senderCurrencyCode,
                destinationCurrencyCode: destinationCurrencyCode,
                option: .destination
            )
        )

        if !quote.isBest, let percentSubtitle = makePercentSubtitle(quote: quote) {
            subtitles.append(percentSubtitle)
        }

        let provider = quote.provider

        return ProviderRowViewModel(
            provider: expressProviderFormatter.mapToProvider(provider: provider),
            isDisabled: !quote.isAvailable,
            badge: provider.type == .dex ? .permissionNeeded : .none,
            subtitles: subtitles,
            detailsType: selectedProviderId == provider.id ? .selected : .none,
            tapAction: { [weak self] in
                self?.selectedProviderId = provider.id
                self?.expressInteractor.updateProvider(provider: provider)
                self?.coordinator.closeExpressProvidersBottomSheet()
            }
        )
    }

    func makePercentSubtitle(quote: ExpectedQuote) -> ProviderRowViewModel.Subtitle? {
        guard let bestRate = quotes.first(where: { $0.isBest })?.rate,
              !quote.rate.isZero else {
            return nil
        }

        let changePercent = 1 - bestRate / quote.rate
        let formatted = percentFormatter.percentFormat(value: changePercent, option: .expressRate)

        return .percent(formatted, signType: ChangeSignType(from: changePercent))
    }
}

extension ExpressProvidersBottomSheetViewModel {
    struct InputModel {
        let selectedProviderId: Int?
        let quotes: [ExpectedQuote]
    }
}
