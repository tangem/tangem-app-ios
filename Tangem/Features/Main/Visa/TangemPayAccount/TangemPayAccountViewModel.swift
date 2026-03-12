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
import TangemUI

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
    private let userWalletId: UserWalletId
    private let cachedStateStorage: TangemPayCachedStateStorage
    private weak var router: TangemPayAccountRoutable?

    private let loadableTokenBalanceViewStateBuilder = LoadableBalanceViewStateBuilder()

    init(
        tangemPayLocalState: TangemPayLocalState,
        userWalletId: UserWalletId,
        cachedStateStorage: TangemPayCachedStateStorage,
        router: TangemPayAccountRoutable?
    ) {
        self.tangemPayLocalState = tangemPayLocalState
        self.userWalletId = userWalletId
        self.cachedStateStorage = cachedStateStorage
        self.router = router

        bind()
    }

    func userDidTapView() {
        switch tangemPayLocalState {
        case .loading, .syncNeeded, .syncInProgress, .unavailable:
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
            .withWeakCaptureOf(self)
            .flatMapLatest { viewModel, state -> AnyPublisher<ViewState, Never> in
                guard !RTCUtil().checkStatus().hasIssues else {
                    return .just(output: .rootedDevice)
                }

                return switch state {
                case .loading:
                    .just(output: .skeleton)
                case .syncNeeded, .syncInProgress:
                    .just(output: .syncNeeded)
                case .unavailable:
                    .just(output: .unavailable(cached: viewModel.makeCachedDisplayData()))
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
                            let balance = LoadableBalanceViewStateBuilder().build(type: balanceType)
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

    func makeCachedDisplayData() -> CachedDisplayData? {
        switch cachedStateStorage.cachedLocalState(customerWalletId: userWalletId.stringValue) {
        case .kycRequired:
            CachedDisplayData(
                subtitle: Localization.tangempayKycInProgress,
                trailing: .empty
            )

        case .kycDeclined:
            CachedDisplayData(
                subtitle: Localization.tangempayKycHasFailed,
                trailing: .empty
            )

        case .issuingCard:
            CachedDisplayData(
                subtitle: Localization.tangempayIssuingYourCard,
                trailing: .empty
            )

        case .failedToIssueCard:
            CachedDisplayData(
                subtitle: Localization.tangempayFailedToIssueCard,
                trailing: .warningIcon
            )

        case .tangemPayAccount(let cardNumberEnd):
            CachedDisplayData(
                subtitle: cardNumberEnd.map { "*" + $0 },
                trailing: .balance(cachedBalanceState())
            )

        case .none:
            nil
        }
    }

    func cachedBalanceState() -> LoadableBalanceView.State {
        let repository = CommonTokenBalancesRepository(userWalletId: userWalletId)
        let walletModelId = WalletModelId(tokenItem: TangemPayUtilities.usdcTokenItem)

        guard let cachedBalance = repository.balance(walletModelId: walletModelId, type: .available) else {
            return .empty
        }

        let formatted = BalanceFormatter().formatFiatBalance(
            cachedBalance.balance,
            currencyCode: TangemPayUtilities.fiatItem.currencyCode
        )
        return .loaded(text: .string(formatted))
    }
}

extension TangemPayAccountViewModel {
    enum ViewState {
        case skeleton
        case kycInProgress
        case kycDeclined
        case issuingYourCard
        case failedToIssueCard
        case normal(card: CardInfo, balance: LoadableBalanceView.State)
        case syncNeeded
        case unavailable(cached: CachedDisplayData? = nil)
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
            case .unavailable(let cached):
                cached?.subtitle ?? "—"
            case .skeleton:
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

    struct CachedDisplayData {
        let subtitle: String?
        let trailing: Trailing

        enum Trailing {
            case empty
            case warningIcon
            case balance(LoadableBalanceView.State)
        }
    }

    struct CardInfo {
        let cardNumberEnd: String
    }
}
