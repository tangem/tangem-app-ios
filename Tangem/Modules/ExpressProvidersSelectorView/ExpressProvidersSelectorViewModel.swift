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

final class ExpressProvidersSelectorViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published var providerViewModels: [ProviderRowViewModel] = []

    // MARK: - Dependencies

    private var allProviders: [ExpressAvailableProvider] = []
    private var selectedProvider: ExpressAvailableProvider?

    private let percentFormatter: PercentFormatter
    private let expressProviderFormatter: ExpressProviderFormatter
    private let expressRepository: ExpressRepository
    private let expressInteractor: ExpressInteractor
    private weak var coordinator: ExpressProvidersSelectorRoutable?

    private var stateSubscription: AnyCancellable?

    init(
        percentFormatter: PercentFormatter,
        expressProviderFormatter: ExpressProviderFormatter,
        expressRepository: ExpressRepository,
        expressInteractor: ExpressInteractor,
        coordinator: ExpressProvidersSelectorRoutable
    ) {
        self.percentFormatter = percentFormatter
        self.expressProviderFormatter = expressProviderFormatter
        self.expressRepository = expressRepository
        self.expressInteractor = expressInteractor
        self.coordinator = coordinator

        bind()
        initialSetup()
    }

    func bind() {
        stateSubscription = expressInteractor.state
            .dropFirst()
            .compactMap { $0.quote }
            .removeDuplicates()
            .sink { [weak self] state in
                self?.updateView()
            }
    }

    func initialSetup() {
        runTask(in: self) { viewModel in
            try await viewModel.updateFields()
            await viewModel.setupProviderRowViewModels()
        }
    }

    func updateView() {
        runTask(in: self) { viewModel in
            await viewModel.setupProviderRowViewModels()
        }
    }

    func updateFields() async throws {
        allProviders = await expressInteractor.getAllProviders()
        selectedProvider = await expressInteractor.getSelectedProvider()
    }

    func setupProviderRowViewModels() async {
        let viewModels: [ProviderRowViewModel] = await allProviders
            .asyncSorted(sort: >, by: { await $0.getPriority() })
            .asyncCompactMap { provider in
                if !provider.isAvailable {
                    return unavailableProviderRowViewModel(provider: provider.provider)
                }

                // If the provider `isSelected` we are forced to show it anyway
                let isSelected = selectedProvider?.provider.id == provider.provider.id
                let isAvailableToShow = await provider.getState().isAvailableToShow

                guard isSelected || isAvailableToShow else {
                    return nil
                }

                return await mapToProviderRowViewModel(provider: provider)
            }

        await runOnMain {
            providerViewModels = viewModels
        }
    }

    func mapToProviderRowViewModel(provider: ExpressAvailableProvider) async -> ProviderRowViewModel {
        let senderCurrencyCode = expressInteractor.getSender().tokenItem.currencySymbol
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
        let badge: ProviderRowViewModel.Badge? = state.isPermissionRequired ? .permissionNeeded : .none

        if let percentSubtitle = await makePercentSubtitle(provider: provider) {
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

    func unavailableProviderRowViewModel(provider: ExpressProvider) -> ProviderRowViewModel {
        ProviderRowViewModel(
            provider: expressProviderFormatter.mapToProvider(provider: provider),
            titleFormat: .name,
            isDisabled: true,
            badge: .none,
            subtitles: [.text(Localization.expressProviderNotAvailable)],
            detailsType: .none,
            tapAction: {}
        )
    }

    func userDidTap(provider: ExpressAvailableProvider) {
        // Cancel subscription that view do not jump
        stateSubscription?.cancel()
        Analytics.log(event: .swapProviderChosen, params: [.provider: provider.provider.name])
        expressInteractor.updateProvider(provider: provider)
        coordinator?.closeExpressProvidersSelector()
    }

    func makePercentSubtitle(provider: ExpressAvailableProvider) async -> ProviderRowViewModel.Subtitle? {
        // For selectedProvider we don't add percent badge
        guard selectedProvider?.provider.id != provider.provider.id else {
            return nil
        }

        guard let quote = await provider.getState().quote,
              let selectedRate = await selectedProvider?.getState().quote?.rate else {
            return nil
        }

        let changePercent = quote.rate / selectedRate - 1
        let formatted = percentFormatter.expressRatePercentFormat(value: changePercent)

        return .percent(formatted, signType: ChangeSignType(from: changePercent))
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
