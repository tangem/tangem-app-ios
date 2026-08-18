//
//  TangemPayOrderCardTypeViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

final class TangemPayOrderCardTypeViewModel: ObservableObject, Identifiable {
    @Published var selectedCardType: TangemPayOrderCardType

    let cardTypes: [TangemPayOrderCardType] = TangemPayOrderCardType.allCases
    let virtualCardImageURL: URL?

    var isSelectEnabled: Bool {
        switch selectedCardType {
        case .virtual: true
        case .plastic: plasticDeliveryState != .countryUnavailable
        }
    }

    var infoRows: [TangemPayOrderCardInfoRow] {
        switch selectedCardType {
        case .virtual: virtualRows
        case .plastic: plasticRows
        }
    }

    private let issueFeeText: String
    private let plasticDeliveryState: TangemPayPlasticDeliveryState
    private weak var coordinator: TangemPayOrderCardTypeRoutable?

    init(
        issueFeeText: String,
        virtualCardImageURL: URL?,
        selectedCardType: TangemPayOrderCardType = .virtual,
        plasticDeliveryState: TangemPayPlasticDeliveryState = .available,
        coordinator: TangemPayOrderCardTypeRoutable?
    ) {
        self.issueFeeText = issueFeeText
        self.virtualCardImageURL = virtualCardImageURL
        self.selectedCardType = selectedCardType
        self.plasticDeliveryState = plasticDeliveryState
        self.coordinator = coordinator
    }

    func select() {
        switch selectedCardType {
        case .virtual:
            coordinator?.orderCardTypeDidSelectVirtual()
        case .plastic:
            break
        }
    }

    func close() {
        coordinator?.closeOrderCardType()
    }
}

// MARK: - Rows

private extension TangemPayOrderCardTypeViewModel {
    var virtualRows: [TangemPayOrderCardInfoRow] {
        [
            TangemPayOrderCardInfoRow(
                id: .issueFee,
                title: Localization.tangempayOrderTypeIssueFee,
                value: issueFeeText
            ),
            TangemPayOrderCardInfoRow(
                id: .issueTime,
                title: Constants.issueTimeTitle,
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
            value: countryOfResidence,
            subvalue: Constants.countryOfResidence,
            badge: isCountryUnavailable ? .init(text: Constants.unavailableBadge, appearance: .warning) : nil
        )
    }

    var deliveryFeeRow: TangemPayOrderCardInfoRow {
        TangemPayOrderCardInfoRow(
            id: .deliveryFee,
            title: Localization.tangempayOrderTypeDeliveryFee,
            value: isCountryUnavailable ? Constants.unknownValue : Constants.deliveryFee,
            badge: deliveryFeeBadge,
            isValueStruckThrough: plasticDeliveryState == .firstDeliveryFree,
            isDimmed: isCountryUnavailable
        )
    }

    var deliveryTimeRow: TangemPayOrderCardInfoRow {
        TangemPayOrderCardInfoRow(
            id: .deliveryTime,
            title: Localization.tangempayOrderTypeDeliveryTime,
            value: isCountryUnavailable ? Constants.unknownValue : Constants.deliveryTime,
            isDimmed: isCountryUnavailable
        )
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

    // [REDACTED_TODO_COMMENT]
    var countryOfResidence: String {
        guard let region = Locale.current.region,
              let name = Locale.current.localizedString(forRegionCode: region.identifier)
        else {
            return Constants.unknownValue
        }

        return name
    }
}

// MARK: - Constants

private extension TangemPayOrderCardTypeViewModel {
    enum Constants {
        static let unknownValue = "—"

        // [REDACTED_TODO_COMMENT]
        static let issueTimeTitle = "Issue time"
        static let countryOfResidence = "Country of residence"
        static let unavailableBadge = "Unavailable"
        static let deliveryTime = "3–5 business days"

        // [REDACTED_TODO_COMMENT]
        static let deliveryFee = "$10"
    }
}
