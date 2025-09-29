//
//  OnrampProvidersViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemLocalization
import SwiftUI
import TangemExpress

final class OnrampProvidersViewModel: ObservableObject {
    @Injected(\.ukGeoDefiner) private var ukGeoDefiner: UKGeoDefiner

    // MARK: - ViewState

    @Published var paymentViewData: OnrampProvidersPaymentViewData?
    @Published var providersViewData: [OnrampProviderRowViewData] = []
    @Published var selectedProviderID: Int?

    // MARK: - Dependencies

    private let tokenItem: TokenItem
    private let interactor: OnrampProvidersInteractor
    private let analyticsLogger: SendOnrampProvidersAnalyticsLogger
    private weak var coordinator: OnrampProvidersRoutable?

    private let priceChangeFormatter = PriceChangeFormatter()
    private let balanceFormatter = BalanceFormatter()

    private var bag: Set<AnyCancellable> = []

    init(
        tokenItem: TokenItem,
        interactor: OnrampProvidersInteractor,
        analyticsLogger: SendOnrampProvidersAnalyticsLogger,
        coordinator: OnrampProvidersRoutable
    ) {
        self.tokenItem = tokenItem
        self.interactor = interactor
        self.analyticsLogger = analyticsLogger
        self.coordinator = coordinator

        bind()
    }

    func onAppear() {
        analyticsLogger.logOnrampProvidersScreenOpened()
    }

    func closeView() {
        coordinator?.closeOnrampProviders()
    }
}

// MARK: - Private

private extension OnrampProvidersViewModel {
    func bind() {
        Publishers.CombineLatest(
            interactor.providesPublisher,
            interactor.selectedProviderPublisher.compactMap { $0 }
        )
        .withWeakCaptureOf(self)
        .receiveOnMain()
        .sink { viewModel, args in
            let (providers, selected) = args
            viewModel.updateProvidersView(providers: providers, selectedProviderId: selected.provider.id)
            viewModel.updatePaymentView(payment: selected.paymentMethod)
        }
        .store(in: &bag)
    }

    func updatePaymentView(payment: OnrampPaymentMethod) {
        paymentViewData = .init(
            name: payment.name,
            iconURL: payment.image,
            action: { [weak self] in
                self?.coordinator?.openOnrampPaymentMethods()
            }
        )
    }

    func updateProvidersView(providers: [OnrampProvider], selectedProviderId: String) {
        var providersViewData: [OnrampProviderRowViewData] = []

        providers.forEach { provider in
            let rowData = OnrampProviderRowViewData(
                name: provider.provider.name,
                // Need to set here to that the action works correctly
                paymentMethodId: provider.paymentMethod.id,
                iconURL: provider.provider.imageURL,
                formattedAmount: formattedAmount(state: provider.state),
                state: state(state: provider.state),
                badge: badge(provider: provider),
                action: { [weak self] in
                    self?.userDidSelect(provider: provider)
                }
            )

            if selectedProviderId == provider.provider.id {
                self.selectedProviderID = rowData.id
            }

            providersViewData.append(rowData)
        }

        self.providersViewData = providersViewData
    }

    func userDidSelect(provider: OnrampProvider) {
        analyticsLogger.logOnrampProviderChosen(provider: provider.provider)
        interactor.update(selectedProvider: provider)
        coordinator?.closeOnrampProviders()
    }

    func badge(provider: OnrampProvider) -> OnrampProviderRowViewData.Badge? {
        switch provider.attractiveType {
        case .none:
            return .none
        case .best where ukGeoDefiner.isUK:
            return .none
        case .best:
            return .bestRate
        case .loss(let percent):
            let result = priceChangeFormatter.formatFractionalValue(percent, option: .express)
            return .percent(result.formattedText, signType: result.signType)
        }
    }

    func formattedAmount(state: OnrampProviderManagerState) -> String? {
        guard case .loaded(let onrampQuote) = state else {
            return nil
        }

        return balanceFormatter.formatCryptoBalance(
            onrampQuote.expectedAmount,
            currencyCode: tokenItem.currencySymbol
        )
    }

    func state(state: OnrampProviderManagerState) -> OnrampProviderRowViewData.State? {
        switch state {
        case .idle, .loading:
            return nil
        case .notSupported(.currentPair):
            // It's not to be showed
            return .unavailable(reason: Localization.expressProviderNotAvailable)
        case .notSupported(.paymentMethod(let supported)):
            let methods = supported.map(\.name).joined(separator: ", ")
            return .availableForPaymentMethods(methods: Localization.onrampAvaiableWithPaymentMethods(methods))
        case .loaded:
            return .available
        case .restriction(.tooSmallAmount(_, let formatted)):
            return .availableFromAmount(minAmount: Localization.onrampProviderMinAmount(formatted))
        case .restriction(.tooBigAmount(_, let formatted)):
            return .availableToAmount(maxAmount: Localization.onrampProviderMaxAmount(formatted))
        case .failed(let error as ExpressAPIError):
            return .unavailable(reason: error.localizedMessage)
        case .failed(let error):
            return .unavailable(reason: error.localizedDescription)
        }
    }
}
