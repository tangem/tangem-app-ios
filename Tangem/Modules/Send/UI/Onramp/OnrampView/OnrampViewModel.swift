//
//  OnrampViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemExpress

class OnrampViewModel: ObservableObject, Identifiable {
    @Published private(set) var onrampAmountViewModel: OnrampAmountViewModel
    @Published private(set) var paymentState: PaymentState?

    private let interactor: OnrampInteractor

    weak var router: OnrampSummaryRoutable?
    private var bag: Set<AnyCancellable> = []

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
        /*
          // [REDACTED_TODO_COMMENT]
         interactor
             .selectedQuotePublisher
             .withWeakCaptureOf(self)
             .receive(on: DispatchQueue.main)
             .sink { viewModel, quote in
                 viewModel.updateQuoteView(quote: quote)
             }
             .store(in: &bag)
          */
    }

    func updateQuoteView(quote: LoadingValue<OnrampQuote>?) {
        switch quote {
        case .none, .failedToLoad:
            paymentState = .none
        case .loading:
            paymentState = .loading
        case .loaded(let quote):
            // [REDACTED_TODO_COMMENT]
            paymentState = .loaded(
                data: .init(iconURL: nil, paymentMethodName: "Card", providerName: "1Inch", badge: .bestRate) { [weak self] in
                    self?.router?.onrampStepRequestEditProvider()
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
