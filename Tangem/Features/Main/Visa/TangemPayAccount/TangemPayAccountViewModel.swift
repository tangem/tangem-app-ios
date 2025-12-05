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
    func openTangemPayMainView(tangemPayAccount: TangemPayAccount)
}

final class TangemPayAccountViewModel: ObservableObject {
    @Published private(set) var state: ViewState

    @Published private var isLoading: Bool = false

    var disableButtonTap: Bool {
        isLoading ? true : !state.isTappable
    }

    private let tangemPayAccount: TangemPayAccount
    private weak var router: TangemPayAccountRoutable?

    private let loadableTokenBalanceViewStateBuilder = LoadableTokenBalanceViewStateBuilder()

    init(tangemPayAccount: TangemPayAccount, router: TangemPayAccountRoutable?) {
        self.tangemPayAccount = tangemPayAccount
        self.router = router

        state = TangemPayAccountViewModel.mapToState(
            state: tangemPayAccount.state,
            status: .active,
            card: tangemPayAccount.tangemPayCard,
            balanceType: tangemPayAccount.tangemPayFiatTokenBalanceProvider.formattedBalanceType
        )

        bind()
    }

    func userDidTapView() {
        switch state {
        case .kycInProgress:
            runTask(in: self) { viewModel in
                do {
                    try await viewModel.tangemPayAccount.launchKYC {
                        viewModel.isLoading = true
                        runTask(in: viewModel) { viewModel in
                            _ = await viewModel.tangemPayAccount.loadCustomerInfo().value
                            Task { @MainActor in
                                viewModel.isLoading = false
                            }
                        }
                    }
                } catch {
                    VisaLogger.error("Failed to launch KYC", error: error)
                }
            }

        case .failedToIssueCard:
            router?.openTangemPayFailedToIssueCardPopup()

        case .issuingYourCard:
            router?.openTangemPayIssuingYourCardPopup()

        case .normal:
            router?.openTangemPayMainView(tangemPayAccount: tangemPayAccount)

        case .syncNeeded, .unavailable:
            break
        }
    }
}

// MARK: - Private

private extension TangemPayAccountViewModel {
    func bind() {
        Publishers.CombineLatest4(
            tangemPayAccount
                .tangemPayAccountStatePublisher,
            tangemPayAccount
                .tangemPayStatusPublisher,
            tangemPayAccount
                .tangemPayCardPublisher,
            tangemPayAccount
                .tangemPayFiatTokenBalanceProvider
                .formattedBalanceTypePublisher
        )
        .map(TangemPayAccountViewModel.mapToState)
        .handleEvents(receiveOutput: { state in
            switch state {
            case .issuingYourCard:
                Analytics.log(.visaOnboardingVisaIssuingBannerDisplayed)
            default:
                break
            }
        })
        .receiveOnMain()
        .assign(to: &$state)
    }

    static func mapToState(
        state: TangemPayAuthorizer.State,
        status: TangemPayStatus,
        card: VisaCustomerInfoResponse.Card?,
        balanceType: FormattedTokenBalanceType
    ) -> ViewState {
        switch status {
        case .kycRequired:
            return .kycInProgress
        case .readyToIssueOrIssuing:
            return .issuingYourCard
        case .failedToIssue:
            return .failedToIssueCard
        case .active, .blocked:
            break
        }

        switch state {
        case .authorized:
            break
        case .syncNeeded:
            return .syncNeeded
        case .unavailable:
            return .unavailable
        }

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
