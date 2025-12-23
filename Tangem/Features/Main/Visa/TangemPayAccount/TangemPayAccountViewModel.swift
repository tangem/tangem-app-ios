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
    func openTangemPayKYCInProgressPopup(tangemPayAccount: TangemPayAccount)
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
            state: tangemPayAccount.state,
            status: .active,
            card: tangemPayAccount.tangemPayCard,
            balanceType: tangemPayAccount.balancesProvider.fixedFiatTotalTokenBalanceProvider.formattedBalanceType
        )

        bind()
    }

    func userDidTapView() {
        switch state {
        case .kycInProgress:
            router?.openTangemPayKYCInProgressPopup(
                tangemPayAccount: tangemPayAccount
            )

        case .failedToIssueCard:
            router?.openTangemPayFailedToIssueCardPopup()

        case .issuingYourCard:
            router?.openTangemPayIssuingYourCardPopup()

        case .normal:
            router?.openTangemPayMainView(tangemPayAccount: tangemPayAccount)

        case .syncNeeded, .unavailable, .skeleton, .rootedDevice:
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
                .tangemPayStatusPublisher
                .map(Optional.some)
                .prepend(nil),
            tangemPayAccount
                .tangemPayCardPublisher,
            tangemPayAccount
                .balancesProvider
                .fixedFiatTotalTokenBalanceProvider
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
        status: TangemPayStatus?,
        card: VisaCustomerInfoResponse.Card?,
        balanceType: FormattedTokenBalanceType
    ) -> ViewState {
        guard !RTCUtil().checkStatus().hasIssues else {
            return .rootedDevice
        }

        switch state {
        case .syncNeeded:
            return .syncNeeded
        case .unavailable:
            return .unavailable
        case .authorized:
            break
        }

        switch status {
        case .kycRequired:
            return .kycInProgress
        case .readyToIssueOrIssuing:
            return .issuingYourCard
        case .failedToIssue:
            return .failedToIssueCard
        case .unavailable:
            return .unavailable
        case .active, .blocked, .none:
            break
        }

        switch card {
        case .none:
            return .skeleton
        case .some(let card):
            let cardInfo = CardInfo(cardNumberEnd: card.cardNumberEnd)
            let balance = LoadableTokenBalanceViewStateBuilder().build(type: balanceType)
            return .normal(card: cardInfo, balance: balance)
        }
    }
}

extension TangemPayAccountViewModel {
    enum ViewState {
        case skeleton
        case kycInProgress
        case issuingYourCard
        case failedToIssueCard
        case normal(card: CardInfo, balance: LoadableTokenBalanceView.State)
        case syncNeeded
        case unavailable
        case rootedDevice

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
            case .unavailable, .skeleton:
                "—"
            case .rootedDevice:
                Localization.tangempayAccountUnableToUseRooted
            }
        }

        var isFullyVisible: Bool {
            switch self {
            case .kycInProgress, .issuingYourCard, .failedToIssueCard, .normal, .skeleton:
                true
            case .syncNeeded, .unavailable, .rootedDevice:
                false
            }
        }

        var isSkeleton: Bool {
            if case .skeleton = self {
                return true
            }
            return false
        }
    }

    struct CardInfo {
        let cardNumberEnd: String
    }
}
