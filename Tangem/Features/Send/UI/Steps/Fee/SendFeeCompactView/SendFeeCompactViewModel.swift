//
//  SendFeeCompactViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemAssets
import TangemLocalization

class SendFeeCompactViewModel: ObservableObject, Identifiable {
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

    init(feeFormatter: FeeFormatter = CommonFeeFormatter()) {
        self.feeFormatter = feeFormatter
    }

    func bind(input: SendFeeInput) {
        input.selectedFeePublisher
            .withWeakCaptureOf(self)
            .map { $0.mapToLoadableTextViewState(tokenFee: $1) }
            .receiveOnMain()
            .assign(to: &$selectedFeeComponents)

        input.supportFeeSelectionPublisher
            .receiveOnMain()
            .assign(to: &$canEditFee)
    }

    private func mapToLoadableTextViewState(tokenFee: TokenFee) -> LoadableTextView.State {
        switch tokenFee.value {
        case .loading:
            return .loading

        case .success(let fee):
            let feeComponents = feeFormatter.formattedFeeComponents(
                fee: fee.amount.value,
                currencySymbol: tokenFee.tokenItem.currencySymbol,
                currencyId: tokenFee.tokenItem.currencyId,
                isFeeApproximate: tokenFee.tokenItem.isFeeApproximate,
                formattingOptions: .sendCryptoFeeFormattingOptions
            )
            return .loaded(text: feeComponents.fiatFee ?? feeComponents.cryptoFee)

        case .failure:
            return .noData
        }
    }
}
