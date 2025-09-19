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

    @Published private(set) var viewState: ViewState = .paymentMethods
    @Published private(set) var paymentMethods: [OnrampProviderItemViewModel] = []

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

    func back() {
        viewState = .paymentMethods
    }

    func close() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
            viewState = .paymentMethods
        }
    }
}

// MARK: - Private

private extension OnrampOffersSelectorViewModel {
    func bind() {
        input?.onrampProvidersPublisher
            .compactMap { $0?.value }
            .withWeakCaptureOf(self)
            .map { $0.mapToOnrampPaymentMethodRowViewData(providers: $1) }
            .receiveOnMain()
            .assign(to: &$paymentMethods)
    }

    func mapToOnrampPaymentMethodRowViewData(providers: ProvidersList) -> [OnrampProviderItemViewModel] {
        providers
            .filter { $0.hasSuccessfullyLoadedProviders() }
            .map { providerItem in
                onrampProvidersItemViewModelBuilder.mapToOnrampProviderItemViewModel(
                    providerItem: providerItem
                ) { [weak self] in
                    self?.updateViewState(item: providerItem)
                }
            }
    }

    func updateViewState(item: ProviderItem) {
        let offers = item.successfullyLoadedProviders().map { provider in
            onrampOfferViewModelBuilder.mapToOnrampOfferViewModel(provider: provider) { [weak self] in
                self?.close()
                self?.output?.userDidRequestOnramp(provider: provider)
            }
        }

        viewState = .providers(offers)
    }
}

extension OnrampOffersSelectorViewModel {
    enum ViewState: Hashable {
        case paymentMethods
        case providers([OnrampOfferViewModel])
    }
}
