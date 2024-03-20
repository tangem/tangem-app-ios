//
//  SendSummarySectionViewModelFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct SendSummarySectionViewModelFactory {
    private let feeCurrencySymbol: String
    private let feeCurrencyId: String
    private let isFeeApproximate: Bool
    private let currencyId: String?
    private let tokenIconInfo: TokenIconInfo

    private var feeFormatter: FeeFormatter {
        CommonFeeFormatter(
            balanceFormatter: BalanceFormatter(),
            balanceConverter: BalanceConverter()
        )
    }

    init(feeCurrencySymbol: String, feeCurrencyId: String, isFeeApproximate: Bool, currencyId: String?, tokenIconInfo: TokenIconInfo) {
        self.feeCurrencySymbol = feeCurrencySymbol
        self.feeCurrencyId = feeCurrencyId
        self.isFeeApproximate = isFeeApproximate
        self.currencyId = currencyId
        self.tokenIconInfo = tokenIconInfo
    }

    func makeDestinationViewTypes(address: String, additionalField: (SendAdditionalFields, String)?) -> [SendDestinationSummaryViewType] {
        var destinationViewTypes: [SendDestinationSummaryViewType] = [
            .address(address: address),
        ]

        if let (additionalFieldType, additionalFieldValue) = additionalField {
            destinationViewTypes.append(.additionalField(type: additionalFieldType, value: additionalFieldValue))
        }

        return destinationViewTypes
    }

    func makeAmountViewData(from amount: Amount?, useFiatCalculation: Bool) -> SendAmountSummaryViewData? {
        guard let amount else { return nil }

        let amountCryptoFormatted = amount.description

        let amountFiatFormatted: String
        if let currencyId,
           let fiatValue = BalanceConverter().convertToFiat(value: amount.value, from: currencyId) {
            amountFiatFormatted = BalanceFormatter().formatFiatBalance(fiatValue)
        } else {
            amountFiatFormatted = AppConstants.dashSign
        }

        let amountFormatted = useFiatCalculation ? amountFiatFormatted : amountCryptoFormatted
        let amountAlternativeFormatted = useFiatCalculation ? amountCryptoFormatted : amountFiatFormatted

        return SendAmountSummaryViewData(
            title: Localization.sendAmountLabel,
            amount: amountFormatted,
            amountAlternative: amountAlternativeFormatted,
            tokenIconInfo: tokenIconInfo
        )
    }

    func makeFeeViewData(from value: Fee?) -> SendFeeSummaryViewData? {
        guard let value else { return nil }

        let formattedFeeComponents = feeFormatter.formattedFeeComponents(
            fee: value.amount.value,
            currencySymbol: feeCurrencySymbol,
            currencyId: feeCurrencyId,
            isFeeApproximate: isFeeApproximate
        )

        return SendFeeSummaryViewData(
            title: Localization.commonNetworkFeeTitle,
            feeOption: .market,
            cryptoAmount: formattedFeeComponents.cryptoFee,
            fiatAmount: formattedFeeComponents.fiatFee
        )
    }
}
