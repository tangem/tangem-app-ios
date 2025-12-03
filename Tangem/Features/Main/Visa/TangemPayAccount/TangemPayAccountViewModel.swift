//
//  TangemPayAccountViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemVisa
import TangemLocalization

protocol TangemPayAccountRoutable: AnyObject {
    func openTangemPayIssuingYourCardPopup()
    func openTangemPayFailedToIssueCardPopup()
    func openTangemPayMainView(
        tangemPayAccount: TangemPayAccount,
        tangemPayAccountManager: TangemPayAccountManaging
    )
}

final class TangemPayAccountViewModel: ObservableObject {
    @Published private(set) var state: ViewState = .unavailable

    private let tangemPayAccountManager: TangemPayAccountManaging
    private weak var router: TangemPayAccountRoutable?

    private let loadableTokenBalanceViewStateBuilder = LoadableTokenBalanceViewStateBuilder()

    init(
        tangemPayAccountManager: TangemPayAccountManaging,
        router: TangemPayAccountRoutable?
    ) {
        self.tangemPayAccountManager = tangemPayAccountManager
        self.router = router
        bind()
    }

    func userDidTapView() {
        switch state {
        case .kycInProgress:
            runTask(in: self) { viewModel in
                do {
                    try await viewModel.tangemPayAccountManager.launchKYC()
                } catch {
                    VisaLogger.error("Failed to launch KYC", error: error)
                }
            }

        case .failedToIssueCard:
            router?.openTangemPayFailedToIssueCardPopup()

        case .issuingYourCard:
            router?.openTangemPayIssuingYourCardPopup()

        case .normal:
            guard let account = tangemPayAccountManager.tangemPayAccount else {
                VisaLogger.info(
                    "Unexpected behavior, normal state implies that TangemPayAccount exists"
                )
                return
            }
            router?.openTangemPayMainView(
                tangemPayAccount: account,
                tangemPayAccountManager: tangemPayAccountManager
            )

        case .syncNeeded, .unavailable:
            break
        }
    }
}

// MARK: - Private

private extension TangemPayAccountViewModel {
    func bind() {
        tangemPayAccountManager.statePublisher
            .map(TangemPayAccountViewModel.mapToState(from:))
            .receiveOnMain()
            .assign(to: &$state)
    }

    static func mapToState(
        from state: TangemPayAccountManager.State
    ) -> ViewState {
        switch state {
        case .idle, .unavailable:
            return .unavailable

        case .offered(let status):
            switch status {
            case .kycRequired:
                return .kycInProgress
            case .readyToIssueOrIssuing:
                return .issuingYourCard
            case .failedToIssue:
                return .failedToIssueCard
            case .active, .blocked:
                return .unavailable
            }

        case .syncNeeded:
            return .syncNeeded

        case .activated(let account):
            switch account.tangemPayCard {
            case .none:
                return .unavailable
            case .some(let card):
                let cardInfo = CardInfo(cardNumberEnd: card.cardNumberEnd)
                let balanceType = account.tangemPayTokenBalanceProvider.formattedBalanceType
                let balance = LoadableTokenBalanceViewStateBuilder().build(type: balanceType)
                return .normal(card: cardInfo, balance: balance)
            }
        }
    }
}

extension TangemPayAccountViewModel {
    enum ViewState {
        case kycInProgress
        case issuingYourCard
        case failedToIssueCard
        case normal(card: CardInfo, balance: LoadableTokenBalanceView.State)
        case syncNeeded
        case unavailable

        var subtitle: String {
            switch self {
            case .kycInProgress:
                Localization.tangempayKycInProgress
            case .issuingYourCard:
                Localization.tangempayIssuingYourCard
            case .failedToIssueCard:
                Localization.tangempayFailedToIssueCard
            case .normal(let card, _):
                "*" + card.cardNumberEnd
            case .syncNeeded:
                Localization.tangempaySyncNeeded
            case .unavailable:
                "—"
            }
        }

        var isTappable: Bool {
            switch self {
            case .kycInProgress, .issuingYourCard, .failedToIssueCard, .normal:
                true
            case .syncNeeded, .unavailable:
                false
            }
        }
    }

    struct CardInfo {
        let cardNumberEnd: String
    }
}
