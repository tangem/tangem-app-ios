//
//  FeeCompactViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemAssets
import TangemLocalization

class FeeCompactViewModel: ObservableObject, Identifiable {
    @Published var selectedFeeTokenCurrencySymbol: String?
    @Published var selectedFeeComponents: LoadableTextView.State
    @Published var canEditFee: Bool

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

    init(
        selectedFeeTokenCurrencySymbol: String? = nil,
        selectedFeeComponents: LoadableTextView.State = .initialized,
        canEditFee: Bool = false,
        feeFormatter: FeeFormatter = CommonFeeFormatter()
    ) {
        self.selectedFeeTokenCurrencySymbol = selectedFeeTokenCurrencySymbol
        self.selectedFeeComponents = selectedFeeComponents
        self.canEditFee = canEditFee
        self.feeFormatter = feeFormatter
    }

    func bind(input: SendFeeInput) {
        bind(
            selectedFeePublisher: input.selectedFeePublisher,
            supportFeeSelectionPublisher: input.supportFeeSelectionPublisher
        )
    }

    func bind(
        selectedFeePublisher: AnyPublisher<TokenFee, Never>,
        supportFeeSelectionPublisher: AnyPublisher<Bool, Never>
    ) {
        selectedFeePublisher
            .withWeakCaptureOf(self)
            .map { $0.mapToLoadableTextViewState(tokenFee: $1) }
            .receiveOnMain()
            .assign(to: &$selectedFeeComponents)

        selectedFeePublisher
            .map { $0.tokenItem.currencySymbol }
            .receiveOnMain()
            .assign(to: &$selectedFeeTokenCurrencySymbol)

        supportFeeSelectionPublisher
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
