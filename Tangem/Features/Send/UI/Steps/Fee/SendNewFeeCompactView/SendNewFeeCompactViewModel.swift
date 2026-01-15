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

    private let feeFormatter: FeeFormatter

    private let feeExplanationUrl = TangemBlogUrlBuilder().url(post: .fee)
    private var selectedFeeSubscription: AnyCancellable?
    private var canEditFeeSubscription: AnyCancellable?

    init(feeFormatter: FeeFormatter = CommonFeeFormatter()) {
        self.feeFormatter = feeFormatter
    }

    func bind(input: SendFeeInput) {
        selectedFeeSubscription = input.selectedFeePublisher
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { viewModel, selectedFee in
                viewModel.updateView(tokenFee: selectedFee)
            }

        canEditFeeSubscription = input.hasMultipleFeeOptions
            .receiveOnMain()
            .assign(to: \.canEditFee, on: self, ownership: .weak)
    }

    private func updateView(tokenFee: TokenFee?) {
        guard let tokenFee else {
            selectedFeeComponents = .noData
            return
        }

        switch tokenFee.value {
        case .loading:
            selectedFeeComponents = .loading

        case .success(let fee):
            let feeComponents = feeFormatter.formattedFeeComponents(
                fee: fee.amount.value,
                currencySymbol: tokenFee.tokenItem.currencySymbol,
                currencyId: tokenFee.tokenItem.currencyId,
                isFeeApproximate: tokenFee.tokenItem.isFeeApproximate,
                formattingOptions: .sendCryptoFeeFormattingOptions
            )
            selectedFeeComponents = .loaded(text: feeComponents.fiatFee ?? feeComponents.cryptoFee)

        case .failure:
            selectedFeeComponents = .noData
        }
    }
}
