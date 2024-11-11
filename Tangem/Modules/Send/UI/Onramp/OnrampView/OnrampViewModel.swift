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
    @Published private(set) var onrampProvidersCompactViewModel: OnrampProvidersCompactViewModel

    private let interactor: OnrampInteractor

    private var bag: Set<AnyCancellable> = []

    init(
        onrampAmountViewModel: OnrampAmountViewModel,
        onrampProvidersCompactViewModel: OnrampProvidersCompactViewModel,
        interactor: OnrampInteractor
    ) {
        self.onrampAmountViewModel = onrampAmountViewModel
        self.onrampProvidersCompactViewModel = onrampProvidersCompactViewModel

        self.interactor = interactor
    }
}

// MARK: - Private

/*
 // [REDACTED_TODO_COMMENT]
 private extension OnrampViewModel {
     func bind() {
          interactor
              .selectedQuotePublisher
              .withWeakCaptureOf(self)
              .receive(on: DispatchQueue.main)
              .sink { viewModel, quote in
                  viewModel.updateQuoteView(quote: quote)
              }
              .store(in: &bag)
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
 */

// MARK: - SendStepViewAnimatable

extension OnrampViewModel: SendStepViewAnimatable {
    func viewDidChangeVisibilityState(_ state: SendStepVisibilityState) {}
}
