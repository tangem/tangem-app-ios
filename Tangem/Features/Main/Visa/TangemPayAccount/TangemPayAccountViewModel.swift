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
    func openTangemPayKYCInProgressPopup(paeraCustomer: PaeraCustomer)
    func openTangemPayMainView(tangemPayAccount: TangemPayAccount)
}

final class TangemPayAccountViewModel: ObservableObject {
    @Published private(set) var state: ViewState = .skeleton

    private let paeraCustomer: PaeraCustomer
    private weak var router: TangemPayAccountRoutable?

    init(paeraCustomer: PaeraCustomer, router: TangemPayAccountRoutable?) {
        self.paeraCustomer = paeraCustomer
        self.router = router

        bind()
    }

    func userDidTapView() {
        switch paeraCustomer.state {
        case .none, .syncNeeded, .syncInProgress, .unavailable:
            break
        case .kyc:
            router?.openTangemPayKYCInProgressPopup(paeraCustomer: paeraCustomer)
        case .readyToIssueOrIssuing:
            router?.openTangemPayIssuingYourCardPopup()
        case .failedToIssue:
            router?.openTangemPayFailedToIssueCardPopup()
        case .tangemPayAccount(let tangemPayAccount):
            router?.openTangemPayMainView(tangemPayAccount: tangemPayAccount)
        }
    }
}

// MARK: - Private

private extension TangemPayAccountViewModel {
    func bind() {
        paeraCustomer.statePublisher
            .flatMapLatest { state -> AnyPublisher<ViewState, Never> in
                guard !RTCUtil().checkStatus().hasIssues else {
                    return .just(output: .rootedDevice)
                }

                return switch state {
                case .none:
                    .just(output: .skeleton)
                case .syncNeeded, .syncInProgress:
                    .just(output: .syncNeeded)
                case .unavailable:
                    .just(output: .unavailable)
                case .kyc:
                    .just(output: .kycInProgress)
                case .readyToIssueOrIssuing:
                    .just(output: .issuingYourCard)
                case .failedToIssue:
                    .just(output: .failedToIssueCard)
                case .tangemPayAccount(let tangemPayAccount):
                    Publishers.CombineLatest(
                        tangemPayAccount.tangemPayCardPublisher,
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
