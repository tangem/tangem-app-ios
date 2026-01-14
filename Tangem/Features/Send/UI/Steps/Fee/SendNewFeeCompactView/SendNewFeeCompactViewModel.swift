//
//  SendNewFeeCompactViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemAssets
import TangemLocalization

class SendNewFeeCompactViewModel: ObservableObject, Identifiable {
    @Published var selectedFeeComponents: LoadableTextView.State = .initialized
    @Published var canEditFee: Bool = false

    var infoButtonString: AttributedString {
        let readMore = Localization.commonReadMore
        var attributed = AttributedString(Localization.commonFeeSelectorFooter(readMore))
        attributed.foregroundColor = Colors.Text.primary2
        attributed.font = Fonts.Regular.caption1

        if let range = attributed.range(of: readMore) {
            attributed[range].foregroundColor = Colors.Text.accent
            attributed[range].link = TangemBlogUrlBuilder().url(post: .fee)
        }

        return attributed
    }

    private let feeTokenItem: TokenItem
    private let isFeeApproximate: Bool

    private let feeExplanationUrl = TangemBlogUrlBuilder().url(post: .fee)
    private var selectedFeeSubscription: AnyCancellable?
    private var canEditFeeSubscription: AnyCancellable?

    private let feeFormatter: FeeFormatter = CommonFeeFormatter(
        balanceFormatter: BalanceFormatter(),
        balanceConverter: BalanceConverter()
    )

    init(feeTokenItem: TokenItem, isFeeApproximate: Bool) {
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

        canEditFeeSubscription = input.hasMultipleFeeOptions
            .receiveOnMain()
            .assign(to: \.canEditFee, on: self, ownership: .weak)
    }

    private func updateView(fee: TokenFee) {
        switch fee.value {
        case .loading:
            selectedFeeComponents = .loading

        case .success(let fee):
            let feeComponents = feeFormatter.formattedFeeComponents(
                fee: fee.amount.value,
                currencySymbol: feeTokenItem.currencySymbol,
                currencyId: feeTokenItem.currencyId,
                isFeeApproximate: isFeeApproximate,
                formattingOptions: .sendCryptoFeeFormattingOptions
            )
            selectedFeeComponents = .loaded(text: feeComponents.fiatFee ?? feeComponents.cryptoFee)

        case .failure:
            selectedFeeComponents = .noData
        }
    }
}
