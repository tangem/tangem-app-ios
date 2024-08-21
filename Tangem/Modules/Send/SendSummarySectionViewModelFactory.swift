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
    private let feeCurrencyId: String?
    private let isFeeApproximate: Bool
    private let currencyId: String?
    private let tokenIconInfo: TokenIconInfo

    private var feeFormatter: FeeFormatter {
        CommonFeeFormatter(
            balanceFormatter: BalanceFormatter(),
            balanceConverter: BalanceConverter()
        )
    }

    init(feeCurrencySymbol: String, feeCurrencyId: String?, isFeeApproximate: Bool, currencyId: String?, tokenIconInfo: TokenIconInfo) {
        self.feeCurrencySymbol = feeCurrencySymbol
        self.feeCurrencyId = feeCurrencyId
        self.isFeeApproximate = isFeeApproximate
        self.currencyId = currencyId
        self.tokenIconInfo = tokenIconInfo
    }

    func makeDestinationViewTypes(address: String, additionalField: SendDestinationAdditionalField) -> [SendDestinationSummaryViewType] {
        var destinationViewTypes: [SendDestinationSummaryViewType] = []

        var addressCorners: UIRectCorner = .allCorners

        if case .filled(let type, let value, _) = additionalField {
            addressCorners = [.topLeft, .topRight]
            destinationViewTypes.append(.additionalField(type: type, value: value))
        }

        destinationViewTypes.insert(.address(address: address, corners: addressCorners), at: 0)

        return destinationViewTypes
    }

    func makeAmountViewData(amount: String?, amountAlternative: String?) -> SendAmountSummaryViewData {
        SendAmountSummaryViewData(
            title: Localization.sendAmountLabel,
            amount: amount,
            amountAlternative: amountAlternative,
            tokenIconInfo: tokenIconInfo
        )
    }

    func makeFeeViewData(from value: SendFee) -> SendFeeSummaryViewModel? {
        let formattedFeeComponents = formattedFeeComponents(from: value.value)
        return SendFeeSummaryViewModel(
            title: Localization.commonNetworkFeeTitle,
            feeOption: value.option,
            formattedFeeComponents: formattedFeeComponents
        )
    }

    func makeDeselectedFeeRowViewModel(from value: SendFee) -> FeeRowViewModel {
        return FeeRowViewModel(
            option: value.option,
            formattedFeeComponents: formattedFeeComponents(from: value.value),
            isSelected: .constant(false)
        )
    }

    private func formattedFeeComponents(from feeValue: LoadingValue<Fee>) -> LoadingValue<FormattedFeeComponents> {
        switch feeValue {
        case .loading:
            return .loading
        case .loaded(let value):
            let formattedFeeComponents = feeFormatter.formattedFeeComponents(
                fee: value.amount.value,
                currencySymbol: feeCurrencySymbol,
                currencyId: feeCurrencyId,
                isFeeApproximate: isFeeApproximate
            )
            return .loaded(formattedFeeComponents)
        case .failedToLoad(let error):
            return .failedToLoad(error: error)
        }
    }
}
