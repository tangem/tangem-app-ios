//
//  TangemPayOrderCardTypeViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemLocalization
import TangemPay

final class TangemPayOrderCardTypeViewModel: ObservableObject, Identifiable {
    @Published var selectedCardType: TangemPayOrderCardType
    @Published private var availableBalance: Decimal?

    let cardTypes: [TangemPayOrderCardType]
    let isBasicTariff: Bool

    var isSelectEnabled: Bool {
        switch selectedCardType {
        case .virtual:
            true
        case .plastic:
            switch plasticDeliveryState {
            case .available, .firstDeliveryFree: true
            case .countryUnavailable, .insufficientFunds: false
            }
        }
    }

    var infoRows: [TangemPayOrderCardInfoRow] {
        switch selectedCardType {
        case .virtual: virtualRows
        case .plastic: plasticRows
        }
    }

    private let virtualOffer: TangemPayCustomerOffer?
    private let plasticOffer: TangemPayCustomerOffer?
    private let tariffPlanCardImageURL: URL?
    private let countryName: String?
    private let fiatAmountFormatter = TangemPayFiatAmountFormatter()
    private weak var coordinator: TangemPayOrderCardTypeRoutable?
    private var bag = Set<AnyCancellable>()
    private var didLogInsufficientFunds = false

    init(
        virtualOffer: TangemPayCustomerOffer?,
        plasticOffer: TangemPayCustomerOffer?,
        tariffPlanCardImageURL: URL?,
        isBasicTariff: Bool,
        availableBalancePublisher: some Publisher<Decimal?, Never>,
        countryName: String?,
        selectedCardType: TangemPayOrderCardType?,
        coordinator: TangemPayOrderCardTypeRoutable?
    ) {
        let cardTypes = TangemPayOrderCardType.allCases.filter { type in
            switch type {
            case .virtual: virtualOffer?.fee != nil
            case .plastic: FeatureProvider.isAvailable(.tangemPayPlastic)
            }
        }

        self.cardTypes = cardTypes
        self.isBasicTariff = isBasicTariff
        self.virtualOffer = virtualOffer
        self.plasticOffer = plasticOffer
        self.tariffPlanCardImageURL = tariffPlanCardImageURL
        self.countryName = countryName
        self.coordinator = coordinator

        let preselected = selectedCardType.flatMap { cardTypes.contains($0) ? $0 : nil }
        self.selectedCardType = preselected ?? cardTypes.first ?? .virtual

        availableBalancePublisher
            .receiveOnMain()
            .assign(to: \.availableBalance, on: self, ownership: .weak)
            .store(in: &bag)

        Analytics.log(.visaPlasticCardTypeSelectionScreenOpened)
        bindInsufficientFundsAnalytics()
    }

    func imageURL(for cardType: TangemPayOrderCardType) -> URL? {
        switch cardType {
        case .virtual: tariffPlanCardImageURL
        case .plastic: plasticOffer?.mainImageURL ?? tariffPlanCardImageURL
        }
    }

    func select() {
        switch selectedCardType {
        case .virtual:
            Analytics.log(.visaPlasticVirtualSelectClicked)
            coordinator?.orderCardTypeDidSelectVirtual()
        case .plastic:
            Analytics.log(.visaPlasticPlasticSelectClicked)
            coordinator?.orderCardTypeDidSelectPlastic()
        }
    }

    func onCardTypeTabTapped(_ cardType: TangemPayOrderCardType) {
        switch cardType {
        case .virtual: Analytics.log(.visaPlasticVirtualTypeClicked)
        case .plastic: Analytics.log(.visaPlasticPlasticTypeClicked)
        }

        selectedCardType = cardType
    }

    func onCardTypeSwiped(_ cardType: TangemPayOrderCardType) {
        guard selectedCardType != cardType else { return }

        Analytics.log(.visaPlasticCardTypeSwiped)
        selectedCardType = cardType
    }

    func close() {
        coordinator?.closeOrderCardType()
    }
}

// MARK: - Offer

private extension TangemPayOrderCardTypeViewModel {
    var deliveryEtaMaxDays: Int? {
        plasticOffer?.data?.deliveryEtaMaxDays
    }

    var plasticDeliveryState: TangemPayPlasticDeliveryState {
        plasticDeliveryState(availableBalance: availableBalance)
    }

    func plasticDeliveryState(availableBalance: Decimal?) -> TangemPayPlasticDeliveryState {
        guard let fee = plasticOffer?.fee, deliveryEtaMaxDays != nil else {
            return .countryUnavailable
        }

        if fee.amount == 0 {
            return .firstDeliveryFree
        }

        if let availableBalance, availableBalance < fee.amount {
            return .insufficientFunds
        }

        return .available
    }

