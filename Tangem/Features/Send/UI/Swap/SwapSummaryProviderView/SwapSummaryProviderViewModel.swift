//
//  SwapProviderViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemLocalization
import TangemFoundation
import TangemExpress
import TangemMacro

protocol SwapSummaryProviderRoutable: AnyObject {
    func userDidTapProvider()
}

final class SwapSummaryProviderViewModel: ObservableObject, Identifiable {
    @Published private(set) var providerState: ProviderState?

    weak var router: SwapSummaryProviderRoutable?

    private let expressProviderFormatter: ExpressProviderFormatter

    init(
        expressProviderFormatter: ExpressProviderFormatter,
        sourceTokenInput: SendSourceTokenInput,
        receiveTokenInput: SendReceiveTokenInput,
        swapProvidersInput: SendSwapProvidersInput,
        receiveTokenAmountInput: SendReceiveTokenAmountInput?
    ) {
        self.expressProviderFormatter = expressProviderFormatter

        bind(
            sourceTokenInput: sourceTokenInput,
            receiveTokenInput: receiveTokenInput,
            swapProvidersInput: swapProvidersInput,
            receiveTokenAmountInput: receiveTokenAmountInput
        )
    }
}

// MARK: - Private

private extension SwapSummaryProviderViewModel {
    func bind(
        sourceTokenInput: SendSourceTokenInput,
        receiveTokenInput: SendReceiveTokenInput,
        swapProvidersInput: SendSwapProvidersInput,
        receiveTokenAmountInput: SendReceiveTokenAmountInput?
    ) {
        let highPriceImpactPublisher = receiveTokenAmountInput?.highPriceImpactPublisher ?? Just(nil).eraseToAnyPublisher()

        let tokensPublisher = Publishers.CombineLatest(
            sourceTokenInput.sourceTokenPublisher.compactMap { $0.value },
            receiveTokenInput.receiveTokenPublisher.compactMap { $0.value }
        ).map { (source: $0, receive: $1) }

        let providersPublisher = Publishers.CombineLatest(
            swapProvidersInput.selectedExpressProviderPublisher,
            swapProvidersInput.expressProvidersPublisher
        ).map { (selected: $0, all: $1) }

        Publishers.CombineLatest3(tokensPublisher, providersPublisher, highPriceImpactPublisher)
            .withWeakCaptureOf(self)
            .map { viewModel, swapInput in
                let (tokenValues, providerValues, highPriceImpactValue) = swapInput
                let hasWarning = highPriceImpactValue.map { !$0.level.isNegligible } ?? false
                return viewModel.mapToProviderState(
                    sourceToken: tokenValues.source,
                    receiveToken: tokenValues.receive,
                    provider: providerValues.selected,
                    providers: providerValues.all,
                    hasHighPriceImpactWarning: hasWarning
                )
            }
            .receiveOnMain()
            .assign(to: &$providerState)
    }

    func mapToProviderState(
        sourceToken: SendSourceToken,
        receiveToken: SendReceiveToken,
        provider: LoadingResult<ExpressAvailableProvider, any Error>?,
        providers: [ExpressAvailableProvider],
        hasHighPriceImpactWarning: Bool
    ) -> ProviderState? {
        switch provider {
        case .none:
            return nil
        case .loading:
            return .loading
        case .failure:
            return nil
        case .success(let provider):
            if let data = mapToProviderRowViewModel(
                sourceToken: sourceToken,
                receiveToken: receiveToken,
                selectedProvider: provider,
                providers: providers,
                hasHighPriceImpactWarning: hasHighPriceImpactWarning
            ) {
                return .loaded(data: data)
            }

            return nil
        }
    }

    func mapToProviderRowViewModel(
        sourceToken: SendSourceToken,
        receiveToken: SendReceiveToken,
        selectedProvider: ExpressAvailableProvider,
        providers: [ExpressAvailableProvider],
        hasHighPriceImpactWarning: Bool
    ) -> ProviderRowViewModel? {
        // Has more than one `showableProviders` to selection
        let hasAnotherProviders = providers.showableProviders().count > 1
        let state = selectedProvider.getState()
        let selectedProviderNonError = !state.isError

        guard hasAnotherProviders || selectedProviderNonError else {
            return nil
        }

        let subtitle = expressProviderFormatter.mapToRateSubtitle(
            state: state,
            senderCurrencyCode: sourceToken.tokenItem.currencySymbol,
            destinationCurrencyCode: receiveToken.tokenItem.currencySymbol,
            option: .exchangeRate
        )

        let providerBadge = expressProviderFormatter.mapToBadge(availableProvider: selectedProvider, hasHighPriceImpactWarning: hasHighPriceImpactWarning)
        let badge: ProviderRowViewModel.Badge? = switch providerBadge {
        case .none: .none
        case .bestRate: .bestRate
        case .fcaWarning: .fcaWarning
        case .permissionNeeded: .permissionNeeded
        }

        return ProviderRowViewModel(
            provider: expressProviderFormatter.mapToProvider(provider: selectedProvider.provider),
            titleFormat: .name,
            isDisabled: false,
            badge: badge,
            subtitles: [subtitle],
            detailsType: .chevron
        ) { [weak self] in
            self?.router?.userDidTapProvider()
        }
    }
}

extension SwapSummaryProviderViewModel {
    @RawCaseName
    enum ProviderState: Identifiable {
        case loading
        case loaded(data: ProviderRowViewModel)
    }
}
