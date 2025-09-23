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

    private lazy var onrampOfferViewModelBuilder = OnrampOfferViewModelBuilder(tokenItem: tokenItem)
    private lazy var onrampProvidersItemViewModelBuilder = OnrampProviderItemViewModelBuilder(tokenItem: tokenItem)
    private weak var input: OnrampProvidersInput?
    private weak var output: OnrampOutput?

    init(tokenItem: TokenItem, input: OnrampProvidersInput, output: OnrampOutput) {
        self.tokenItem = tokenItem
        self.input = input
        self.output = output

        bind()
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
                    .sorted { $0.paymentMethod.type.priority > $1.paymentMethod.type.priority }
                    .filter { $0.hasSuccessfullyLoadedProviders() }
            }
            .receiveOnMain()
            .assign(to: &$providersList)
    }

    func mapToOnrampPaymentMethodRowViewData(providers: ProvidersList) -> [OnrampProviderItemViewModel] {
        providers.map { providerItem in
            onrampProvidersItemViewModelBuilder.mapToOnrampProviderItemViewModel(
                providerItem: providerItem
            ) { [weak self] in
                self?.selectedProviderItem = providerItem
            }
        }
    }

    func mapToOnrampOfferViewModels(item: ProviderItem) -> [OnrampOfferViewModel] {
        let offers = item.successfullyLoadedProviders().map { provider in
            onrampOfferViewModelBuilder.mapToOnrampOfferViewModel(provider: provider) { [weak self] in
                self?.close()
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
    }
}
