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
        swapProvidersInput: SendSwapProvidersInput
    ) {
        self.expressProviderFormatter = expressProviderFormatter

        bind(
            sourceTokenInput: sourceTokenInput,
            receiveTokenInput: receiveTokenInput,
            swapProvidersInput: swapProvidersInput
        )
    }
}

// MARK: - Private

private extension SwapSummaryProviderViewModel {
    func bind(
        sourceTokenInput: SendSourceTokenInput,
        receiveTokenInput: SendReceiveTokenInput,
        swapProvidersInput: SendSwapProvidersInput
    ) {
        Publishers.CombineLatest3(
            sourceTokenInput.sourceTokenPublisher.compactMap { $0.value },
            receiveTokenInput.receiveTokenPublisher.compactMap { $0.value },
            swapProvidersInput.selectedExpressProviderPublisher
        )
        .withWeakCaptureOf(self)
        .map { $0.mapToProviderState(sourceToken: $1.0, receiveToken: $1.1, provider: .success($1.2)) }
        .receiveOnMain()
        .assign(to: &$providerState)
    }

    func mapToProviderState(
        sourceToken: SendSourceToken,
        receiveToken: SendReceiveToken,
        provider: LoadingResult<ExpressAvailableProvider?, any Error>
    ) -> ProviderState? {
        switch provider {
        case .loading:
            return .loading
        case .failure, .success(.none):
            return nil
        case .success(.some(let provider)):
            if let data = mapToProviderRowViewModel(sourceToken: sourceToken, receiveToken: receiveToken, provider: provider) {
                return .loaded(data: data)
            }

            return nil
        }
    }

    func mapToProviderRowViewModel(
        sourceToken: SendSourceToken,
        receiveToken: SendReceiveToken,
        provider selectedProvider: ExpressAvailableProvider
    ) -> ProviderRowViewModel? {
        let state = selectedProvider.getState()
        if state.isError {
            // Don't show a error provider
            return nil
        }

        let subtitle = expressProviderFormatter.mapToRateSubtitle(
            state: state,
            senderCurrencyCode: sourceToken.tokenItem.currencySymbol,
            destinationCurrencyCode: receiveToken.tokenItem.currencySymbol,
            option: .exchangeRate
        )

        let providerBadge = expressProviderFormatter.mapToBadge(availableProvider: selectedProvider)
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
