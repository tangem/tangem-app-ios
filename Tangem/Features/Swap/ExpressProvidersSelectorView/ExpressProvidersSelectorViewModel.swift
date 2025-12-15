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
    private let expressRepository: ExpressRepository
    private let expressInteractor: ExpressInteractor
    private weak var coordinator: ExpressProvidersSelectorRoutable?

    init(
        priceChangeFormatter: PriceChangeFormatter,
        expressProviderFormatter: ExpressProviderFormatter,
        expressRepository: ExpressRepository,
        expressInteractor: ExpressInteractor,
        coordinator: ExpressProvidersSelectorRoutable
    ) {
        self.priceChangeFormatter = priceChangeFormatter
        self.expressProviderFormatter = expressProviderFormatter
        self.expressRepository = expressRepository
        self.expressInteractor = expressInteractor
        self.coordinator = coordinator

        bind()
    }

    func userDidTap(provider: ExpressAvailableProvider) {
        Analytics.log(event: .swapProviderChosen, params: [.provider: provider.provider.name])
        expressInteractor.updateProvider(provider: provider)
        coordinator?.closeExpressProvidersSelector()
    }
}

// MARK: - Private Implementation

extension ExpressProvidersSelectorViewModel {
    func bind() {
        expressInteractor.providersPublisher()
            .withWeakCaptureOf(self)
            .map { $0.mapToFCAWarningIfNeeded(providers: $1) }
            .receiveOnMain()
            .assign(to: &$ukNotificationInput)

        Publishers.CombineLatest(
            expressInteractor.providersPublisher(),
            expressInteractor.selectedProviderPublisher()
        )
        .withWeakCaptureOf(self)
        .asyncMap { await $0.mapToProviderRowViewModels(providers: $1.0, selectedProvider: $1.1) }
        .receiveOnMain()
        .assign(to: &$providerViewModels)
    }

    func mapToFCAWarningIfNeeded(
        providers: [ExpressAvailableProvider]
    ) -> NotificationViewInput? {
        let allProviderIds = providers.map { $0.provider.id }

        // Display FCA notification if the providers list contains FCA restriction for any provider
        let isRestrictableFCAIncluded = allProviderIds.contains(where: {
            ExpressConstants.expressProvidersFCAWarningList.contains($0)
        })

        guard ukGeoDefiner.isUK, isRestrictableFCAIncluded else {
            return nil
        }

        return NotificationsFactory().buildNotificationInput(for: ExpressProvidersListEvent.fcaWarningList)
    }

    func mapToProviderRowViewModels(
        providers: [ExpressAvailableProvider],
        selectedProvider: ExpressAvailableProvider?
    ) async -> [ProviderRowViewModel] {
        await providers
            .showableProviders(selectedProviderId: selectedProvider?.provider.id)
            .sortedByPriorityAndQuotes()
            .asyncMap { await mapToProviderRowViewModel(provider: $0, selectedProvider: selectedProvider) }
    }

    func mapToProviderRowViewModel(
        provider: ExpressAvailableProvider,
        selectedProvider: ExpressAvailableProvider?
    ) async -> ProviderRowViewModel {
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

    func makePercentSubtitle(
        provider: ExpressAvailableProvider,
        selectedProvider: ExpressAvailableProvider?
    ) async -> ProviderRowViewModel.Subtitle? {
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
