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

    private var allProviders: [ExpressAvailableProvider] = []
    private var selectedProvider: ExpressAvailableProvider?

    private let percentFormatter: PercentFormatter
    private let expressProviderFormatter: ExpressProviderFormatter
    private let expressRepository: ExpressRepository
    private unowned let expressInteractor: ExpressInteractor
    private unowned let coordinator: ExpressProvidersBottomSheetRoutable

    private var stateSubscription: AnyCancellable?

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
        allProviders = await expressInteractor.getAllProviders().sorted(by: { lhs, rhs in
            return lhs.isBest || lhs.isAvailable
        })

        selectedProvider = await expressInteractor.getSelectedProvider()
    }

    func setupProviderRowViewModels() async {
        for provider in allProviders {
            guard provider.isAvailable else {
                await runOnMain {
                    providerViewModels.append(unavailableProviderRowViewModel(provider: provider.provider))
                }

                return
            }

            if await provider.getState().isAvailableToShow {
                let viewModel = await mapToProviderRowViewModel(provider: provider)
                await runOnMain {
                    providerViewModels.append(viewModel)
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
        let badge: ProviderRowViewModel.Badge? = {
            if state.isPermissionRequired {
                return .permissionNeeded
            }

            return provider.isBest ? .bestRate : .none
        }()

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
        // Cancel subscription that view do not jump
        stateSubscription?.cancel()
        Analytics.log(event: .swapProviderChosen, params: [.provider: provider.provider.name])
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
