//
//  OnrampOffersSelectorViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import PassKit
import TangemUI
import TangemExpress
import SwiftUI

class OnrampOffersSelectorViewModel: ObservableObject, Identifiable, FloatingSheetContentViewModel {
    @Injected(\.floatingSheetPresenter)
    private var floatingSheetPresenter: any FloatingSheetPresenter

    @Injected(\.geoEligibilityService) private var geoEligibilityService: GeoEligibilityService

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
            let buyAction = makeBuyAction(provider: provider) { [weak self] in
                self?.close()
                self?.analyticsLogger.logOnrampProviderChosen(provider: provider.provider)
                self?.analyticsLogger.logOnrampOfferButtonBuy(provider: provider)
            }

            return onrampOfferViewModelBuilder.mapToOnrampOfferViewModel(provider: provider, buyAction: buyAction)
        }

        return offers
    }

    func makeBuyAction(provider: OnrampProvider, additionalAnalytics: @escaping () -> Void) -> OnrampOfferViewModel.BuyAction {
        if geoEligibilityService.isApplePayAllowed,
           provider.paymentMethod.type == .applePay,
           provider.quote?.nativePaymentAvailable == true,
           let amount = provider.amount,
           let currencyCode = input?.selectedOnrampProvider?.paymentMethod {
            // Get currency code from the provider's pair item
            if let code = try? provider.makeOnrampQuotesRequestItem().pairItem.fiatCurrency.identity.code {
                let request = OnrampApplePayUtils.makePaymentRequest(amount: amount, currencyCode: code)
                return .nativeApplePay(request: request) { [weak self] (phase: PayWithApplePayButtonPaymentAuthorizationPhase) in
                    switch phase {
                    case .willAuthorize:
                        additionalAnalytics()
                    case .didAuthorize(let payment, let resultHandler):
                        let applePayResult = OnrampApplePayUtils.mapPaymentResult(payment)
                        resultHandler(.init(status: .success, errors: nil))
                        self?.output?.userDidAuthorizeNativePayment(provider: provider, applePayResult: applePayResult)
                    case .didFinish:
                        break
                    @unknown default:
                        break
                    }
                }
            }
        }

        return .button { [weak self] in
            additionalAnalytics()
            self?.output?.userDidRequestOnramp(provider: provider)
        }
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