    func formatted(_ fee: TangemPayCustomerOffer.Fee) -> String {
        fiatAmountFormatter.format(
            fee.amount,
            currencyCode: fee.currency,
            hidesFractionForWholeAmounts: true
        )
    }
}

// MARK: - Rows

private extension TangemPayOrderCardTypeViewModel {
    var virtualRows: [TangemPayOrderCardInfoRow] {
        [
            TangemPayOrderCardInfoRow(
                id: .issueFee,
                title: Localization.tangempayOrderTypeIssueFee,
                value: virtualOffer?.fee.map(formatted) ?? Constants.unknownValue
            ),
            TangemPayOrderCardInfoRow(
                id: .issueTime,
                title: Localization.tangempayOrderTypeDeliveryTime,
                value: Localization.tangempayOrderTypeDeliveryTimeInstant
            ),
        ]
    }

    var plasticRows: [TangemPayOrderCardInfoRow] {
        [deliverToRow, deliveryFeeRow, deliveryTimeRow]
    }

    var deliverToRow: TangemPayOrderCardInfoRow {
        TangemPayOrderCardInfoRow(
            id: .deliverTo,
            title: Localization.tangempayOrderTypeDeliveryTo,
            value: countryName ?? Constants.unknownValue,
            subvalue: Localization.tangempayOrderTypeCountryOfResidence,
            badge: isCountryUnavailable ? .init(text: Localization.tangempayOrderTypeUnavailable, appearance: .warning) : nil
        )
    }

    var deliveryFeeRow: TangemPayOrderCardInfoRow {
        TangemPayOrderCardInfoRow(
            id: .deliveryFee,
            title: Localization.tangempayOrderTypeDeliveryFee,
            value: deliveryFeeText,
            badge: deliveryFeeBadge,
            isDimmed: isCountryUnavailable
        )
    }

    var deliveryTimeRow: TangemPayOrderCardInfoRow {
        TangemPayOrderCardInfoRow(
            id: .deliveryTime,
            title: Localization.tangempayOrderTypeDeliveryTime,
            value: deliveryTime,
            isDimmed: isCountryUnavailable
        )
    }

    var deliveryFeeText: String? {
        guard let fee = plasticOffer?.fee, !isCountryUnavailable else {
            return Constants.unknownValue
        }

        return plasticDeliveryState == .firstDeliveryFree ? nil : formatted(fee)
    }

    var deliveryTime: String {
        guard let deliveryEtaMaxDays else {
            return Constants.unknownValue
        }

        guard let minDays = plasticOffer?.data?.deliveryEtaMinDays else {
            return Localization.tangempayOrderTypeDeliveryEta(deliveryEtaMaxDays)
        }

        return Localization.tangempayOrderTypeDeliveryEtaRange(minDays, deliveryEtaMaxDays)
    }

    var deliveryFeeBadge: TangemPayOrderCardInfoRow.Badge? {
        switch plasticDeliveryState {
        case .available, .countryUnavailable:
            nil
        case .firstDeliveryFree:
            .init(text: Localization.tangempayOrderTypeFirstDeliveryFree, appearance: .success)
        case .insufficientFunds:
            .init(text: Localization.tangempayOrderTypeNotEnoughMoney, appearance: .warning)
        }
    }

    var isCountryUnavailable: Bool {
        plasticDeliveryState == .countryUnavailable
    }
}

// MARK: - Analytics

private extension TangemPayOrderCardTypeViewModel {
    /// Reads the emitted values, not the properties: `@Published` fires in `willSet`, so both are
    /// still stale here.
    func bindInsufficientFundsAnalytics() {
        Publishers.CombineLatest($selectedCardType, $availableBalance)
            .withWeakCaptureOf(self)
            .sink { viewModel, input in
                let (cardType, availableBalance) = input

                guard cardType == .plastic,
                      viewModel.plasticDeliveryState(availableBalance: availableBalance) == .insufficientFunds
                else {
                    return
                }

                viewModel.logInsufficientFundsOnce()
            }
            .store(in: &bag)
    }

    /// Once per screen: the badge reappears on every tab switch and on a balance republish without a
    /// cache, and those are not separate impressions.
    func logInsufficientFundsOnce() {
        guard !didLogInsufficientFunds else { return }

        didLogInsufficientFunds = true
        Analytics.log(.visaPlasticDeliveryCostNotEnoughMoneyShowed)
    }
}

// MARK: - Constants

private extension TangemPayOrderCardTypeViewModel {
    enum Constants {
        static let unknownValue = "—"
    }
}
