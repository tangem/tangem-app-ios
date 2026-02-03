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
import TangemPay

protocol TangemPayAccountRoutable: AnyObject {
    func openTangemPayIssuingYourCardPopup()
    func openTangemPayFailedToIssueCardPopup()
    func openTangemPayKYCInProgressPopup(tangemPayKYCInteractor: TangemPayKYCInteractor)
    func openTangemPayKYCDeclinedPopup(tangemPayKYCInteractor: TangemPayKYCInteractor)
    func openTangemPayMainView(tangemPayAccount: TangemPayAccount)
}

final class TangemPayAccountViewModel: ObservableObject {
    @Published private(set) var state: ViewState = .skeleton

    private let tangemPayLocalState: TangemPayLocalState
    private weak var router: TangemPayAccountRoutable?

    private let loadableTokenBalanceViewStateBuilder = LoadableTokenBalanceViewStateBuilder()

    init(tangemPayLocalState: TangemPayLocalState, router: TangemPayAccountRoutable?) {
        self.tangemPayLocalState = tangemPayLocalState
        self.router = router

        bind()
    }

    func userDidTapView() {
        switch tangemPayLocalState {
        case .initial, .loading, .syncNeeded, .syncInProgress, .unavailable:
            break
        case .kycRequired(let tangemPayKYCInteractor):
            router?.openTangemPayKYCInProgressPopup(tangemPayKYCInteractor: tangemPayKYCInteractor)
        case .kycDeclined(let tangemPayKYCInteractor):
            router?.openTangemPayKYCDeclinedPopup(tangemPayKYCInteractor: tangemPayKYCInteractor)
        case .issuingCard:
            router?.openTangemPayIssuingYourCardPopup()
        case .failedToIssueCard:
            router?.openTangemPayFailedToIssueCardPopup()
        case .tangemPayAccount(let tangemPayAccount):
            router?.openTangemPayMainView(tangemPayAccount: tangemPayAccount)
        }
    }
}

// MARK: - Private

private extension TangemPayAccountViewModel {
    func bind() {
        Just(tangemPayLocalState)
            .flatMapLatest { state -> AnyPublisher<ViewState, Never> in
                guard !RTCUtil().checkStatus().hasIssues else {
                    return .just(output: .rootedDevice)
                }

                return switch state {
                case .initial, .loading:
                    .just(output: .skeleton)
                case .syncNeeded, .syncInProgress:
                    .just(output: .syncNeeded)
                case .unavailable:
                    .just(output: .unavailable)
                case .kycRequired:
                    .just(output: .kycInProgress)
                case .kycDeclined:
                    .just(output: .kycDeclined)
                case .issuingCard:
                    .just(output: .issuingYourCard)
                case .failedToIssueCard:
                    .just(output: .failedToIssueCard)
                case .tangemPayAccount(let tangemPayAccount):
                    Publishers.CombineLatest(
                        tangemPayAccount.cardPublisher,
                        tangemPayAccount.balancesProvider.fixedFiatTotalTokenBalanceProvider.formattedBalanceTypePublisher
                    )
                    .map { card, balanceType in
                        switch card {
                        case .none:
                            return .skeleton
                        case .some(let card):
                            let cardInfo = CardInfo(cardNumberEnd: card.cardNumberEnd)
                            let balance = LoadableTokenBalanceViewStateBuilder().build(type: balanceType)
                            return .normal(card: cardInfo, balance: balance)
                        }
                    }
                    .eraseToAnyPublisher()
                }
            }
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
}

extension TangemPayAccountViewModel {
    enum ViewState {
        case skeleton
        case kycInProgress
        case kycDeclined
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
            case .kycDeclined:
                Localization.tangempayKycHasFailed
            }
        }

        var isFullyVisible: Bool {
            switch self {
            case .kycInProgress, .issuingYourCard, .failedToIssueCard, .normal, .skeleton, .kycDeclined:
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
