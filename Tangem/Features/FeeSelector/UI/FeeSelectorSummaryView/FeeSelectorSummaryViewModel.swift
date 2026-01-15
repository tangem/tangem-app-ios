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

    // MARK: - Bag

    private var bag = Set<AnyCancellable>()

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
            tokensDataProvider.selectedSelectorTokenFeeProviderPublisher.compactMap { $0 },
            tokensDataProvider.selectorTokenFeeProvidersPublisher.map { $0.count > 1 }
        )
        .receiveOnMain()
        .withWeakCaptureOf(self)
        .map { $0.mapTokenItemToRowViewModel(tokenFeeProvider: $1.0, canExpand: $1.1) }
        .assign(to: \.suggestedFeeCurrency, on: self, ownership: .weak)
        .store(in: &bag)

        Publishers.CombineLatest(
            feesDataProvider.selectedSelectorFeePublisher,
            feesDataProvider.selectorFeesPublisher.map { $0.count > 1 ? true : false }
        )
        .receiveOnMain()
        .withWeakCaptureOf(self)
        .compactMap { viewModel, output in
            let (selectedFee, canExpand) = output
            guard let fee = selectedFee else { return nil }
            return viewModel.mapFeeToRowViewModel(fee: fee, canExpand: canExpand)
        }
        .assign(to: \.suggestedFee, on: self, ownership: .weak)
        .store(in: &bag)
    }

    private func mapTokenItemToRowViewModel(tokenFeeProvider: any TokenFeeProvider, canExpand: Bool) -> FeeSelectorRowViewModel {
        let feeTokenItem = tokenFeeProvider.feeTokenItem
        let subtitleBalanceState = LoadableTokenBalanceViewStateBuilder().build(
            type: tokenFeeProvider.balanceState,
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

    private func mapFeeToRowViewModel(fee: LoadableTokenFee, canExpand: Bool) -> FeeSelectorRowViewModel {
        let subtitleState: LoadableTextView.State = {
            switch fee.value {
            case .loading:
                return .loading
            case .failure:
                return .noData
            case .success(let feeValue):
                let formatted = feeFormatter
                    .formattedFeeComponents(
                        fee: feeValue.amount.value,
                        tokenItem: fee.tokenItem,
                        formattingOptions: .sendCryptoFeeFormattingOptions
                    )
                    .formatted
                return .loaded(text: formatted)
            }
        }()

        return FeeSelectorRowViewModel(
            rowType: .fee(image: fee.option.icon.image),
            title: fee.option.title,
            subtitle: .fee(subtitleState),
            accessibilityIdentifier: FeeAccessibilityIdentifiers.suggestedFeeCurrency,
            expandAction: canExpand ? userDidTapFee : nil
        )
    }
}
