//
//  FeeSelectorSummaryViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemLocalization
import TangemAccessibilityIdentifiers
import Foundation

protocol FeeSelectorSummaryRoutable: AnyObject {
    func userDidRequestTokenSelector()
    func userDidRequestFeeSelector()

    func userDidTapConfirmButton()
}

final class FeeSelectorSummaryViewModel: ObservableObject {
    // MARK: - Published

    @Published private(set) var suggestedFeeCurrency: FeeSelectorRowViewModel?
    @Published private(set) var suggestedFee: FeeSelectorRowViewModel?

    // MARK: - Dependencies

    private let tokensDataProvider: FeeSelectorTokensDataProvider
    private let feesDataProvider: FeeSelectorFeesDataProvider
    private let feeFormatter: FeeFormatter

    private weak var router: FeeSelectorSummaryRoutable?

    // MARK: - Init

    init(
        tokensDataProvider: FeeSelectorTokensDataProvider,
        feesDataProvider: FeeSelectorFeesDataProvider,
        feeFormatter: any FeeFormatter
    ) {
        self.tokensDataProvider = tokensDataProvider
        self.feesDataProvider = feesDataProvider
        self.feeFormatter = feeFormatter

        bind()
    }

    func setup(router: FeeSelectorSummaryRoutable?) {
        self.router = router
    }

    func userDidTapToken() {
        router?.userDidRequestTokenSelector()
    }

    func userDidTapFee() {
        router?.userDidRequestFeeSelector()
    }

    // MARK: - Private Implementation

    private func bind() {
        Publishers.CombineLatest(
            tokensDataProvider.selectedTokenFeeProviderPublisher,
            tokensDataProvider.supportedTokenFeeProvidersPublisher.map { $0.count > 1 }
        )
        .withWeakCaptureOf(self)
        .map { $0.mapTokenItemToRowViewModel(tokenFeeProvider: $1.0, canExpand: $1.1) }
        .receiveOnMain()
        .assign(to: &$suggestedFeeCurrency)

        Publishers.CombineLatest4(
            tokensDataProvider.selectedTokenFeeProviderPublisher.flatMapLatest { $0.statePublisher },
            feesDataProvider.feeCoveragePublisher,
            tokensDataProvider.selectedTokenFeeProviderPublisher,
            feesDataProvider.selectedTokenFeeOptionPublisher,
        )
        .withWeakCaptureOf(self)
        .map { viewModel, output in
            let (state, feeCoverage, tokenFeeProvider, option) = output
            return viewModel.mapFeeStateToRowViewModel(
                state: state,
                feeCoverage: feeCoverage,
                tokenFeeProvider: tokenFeeProvider,
                option: option
            )
        }
        .receiveOnMain()
        .assign(to: &$suggestedFee)
    }

    private func mapTokenItemToRowViewModel(tokenFeeProvider: any TokenFeeProvider, canExpand: Bool) -> FeeSelectorRowViewModel {
        let feeTokenItem = tokenFeeProvider.feeTokenItem
        let subtitleBalanceState = LoadableTokenBalanceViewStateBuilder().build(
            type: tokenFeeProvider.formattedFeeTokenBalance,
            textBuilder: Localization.commonBalance
        )

        return FeeSelectorRowViewModel(
            rowType: .token(tokenIconInfo: TokenIconInfoBuilder().build(from: feeTokenItem, isCustom: false)),
            title: feeTokenItem.name,
            subtitle: .balance(subtitleBalanceState),
            accessibilityIdentifier: FeeAccessibilityIdentifiers.suggestedFeeCurrency,
            expandAction: canExpand ? userDidTapToken : nil
        )
    }

    private func mapFeeStateToRowViewModel(
        state: TokenFeeProviderState,
        feeCoverage: FeeCoverage,
        tokenFeeProvider: any TokenFeeProvider,
        option: FeeOption
    ) -> FeeSelectorRowViewModel {
        let subtitleState: LoadableTextView.State = {
            switch (state, feeCoverage) {
            case (.idle, _), (.unavailable, _), (.error, _):
                return .noData

            case (_, .undefined):
                return .noData

            case (.loading, _):
                return .loading

            case (.available, .uncovered):
                return .loaded(text: Localization.gaslessNotEnoughFundsToCoverTokenFee)

            case (.available, .covered(let feeValue)):
                let formattedFeeComponents = feeFormatter.formattedFeeComponents(
                    fee: feeValue,
                    tokenItem: tokenFeeProvider.feeTokenItem,
                    formattingOptions: .sendCryptoFeeFormattingOptions
                )

                return .loaded(text: formattedFeeComponents.formatted)

            default:
                return .noData
            }

        }()

        let hasEnoughBalance = feeCoverage.isCovered
        let supportsMultipleOptions = tokenFeeProvider.hasMultipleFeeOptions

        return FeeSelectorRowViewModel(
            rowType: .fee(image: option.icon.image),
            title: option.title,
            subtitle: .fee(subtitleState),
            accessibilityIdentifier: FeeAccessibilityIdentifiers.suggestedFeeCurrency,
            availability: hasEnoughBalance ? .available : .notEnoughBalance(supportsMultipleOptions: supportsMultipleOptions),
            expandAction: supportsMultipleOptions ? userDidTapFee : nil
        )
    }
}
