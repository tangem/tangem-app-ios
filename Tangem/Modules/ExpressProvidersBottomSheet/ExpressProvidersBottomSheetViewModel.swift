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

    private var selectedProviderId: ExpressProvider.Id? = nil
    private var quotes: [ExpectedQuote] = []

    private let percentFormatter: PercentFormatter
    private let expressProviderFormatter: ExpressProviderFormatter
    private unowned let expressInteractor: ExpressInteractor
    private unowned let coordinator: ExpressProvidersBottomSheetRoutable

    private var bag: Set<AnyCancellable> = []

    init(
        percentFormatter: PercentFormatter,
        expressProviderFormatter: ExpressProviderFormatter,
        expressInteractor: ExpressInteractor,
        coordinator: ExpressProvidersBottomSheetRoutable
    ) {
        self.percentFormatter = percentFormatter
        self.expressProviderFormatter = expressProviderFormatter
        self.expressInteractor = expressInteractor
        self.coordinator = coordinator

        bind()
    }

    func bind() {
        expressInteractor.state
            .sink { [weak self] state in
                self?.setupView()
            }.store(in: &bag)
    }

    func setupView() {
        runTask(in: self) { viewModel in
            viewModel.quotes = await viewModel.expressInteractor.getAllQuotes()
            viewModel.selectedProviderId = await viewModel.expressInteractor.getSelectedProvider()?.id

            await runOnMain {
                viewModel.updateView()
            }
        }
    }

    func updateView() {
        providerViewModels = quotes
            .sorted(by: { $0.rate > $1.rate })
            .compactMap { quote in
                guard quote.isAvailableToShow else {
                    return nil
                }

                return mapToProviderRowViewModel(quote: quote)
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
                option: .exchangeReceivedAmount
            )
        )

        if !quote.isBest, let percentSubtitle = makePercentSubtitle(quote: quote) {
            subtitles.append(percentSubtitle)
        }

        let provider = quote.provider
        let isDisabled = !quote.isAvailableToSelect

        let badge: ProviderRowViewModel.Badge? = {
            if isDisabled {
                return .none
            }

            return provider.type == .dex ? .permissionNeeded : .none
        }()

        return ProviderRowViewModel(
            provider: expressProviderFormatter.mapToProvider(provider: provider),
            isDisabled: isDisabled,
            badge: badge,
            subtitles: subtitles,
            detailsType: selectedProviderId == provider.id ? .selected : .none,
            tapAction: { [weak self] in
                self?.userDidTap(provider: provider)
            }
        )
    }

    func userDidTap(provider: ExpressProvider) {
        Analytics.log(event: .swapProviderChosen, params: [.provider: provider.name])

        selectedProviderId = provider.id
        expressInteractor.updateProvider(provider: provider)
        coordinator.closeExpressProvidersBottomSheet()
    }

    func makePercentSubtitle(quote: ExpectedQuote) -> ProviderRowViewModel.Subtitle? {
        guard let bestRate = quotes.first(where: { $0.isBest })?.rate, !quote.rate.isZero else {
            return nil
        }

        let changePercent = 1 - bestRate / quote.rate
        let formatted = percentFormatter.expressRatePercentFormat(value: changePercent)

        return .percent(formatted, signType: ChangeSignType(from: changePercent))
    }
}

private extension ExpectedQuote {
    var isAvailableToSelect: Bool {
        switch state {
        case .quote, .tooSmallAmount:
            return true
        case .error, .notAvailable:
            return false
        }
    }

    var isAvailableToShow: Bool {
        switch state {
        case .quote, .tooSmallAmount, .notAvailable:
            return true
        case .error:
            return false
        }
    }
}
