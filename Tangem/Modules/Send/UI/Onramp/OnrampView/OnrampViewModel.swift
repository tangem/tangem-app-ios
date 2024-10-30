//
//  OnrampViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class OnrampViewModel: ObservableObject, Identifiable {
    @Published private(set) var onrampAmountViewModel: OnrampAmountViewModel
    @Published private(set) var paymentState: PaymentState?

    private let interactor: OnrampInteractor

    weak var router: OnrampSummaryRoutable?

    init(
        onrampAmountViewModel: OnrampAmountViewModel,
        interactor: OnrampInteractor
    ) {
        self.onrampAmountViewModel = onrampAmountViewModel
        self.interactor = interactor

        bind()
    }
}

// MARK: - Private

private extension OnrampViewModel {
    func bind() {
        // [REDACTED_TODO_COMMENT]
        // Temp mock
        paymentState = .loading

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.paymentState = .loaded(
                data: .init(iconURL: nil, paymentMethodName: "Card", providerName: "1Inch", badge: .bestRate) {
                    self?.router?.summaryStepRequestEditProvider()
                }
            )
        }
    }
}

// MARK: - SendStepViewAnimatable

extension OnrampViewModel: SendStepViewAnimatable {
    func viewDidChangeVisibilityState(_ state: SendStepVisibilityState) {}
}

extension OnrampViewModel {
    enum PaymentState: Hashable, Identifiable {
        case loading
        case loaded(data: OnrampProvidersCompactViewData)

        var id: Int { hashValue }
    }
}
