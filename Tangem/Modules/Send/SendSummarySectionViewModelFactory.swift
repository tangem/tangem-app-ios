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

    func makeDestinationViewData(address: String) -> SendDestinationSummaryViewData? {
        return SendDestinationSummaryViewData(address: address)
    }

    func makeAmountViewData(from amount: String?, amountAlternative: String?) -> SendAmountSummaryViewData? {
        guard let amount, let amountAlternative else { return nil }

        return SendAmountSummaryViewData(
            title: Localization.sendAmountLabel,
            amount: amount,
            amountAlternative: amountAlternative,
            tokenIconInfo: tokenIconInfo
        )
    }

    func makeFeeViewData(from value: Fee?, feeOption: FeeOption, animateTitleOnAppear: Bool) -> SendFeeSummaryViewModel? {
        guard let value else { return nil }

        let formattedFeeComponents = feeFormatter.formattedFeeComponents(
            fee: value.amount.value,
            currencySymbol: feeCurrencySymbol,
            currencyId: feeCurrencyId,
            isFeeApproximate: isFeeApproximate
        )

        return SendFeeSummaryViewModel(
            title: Localization.commonNetworkFeeTitle,
            feeOption: feeOption,
            cryptoAmount: formattedFeeComponents.cryptoFee,
            fiatAmount: formattedFeeComponents.fiatFee,
            animateTitleOnAppear: animateTitleOnAppear
        )
    }
}
