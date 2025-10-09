//
//  SendFeeFinishViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class SendFeeFinishViewModel: ObservableObject, Identifiable {
    @Published var selectedFeeRowViewModel: FeeRowViewModel?

    private let feeTokenItem: TokenItem
    private let isFeeApproximate: Bool

    private let feeFormatter: FeeFormatter = CommonFeeFormatter(
        balanceFormatter: BalanceFormatter(),
        balanceConverter: BalanceConverter()
    )

    init(feeTokenItem: TokenItem, isFeeApproximate: Bool) {
        self.feeTokenItem = feeTokenItem
        self.isFeeApproximate = isFeeApproximate
    }

    func bind(input: SendFeeInput) {
        input.selectedFeePublisher
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .compactMap { $0.mapToFeeRowViewModel(fee: $1) }
            .assign(to: &$selectedFeeRowViewModel)
    }

    private func mapToFeeRowViewModel(fee: SendFee) -> FeeRowViewModel? {
        switch fee.value {
        case .failedToLoad, .loading:
            // Do nothing to avoid incorrect UI
            return nil

        case .loaded(let feeValue):
            let feeComponents = feeFormatter.formattedFeeComponents(
                fee: feeValue.amount.value,
                currencySymbol: feeTokenItem.currencySymbol,
                currencyId: feeTokenItem.currencyId,
                isFeeApproximate: isFeeApproximate,
                formattingOptions: .sendCryptoFeeFormattingOptions
            )

            return FeeRowViewModel(option: fee.option, components: .loaded(feeComponents), style: .plain)
        }
    }
}
