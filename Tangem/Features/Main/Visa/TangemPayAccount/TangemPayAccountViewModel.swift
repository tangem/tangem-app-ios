//
//  TangemPayAccountViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemMacro
import TangemVisa
import TangemLocalization

protocol TangemPayAccountRoutable: AnyObject {
    func openTangemPayMainView(tangemPayAccount: TangemPayAccount)
}

final class TangemPayAccountViewModel: ObservableObject {
    @Published private(set) var state: ViewState

    private let tangemPayAccount: TangemPayAccount
    private weak var router: TangemPayAccountRoutable?

    private let loadableTokenBalanceViewStateBuilder = LoadableTokenBalanceViewStateBuilder()

    init(tangemPayAccount: TangemPayAccount, router: TangemPayAccountRoutable?) {
        self.tangemPayAccount = tangemPayAccount
        self.router = router

        state = TangemPayAccountViewModel.mapToState(
            card: tangemPayAccount.tangemPayCard,
            balanceType: tangemPayAccount.tangemPayTokenBalanceProvider.formattedBalanceType
        )

        bind()
    }

    func userDidTapView() {
        router?.openTangemPayMainView(tangemPayAccount: tangemPayAccount)
    }
}

// MARK: - Private

private extension TangemPayAccountViewModel {
    func bind() {
        Publishers.CombineLatest(
            tangemPayAccount
                .tangemPayCardPublisher,
            tangemPayAccount
                .tangemPayTokenBalanceProvider
                .formattedBalanceTypePublisher
        )
        .map { TangemPayAccountViewModel.mapToState(card: $0, balanceType: $1) }
        .receiveOnMain()
        .assign(to: &$state)
    }

    static func mapToState(card: VisaCustomerInfoResponse.Card?, balanceType: FormattedTokenBalanceType) -> ViewState {
        switch card {
        case .none:
            return .unavailable
        case .some(let card):
            let cardInfo = CardInfo(cardNumberEnd: card.cardNumberEnd)
            let balance = LoadableTokenBalanceViewStateBuilder().build(type: balanceType)
            return .normal(card: cardInfo, balance: balance)
        }
    }
}

extension TangemPayAccountViewModel {
    @CaseFlagable
    enum ViewState {
        case normal(card: CardInfo, balance: LoadableTokenBalanceView.State)
        case syncNeeded
        case unavailable

        var subtitle: String {
            switch self {
            case .normal(let card, _):
                "*" + card.cardNumberEnd
            case .syncNeeded:
                Localization.tangempayPaymentAccountSyncNeeded
            case .unavailable:
                "—"
            }
        }
    }

    struct CardInfo {
        let cardNumberEnd: String
    }
}
