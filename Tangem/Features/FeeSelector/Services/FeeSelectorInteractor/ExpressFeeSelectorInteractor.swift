//
//  FeeSelectorExpressInteractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

struct ExpressFeeSelectorAnalytics: FeeSelectorAnalytics {
    func logFeeStepOpened() {}

    func logSendFeeSelected(_ feeOption: FeeOption) {}
}

class ExpressFeeSelectorInteractor {
    var hasFees: Bool { !fees.isEmpty }
    var hasMultipleFeeOptions: Bool { fees.hasMultipleFeeOptions }

    private let expressInteractor: ExpressInteractor

    private var feesProvider: (any TokenFeeProvider)? {
        expressInteractor.getSource().value?.tokenFeeProvider
    }

    private var selectedFeeOption: FeeOption {
        expressInteractor.getState().fees.selected
    }

    init(expressInteractor: ExpressInteractor) {
        self.expressInteractor = expressInteractor
    }
}

// MARK: - FeeSelectorInteractor

extension ExpressFeeSelectorInteractor: FeeSelectorInteractor {
    var selectedFee: TokenFee? {
        feesProvider?.fees[selectedFeeOption]
    }

    var selectedFeePublisher: AnyPublisher<TokenFee?, Never> {
        expressInteractor.state
            .withWeakCaptureOf(self)
            .map { $0.feesProvider?.fees[$1.fees.selected] }
            .eraseToAnyPublisher()
    }

    var fees: [TokenFee] {
        feesProvider?.fees ?? []
    }

    var feesPublisher: AnyPublisher<[TokenFee], Never> {
        feesProvider?.feesPublisher.prepend([]).eraseToAnyPublisher() ?? .just(output: [])
    }

    func userDidSelect(feeTokenItem: TokenItem) {}

    func userDidSelect(selectedFee: TokenFee) {
        expressInteractor.updateFeeOption(option: selectedFee.option)
    }

    var feeTokenItems: [TokenItem] {
        []
    }

    var feeTokenItemsPublisher: AnyPublisher<[TokenItem], Never> {
        .just(output: [])
    }
}
