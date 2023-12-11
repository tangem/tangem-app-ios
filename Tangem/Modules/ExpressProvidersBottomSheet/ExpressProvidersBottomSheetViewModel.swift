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

    private var allProviders: [ExpressProvider] = []
    private var availableProviders: [ExpressAvailableProvider] = []
    private var selectedProvider: ExpressAvailableProvider?

    private let percentFormatter: PercentFormatter
    private let expressProviderFormatter: ExpressProviderFormatter
    private let expressRepository: ExpressRepository
    private unowned let expressInteractor: ExpressInteractor
    private unowned let coordinator: ExpressProvidersBottomSheetRoutable

    private var bag: Set<AnyCancellable> = []

    init(
        percentFormatter: PercentFormatter,
        expressProviderFormatter: ExpressProviderFormatter,
        expressRepository: ExpressRepository,
        expressInteractor: ExpressInteractor,
        coordinator: ExpressProvidersBottomSheetRoutable
    ) {
        self.percentFormatter = percentFormatter
        self.expressProviderFormatter = expressProviderFormatter
        self.expressRepository = expressRepository
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
            do {
                try await viewModel.updateProviderRowViewModels()
            } catch {
                // [REDACTED_TODO_COMMENT]
            }
        }
    }

    func updateProviderRowViewModels() async throws {
        allProviders = try await expressRepository.providers()
        availableProviders = await expressInteractor.getAvailableProviders()
        selectedProvider = await expressInteractor.getSelectedProvider()

        for provider in allProviders {
            if let available = availableProviders.first(where: { $0.provider == provider }) {
                if await available.getState().isAvailableToShow {
                    let viewModel = await mapToProviderRowViewModel(provider: available)
                    await runOnMain {
                        providerViewModels.append(viewModel)
                    }
                }
            } else {
                await runOnMain {
                    providerViewModels.append(unavailableProviderRowViewModel(provider: provider))
                }
            }
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
        if !isSelected, let quote = state.quote, let percentSubtitle = await makePercentSubtitle(quote: quote) {
            subtitles.append(percentSubtitle)
        }

        return ProviderRowViewModel(
            provider: expressProviderFormatter.mapToProvider(provider: provider.provider),
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
            isDisabled: true,
            badge: .none,
            subtitles: [.text(Localization.expressProviderNotAvailable)],
            detailsType: .none,
            tapAction: {}
        )
    }

    func userDidTap(provider: ExpressAvailableProvider) {
        Analytics.log(event: .swapProviderChosen, params: [.provider: provider.provider.name])

        selectedProvider = provider
        expressInteractor.updateProvider(provider: provider)
        coordinator.closeExpressProvidersBottomSheet()
    }

    func makePercentSubtitle(quote: ExpressQuote) async -> ProviderRowViewModel.Subtitle? {
        guard let selectedRate = await selectedProvider?.getState().quote?.rate else {
            return nil
        }

        let changePercent = 1 - selectedRate / quote.rate
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
