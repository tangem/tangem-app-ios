//
//  SendFeeCompactViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class SendFeeCompactViewModel: ObservableObject, Identifiable {
    @Published private(set) var selectedFeeRowViewModel: FeeRowViewModel?
    @Published private(set) var canEditFee: Bool = false

    private let feeFormatter: FeeFormatter

    init(input: SendFeeInput, feeFormatter: FeeFormatter = CommonFeeFormatter()) {
        self.feeFormatter = feeFormatter

        bind(input: input)
    }

    func bind(input: SendFeeInput) {
        input.selectedFeePublisher
            .withWeakCaptureOf(self)
            .map { $0.mapToFeeRowViewModel(tokenFee: $1) }
            .receiveOnMain()
            .assign(to: &$selectedFeeRowViewModel)

        input
            .hasMultipleFeeOptions
            .receiveOnMain()
            .assign(to: &$canEditFee)
    }

    private func mapToFeeRowViewModel(tokenFee: TokenFee?) -> FeeRowViewModel? {
        guard let tokenFee else {
            return nil
        }

        let feeComponents = tokenFee.value.mapValue {
            feeFormatter.formattedFeeComponents(
                fee: $0.amount.value,
                currencySymbol: tokenFee.tokenItem.currencySymbol,
                currencyId: tokenFee.tokenItem.currencyId,
                isFeeApproximate: tokenFee.tokenItem.isFeeApproximate,
                formattingOptions: .sendCryptoFeeFormattingOptions
            )
        }

        return FeeRowViewModel(option: tokenFee.option, components: feeComponents, style: .plain)
    }
}
