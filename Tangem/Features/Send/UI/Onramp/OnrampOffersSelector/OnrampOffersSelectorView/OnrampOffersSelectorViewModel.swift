//
//  OnrampOffersSelectorViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemUI
import TangemExpress

class OnrampOffersSelectorViewModel: ObservableObject, Identifiable, FloatingSheetContentViewModel {
    @Injected(\.floatingSheetPresenter)
    private var floatingSheetPresenter: any FloatingSheetPresenter

    var viewState: ViewState {
        switch selectedProviderItem {
        case .some(let item):
            return .offers(mapToOnrampOfferViewModels(item: item))
        case .none:
            return .paymentMethods(mapToOnrampPaymentMethodRowViewData(providers: providersList))
        }
    }

    @Published private var providersList: ProvidersList = []
    @Published private var selectedProviderItem: ProviderItem?

    private let tokenItem: TokenItem
    private let analyticsLogger: SendOnrampOffersAnalyticsLogger
    private var shouldOnrampPaymentMethodScreenOpenedLogged: Bool = true

    private lazy var onrampOfferViewModelBuilder = OnrampAllOfferViewModelBuilder(tokenItem: tokenItem)
    private lazy var onrampProvidersItemViewModelBuilder = OnrampProviderItemViewModelBuilder(tokenItem: tokenItem)
    private weak var input: OnrampProvidersInput?
    private weak var output: OnrampSummaryOutput?

    init(
        tokenItem: TokenItem,
        analyticsLogger: SendOnrampOffersAnalyticsLogger,
        input: OnrampProvidersInput,
        output: OnrampSummaryOutput,
    ) {
        self.tokenItem = tokenItem
        self.analyticsLogger = analyticsLogger
        self.input = input
        self.output = output

        bind()
    }

    /// Because floating sheet use sheet content twice
    /// then `onAppear` calls twice too
    func onAppear() {
        if shouldOnrampPaymentMethodScreenOpenedLogged {
            analyticsLogger.logOnrampPaymentMethodScreenOpened()
            shouldOnrampPaymentMethodScreenOpenedLogged = false
        }
    }

    func onDisappear() {
        selectedProviderItem = nil
    }

    func back() {
        selectedProviderItem = nil
    }

    func close() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}

// MARK: - Private

private extension OnrampOffersSelectorViewModel {
    func bind() {
        input?.onrampProvidersPublisher
            .compactMap { $0?.value }
            .map { providers in
                providers
                    .sortedByFirstItem(sorter: ProviderItemSorterByPaymentMethodPriority())
                    .filter { $0.hasSelectableProviders() }
            }
            .receiveOnMain()
            .assign(to: &$providersList)
    }

    func mapToOnrampPaymentMethodRowViewData(providers: ProvidersList) -> [OnrampProviderItemViewModel] {
        providers.map { providerItem in
            onrampProvidersItemViewModelBuilder.mapToOnrampProviderItemViewModel(
                providerItem: providerItem
            ) { [weak self] in
                self?.analyticsLogger.logOnrampPaymentMethodChosen(paymentMethod: providerItem.paymentMethod)
                self?.analyticsLogger.logOnrampProvidersScreenOpened()
                self?.selectedProviderItem = providerItem
            }
        }
    }

    func mapToOnrampOfferViewModels(item: ProviderItem) -> [OnrampOfferViewModel] {
        let offers = item.selectableProviders().map { provider in
            onrampOfferViewModelBuilder.mapToOnrampOfferViewModel(provider: provider) { [weak self] in
                self?.close()
                self?.analyticsLogger.logOnrampProviderChosen(provider: provider.provider)
                self?.analyticsLogger.logOnrampOfferButtonBuy(provider: provider)
                self?.output?.userDidRequestOnramp(provider: provider)
            }
        }

        return offers
    }
}

extension OnrampOffersSelectorViewModel {
    enum ViewState: Hashable {
        case paymentMethods([OnrampProviderItemViewModel])
        case offers([OnrampOfferViewModel])

        var isPaymentMethods: Bool {
            switch self {
            case .offers: false
            case .paymentMethods: true
            }
        }
    }
}
