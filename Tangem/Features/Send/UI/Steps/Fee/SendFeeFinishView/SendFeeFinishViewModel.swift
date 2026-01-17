//
//  SendFeeFinishViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class SendFeeFinishViewModel: ObservableObject, Identifiable {
    @Published var selectedFeeRowViewModel: FeeRowViewModel?

    private let feeFormatter: FeeFormatter

    init(feeFormatter: FeeFormatter = CommonFeeFormatter()) {
        self.feeFormatter = feeFormatter
    }

    func bind(input: SendFeeInput) {
        input.selectedFeePublisher
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .compactMap { $0.mapToFeeRowViewModel(tokenFee: $1) }
            .assign(to: &$selectedFeeRowViewModel)
    }

    private func mapToFeeRowViewModel(tokenFee: TokenFee) -> FeeRowViewModel? {
        switch tokenFee.value {
        case .failure, .loading:
            // Do nothing to avoid incorrect UI
            return nil

        case .success(let feeValue):
            let feeComponents = feeFormatter.formattedFeeComponents(
                fee: feeValue.amount.value,
                currencySymbol: tokenFee.tokenItem.currencySymbol,
                currencyId: tokenFee.tokenItem.currencyId,
                isFeeApproximate: tokenFee.tokenItem.isFeeApproximate,
                formattingOptions: .sendCryptoFeeFormattingOptions
            )

            return FeeRowViewModel(option: tokenFee.option, components: .success(feeComponents), style: .plain)
        }
    }
}
