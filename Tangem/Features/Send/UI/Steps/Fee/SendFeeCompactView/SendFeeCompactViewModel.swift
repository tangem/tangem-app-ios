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
    @Published var selectedFeeRowViewModel: FeeRowViewModel?
    @Published var canEditFee: Bool = false

    private let feeTokenItem: TokenItem
    private let isFeeApproximate: Bool
    private var selectedFeeSubscription: AnyCancellable?
    private var canEditFeeSubscription: AnyCancellable?

    private let feeFormatter: FeeFormatter = CommonFeeFormatter(
        balanceFormatter: BalanceFormatter(),
        balanceConverter: BalanceConverter()
    )

    init(
        input: SendFeeInput,
        feeTokenItem: TokenItem,
        isFeeApproximate: Bool
    ) {
        self.feeTokenItem = feeTokenItem
        self.isFeeApproximate = isFeeApproximate
    }

    func bind(input: SendFeeInput) {
        selectedFeeSubscription = input.selectedFeePublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, selectedFee in
                viewModel.selectedFeeRowViewModel = viewModel.mapToFeeRowViewModel(fee: selectedFee)
            }

        canEditFeeSubscription = input
            .feesHasMultipleFeeOptions
            .receiveOnMain()
            .assign(to: \.canEditFee, on: self, ownership: .weak)
    }

    private func mapToFeeRowViewModel(fee: TokenFee) -> FeeRowViewModel {
        let feeComponents = fee.value.mapValue {
            feeFormatter.formattedFeeComponents(
                fee: $0.amount.value,
                currencySymbol: feeTokenItem.currencySymbol,
                currencyId: feeTokenItem.currencyId,
                isFeeApproximate: isFeeApproximate,
                formattingOptions: .sendCryptoFeeFormattingOptions
            )
        }

        return FeeRowViewModel(option: fee.option, components: feeComponents, style: .plain)
    }
}
