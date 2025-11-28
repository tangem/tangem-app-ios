//
//  ExpressProvidersSelectorViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemExpress
import TangemFoundation
import TangemLocalization

final class ExpressProvidersSelectorViewModel: ObservableObject, Identifiable {
    @Injected(\.ukGeoDefiner) private var ukGeoDefiner: UKGeoDefiner

    // MARK: - ViewState

    @Published var ukNotificationInput: NotificationViewInput?
    @Published var providerViewModels: [ProviderRowViewModel] = []

    // MARK: - Dependencies

    private let priceChangeFormatter: PriceChangeFormatter
    private let expressProviderFormatter: ExpressProviderFormatter
    private let expressInteractor: ExpressInteractor

    weak var coordinator: ExpressProvidersSelectorRoutable?

    private var stateSubscription: AnyCancellable?

    init(
        priceChangeFormatter: PriceChangeFormatter,
        expressProviderFormatter: ExpressProviderFormatter,
        expressInteractor: ExpressInteractor
    ) {
        self.priceChangeFormatter = priceChangeFormatter
        self.expressProviderFormatter = expressProviderFormatter
        self.expressInteractor = expressInteractor

        bind()
    }

    func bind() {
        expressInteractor.state
            .dropFirst()
            .withWeakCaptureOf(self)
            .asyncMap { viewModel, _ -> (allProviders: [ExpressAvailableProvider], selectedProvider: ExpressAvailableProvider?) in
                let allProviders = await viewModel.expressInteractor.getAllProviders()
                await viewModel.showFCAWarningIfNeeded(allProviders: allProviders)
                let selectedProvider = await viewModel.expressInteractor.getSelectedProvider()
                return (allProviders, selectedProvider)
            }
            .withWeakCaptureOf(self)
            .asyncMap { viewModel, upstreamOutput in
                let (allProviders, selectedProvider) = upstreamOutput
                let sortedProviders = await viewModel.sortProviders(allProviders)
                return (sortedProviders, selectedProvider)
            }
            .withWeakCaptureOf(self)
            .asyncMap { viewModel, upstreamOutput in
                let (sortedProviders, selectedProvider) = upstreamOutput
                return await viewModel.filterAndMapProviders(sortedProviders, selectedProvider: selectedProvider)
            }
            .receiveOnMain()
            .assign(to: &$providerViewModels)
    }

    // MARK: - Private Implementation

    private func makePercentSubtitle(provider: ExpressAvailableProvider, selectedProvider: ExpressAvailableProvider?) async -> ProviderRowViewModel.Subtitle? {
        // For selectedProvider we don't add percent badge
        guard selectedProvider?.provider.id != provider.provider.id else {
            return nil
        }

        guard let quote = await provider.getState().quote,
              let selectedRate = await selectedProvider?.getState().quote?.rate else {
            return nil
        }

        let changePercent = quote.rate / selectedRate - 1
        let result = priceChangeFormatter.formatFractionalValue(changePercent, option: .express)
        return .percent(result.formattedText, signType: result.signType)
    }

    private func mapToProviderRowViewModel(provider: ExpressAvailableProvider, selectedProvider: ExpressAvailableProvider?) async -> ProviderRowViewModel {
        let senderCurrencyCode = expressInteractor.getSource().value?.tokenItem.currencySymbol
        let destinationCurrencyCode = expressInteractor.getDestination()?.tokenItem.currencySymbol
        var subtitles: [ProviderRowViewModel.Subtitle] = []

        let state = await provider.getState()
        subtitles.append(
            expressProviderFormatter.mapToRateSubtitle(
                state: state,
                senderCurrencyCode: senderCurrencyCode,
                destinationCurrencyCode: destinationCurrencyCode,
                option: .exchangeReceivedAmount
            )
        )

        let isSelected = selectedProvider?.provider.id == provider.provider.id

        let badge: ProviderRowViewModel.Badge? = {
            if ukGeoDefiner.isUK,
               ExpressConstants.expressProvidersFCAWarningList.contains(provider.provider.id) {
                return .fcaWarning
            }

            if state.isPermissionRequired {
                return .permissionNeeded
            }

            if provider.provider.recommended == true {
                return .recommended
            }

            return .none
        }()

        if let percentSubtitle = await makePercentSubtitle(provider: provider, selectedProvider: selectedProvider) {
            subtitles.append(percentSubtitle)
        }

        return ProviderRowViewModel(
            provider: expressProviderFormatter.mapToProvider(provider: provider.provider),
            titleFormat: .name,
            isDisabled: false,
            badge: badge,
            subtitles: subtitles,
            detailsType: isSelected ? .selected : .none,
            tapAction: { [weak self] in
                self?.userDidTap(provider: provider)
            }
        )
    }

    private func sortProviders(_ providers: [ExpressAvailableProvider]) async -> [ExpressAvailableProvider] {
        typealias SortableProvider = (priority: ExpressAvailableProvider.Priority, amount: Decimal)
        return await providers.asyncSorted(
            sort: { (first: SortableProvider, second: SortableProvider) in
                if first.priority == second.priority {
                    return first.amount > second.amount
                } else {
                    return first.priority > second.priority
                }
            },
            by: { provider in
                let priority = await provider.getPriority()
                let expectedAmount = await provider.getState().quote?.expectAmount ?? 0
                return (priority, expectedAmount)
            }
        )
    }

    private func filterAndMapProviders(
        _ providers: [ExpressAvailableProvider],
        selectedProvider: ExpressAvailableProvider?
    ) async -> [ProviderRowViewModel] {
        await providers.asyncCompactMap { provider in
            guard provider.isAvailable else {
                return nil
            }

            // If the provider `isSelected` we are forced to show it anyway
            let isSelected = selectedProvider?.provider.id == provider.provider.id
            let isAvailableToShow = await provider.getState().isAvailableToShow

            guard isSelected || isAvailableToShow else {
                return nil
            }

            return await mapToProviderRowViewModel(provider: provider, selectedProvider: selectedProvider)
        }
    }

    @MainActor
    private func showFCAWarningIfNeeded(allProviders: [ExpressAvailableProvider]) {
        let allProviderIds = allProviders.map { $0.provider.id }

        // Display FCA notification if the providers list contains FCA restriction for any provider
        let isRestrictableFCAIncluded = allProviderIds.contains(where: {
            ExpressConstants.expressProvidersFCAWarningList.contains($0)
        })

        if ukGeoDefiner.isUK, isRestrictableFCAIncluded {
            ukNotificationInput = NotificationsFactory().buildNotificationInput(for: ExpressProvidersListEvent.fcaWarningList)
        } else {
            ukNotificationInput = nil
        }
    }

    private func userDidTap(provider: ExpressAvailableProvider) {
        // Cancel subscription that view do not jump
        stateSubscription?.cancel()
        Analytics.log(event: .swapProviderChosen, params: [.provider: provider.provider.name])
        expressInteractor.updateProvider(provider: provider)
        coordinator?.closeExpressProvidersSelector()
    }
}

private extension ExpressProviderManagerState {
    var isPermissionRequired: Bool {
        switch self {
        case .permissionRequired:
            return true
        default:
            return false
        }
    }

    var isAvailableToShow: Bool {
        switch self {
        case .error:
            return false
        default:
            return true
        }
    }
}
