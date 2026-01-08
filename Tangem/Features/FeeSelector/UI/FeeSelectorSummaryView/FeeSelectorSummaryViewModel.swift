//
//  FeeSelectorSummaryViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemAccessibilityIdentifiers

protocol FeeSelectorSummaryRoutable: AnyObject {
    func userDidRequestTokenSelector()
    func userDidRequestFeeSelector()

    func userDidTapConfirmButton()
}

final class FeeSelectorSummaryViewModel: ObservableObject {
    // MARK: - Published

    @Published
    private(set) var suggestedFeeCurrency: FeeSelectorRowViewModel?

    @Published
    private(set) var suggestedFee: FeeSelectorRowViewModel?

    @Published
    private(set) var shouldShowBottomButton: Bool

    // MARK: - Dependencies

    private let feeFormatter: FeeFormatter
    private let interactor: FeeSelectorInteractor

    private weak var router: FeeSelectorSummaryRoutable?

    // MARK: - Bag

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(interactor: FeeSelectorInteractor) {
        self.interactor = interactor

        feeFormatter = CommonFeeFormatter()
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

    func userDidTapConfirm() {
        router?.userDidTapConfirmButton()
    }

    // MARK: - Private Implementation

    private func bind() {
        Publishers.CombineLatest(
            tokensDataProvider.selectedFeeTokenItemPublisher,
            tokensDataProvider.feeTokenItemsPublisher.map { $0.count > 1 ? true : false }
        )
        .receiveOnMain()
        .withWeakCaptureOf(self)
        .compactMap { viewModel, output in
            let (selectedToken, canExpand) = output
            guard let token = selectedToken else { return nil }
            return viewModel.mapTokenItemToRowViewModel(token: token, canExpand: canExpand)
        }
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

    private func mapTokenItemToRowViewModel(token: TokenItem, canExpand: Bool) -> FeeSelectorRowViewModel {
        let subtitleState: LoadableTextView.State = .loading

        return FeeSelectorRowViewModel(
            rowType: .token(tokenIconInfo: TokenIconInfoBuilder().build(from: token, isCustom: false)),
            title: token.name,
            subtitle: subtitleState,
            accessibilityIdentifier: FeeAccessibilityIdentifiers.suggestedFeeCurrency,
            expandAction: canExpand ? userDidTapToken : nil
        )
    }

    private func mapFeeToRowViewModel(fee: TokenFee, canExpand: Bool) -> FeeSelectorRowViewModel {
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
            subtitle: subtitleState,
            accessibilityIdentifier: FeeAccessibilityIdentifiers.suggestedFeeCurrency,
            expandAction: canExpand ? userDidTapFee : nil
        )
    }
}
