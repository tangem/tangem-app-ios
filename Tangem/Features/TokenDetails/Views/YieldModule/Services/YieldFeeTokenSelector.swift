//
//  YieldFeeTokenSelector.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemLocalization

final class YieldFeeTokenSelector {
    let feeCompactViewModel: FeeCompactViewModel
    let feeTokensViewModel: FeeSelectorTokensViewModel

    private let gaslessFeeService: YieldGaslessFeeService
    private let coinFeeTokenItem: TokenItem
    private let nativeFee = CurrentValueSubject<LoadingResult<BSDKFee, any Error>, Never>(.loading)

    init(gaslessFeeService: YieldGaslessFeeService, coinFeeTokenItem: TokenItem) {
        self.gaslessFeeService = gaslessFeeService
        self.coinFeeTokenItem = coinFeeTokenItem

        feeCompactViewModel = FeeCompactViewModel()
        feeTokensViewModel = FeeSelectorTokensViewModel(tokensDataProvider: gaslessFeeService)

        feeCompactViewModel.bind(
            selectedFeePublisher: selectedFeePublisher,
            supportFeeSelectionPublisher: gaslessFeeService.supportFeeSelectionPublisher
        )
    }

    var selectedFeePublisher: AnyPublisher<TokenFee, Never> {
        Publishers.CombineLatest3(gaslessFeeService.selectedTokenFeePublisher, nativeFee, gaslessFeeService.isUpdatingFeesPublisher)
            .map { [coinFeeTokenItem] selectedFee, nativeFee, isUpdatingFees in
                if isUpdatingFees {
                    return TokenFee(option: selectedFee.option, tokenItem: selectedFee.tokenItem, value: .loading)
                }

                guard selectedFee.tokenItem == coinFeeTokenItem else {
                    return selectedFee
                }

                return TokenFee(option: selectedFee.option, tokenItem: coinFeeTokenItem, value: nativeFee)
            }
            .eraseToAnyPublisher()
    }

    func setup(router: FeeSelectorTokensRoutable) {
        feeTokensViewModel.setup(router: router)
    }

    func updateFees(
        for transactionFees: [YieldTransactionFee],
        nativeFeeValue: Decimal? = nil,
        excludedFeeTokenItem: TokenItem? = nil
    ) async {
        guard var nativeFeeAmount = transactionFees.first?.totalFeeAmount else {
            return
        }

        nativeFeeAmount.value = nativeFeeValue ?? transactionFees.reduce(.zero) { $0 + $1.totalFeeAmount.value }

        nativeFee.send(.success(BSDKFee(nativeFeeAmount)))
        await gaslessFeeService.updateFees(for: transactionFees, excludedFeeTokenItem: excludedFeeTokenItem)
    }

    func resetFees() {
        nativeFee.send(.loading)
    }

    func failFees(error: any Error) {
        nativeFee.send(.failure(error))
    }

    func userDidSelectFeeToken(tokenFeeProvider: any TokenFeeProvider) {
        gaslessFeeService.userDidSelectFeeToken(tokenFeeProvider: tokenFeeProvider)
    }
}

// MARK: - Choose token texts

extension YieldFeeTokenSelector {
    static var title: String {
        Localization.feeSelectorChooseTokenTitle
    }

    static var subtitle: String {
        Localization.feeSelectorChooseTokenDescription(Localization.commonLearnMore)
            .replacingOccurrences(of: Localization.commonLearnMore, with: "")
            .trimmingCharacters(in: .whitespaces)
    }
}
