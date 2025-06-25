//
//  SendNewFeeCompactViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class SendNewFeeCompactViewModel: ObservableObject, Identifiable {
    @Published var selectedFeeComponents: LoadableTextView.State = .initialized
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
            .receiveOnMain()
            .sink { viewModel, selectedFee in
                viewModel.updateView(fee: selectedFee)
            }

        canEditFeeSubscription = input.canChooseFeeOption
            .receiveOnMain()
            .assign(to: \.canEditFee, on: self, ownership: .weak)
    }

    private func updateView(fee: SendFee) {
        switch fee.value {
        case .loading:
            selectedFeeComponents = .loading

        case .loaded(let fee):
            let feeComponents = feeFormatter.formattedFeeComponents(
                fee: fee.amount.value,
                currencySymbol: feeTokenItem.currencySymbol,
                currencyId: feeTokenItem.currencyId,
                isFeeApproximate: isFeeApproximate,
                formattingOptions: .sendCryptoFeeFormattingOptions
            )
            selectedFeeComponents = .loaded(text: feeComponents.fiatFee ?? feeComponents.cryptoFee)

        case .failedToLoad:
            selectedFeeComponents = .noData
        }
    }
}
