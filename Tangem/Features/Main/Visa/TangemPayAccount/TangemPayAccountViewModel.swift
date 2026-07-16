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

    private var multipleCardsEnabled: Bool {
        FeatureProvider.isAvailable(.tangemPayMultipleCards)
    }

    private let tangemPayLocalState: TangemPayLocalState
    private let userWalletId: UserWalletId
    private let cachedStateStorage: TangemPayCachedStateStorage
    private let lastKnownTangemPayAccount: TangemPayAccount?
    private weak var router: TangemPayAccountRoutable?

    private let loadableTokenBalanceViewStateBuilder = LoadableBalanceViewStateBuilder()

    init(
        tangemPayLocalState: TangemPayLocalState,
        userWalletId: UserWalletId,
        cachedStateStorage: TangemPayCachedStateStorage,
        lastKnownTangemPayAccount: TangemPayAccount?,
        router: TangemPayAccountRoutable?
    ) {
        self.tangemPayLocalState = tangemPayLocalState
        self.userWalletId = userWalletId
        self.cachedStateStorage = cachedStateStorage
        self.lastKnownTangemPayAccount = lastKnownTangemPayAccount
        self.router = router

        bind()
    }

    func userDidTapView() {
        guard !RTCUtil.isRootedDevice else { return }

        switch tangemPayLocalState {
        case .loading, .syncInProgress:
            break
        case .unavailable, .syncNeeded:
            if let lastKnownTangemPayAccount {
                router?.openTangemPayMainView(tangemPayAccount: lastKnownTangemPayAccount)
            }
        case .kycRequired(let tangemPayKYCInteractor):
            router?.openTangemPayKYCInProgressPopup(tangemPayKYCInteractor: tangemPayKYCInteractor)
        case .kycDeclined(let tangemPayKYCInteractor):
            router?.openTangemPayKYCDeclinedPopup(tangemPayKYCInteractor: tangemPayKYCInteractor)
        case .issuingCard:
            router?.openTangemPayIssuingYourCardPopup()
        case .failedToIssueCard:
            router?.openTangemPayFailedToIssueCardPopup()
        case .tangemPayAccount(let tangemPayAccount), .cardDeactivated(let tangemPayAccount):
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
                guard !RTCUtil.isRootedDevice else {
                    return .just(output: .rootedDevice)
                }

                return switch state {
                case .loading:
                    .just(output: .skeleton)
                case .syncNeeded, .syncInProgress:
                    .just(output: .syncNeeded(cached: viewModel.makeCachedDisplayData()))
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
                    viewModel.multipleCardsEnabled
                        ? viewModel.makeAccountViewStatePublisherNew(tangemPayAccount)
                        : viewModel.makeAccountViewStatePublisherLegacy(tangemPayAccount)
                case .cardDeactivated(let tangemPayAccount):
                    tangemPayAccount.balancesProvider.fixedFiatTotalTokenBalanceProvider.formattedBalanceTypePublisher
                        .map { balanceType in
                            let balance = LoadableBalanceViewStateBuilder().build(type: balanceType)
                            return .cardDeactivated(balance: balance)
                        }
                        .eraseToAnyPublisher()
                }
            }
            .handleEvents(receiveOutput: { [userWalletId] state in
                switch state {
                case .issuingYourCard:
                    Analytics.log(.visaOnboardingVisaIssuingBannerDisplayed, contextParams: .userWallet(userWalletId))
                default:
                    break
                }
            })
            .receiveOnMain()
            .assign(to: &$state)
    }

    func makeAccountViewStatePublisherLegacy(_ tangemPayAccount: TangemPayAccount) -> AnyPublisher<ViewState, Never> {
        Publishers.CombineLatest3(
            tangemPayAccount.cardPublisher,
            tangemPayAccount.balancesProvider.fixedFiatTotalTokenBalanceProvider.formattedBalanceTypePublisher,
            tangemPayAccount.isReissuingCardPublisher
        )
        .map { card, balanceType, isReissuing in
            if isReissuing {
                let balance = LoadableBalanceViewStateBuilder().build(type: balanceType)
                return .replacingCard(balance: balance)
            }

            switch card {
            case .none:
                return .skeleton
            case .some(let card):
                let cardInfo = CardInfo(cardNumberEnd: card.cardNumberEnd)
                let balance = LoadableBalanceViewStateBuilder().build(type: balanceType)
                return .normal(card: cardInfo, balance: balance, cardCount: 1)
            }
        }
        .eraseToAnyPublisher()
    }

    func makeAccountViewStatePublisherNew(_ tangemPayAccount: TangemPayAccount) -> AnyPublisher<ViewState, Never> {
        Publishers.CombineLatest3(
            tangemPayAccount.cardsPublisher,
            tangemPayAccount.balancesProvider.fixedFiatTotalTokenBalanceProvider.formattedBalanceTypePublisher,
            tangemPayAccount.anyCardReissuingPublisher
        )
        .map { cards, balanceType, isAnyReissuing in
            let balance = LoadableBalanceViewStateBuilder().build(type: balanceType)
            if isAnyReissuing {
                return .replacingCard(balance: balance)
            }
            guard let firstActive = cards.first(where: { $0.productInstance.status == .active || $0.productInstance.status == .blocked }) else {
                return .skeleton
            }
            return .normal(
                card: CardInfo(cardNumberEnd: firstActive.cardNumberEnd),
                balance: balance,
                cardCount: cards.count
            )
        }
        .eraseToAnyPublisher()
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

        case .tangemPayAccount(let cardsSummary):
            CachedDisplayData(
                subtitle: cachedAccountSubtitle(cardsSummary),
                trailing: .balance(cachedBalanceState())
            )

        case .cardDeactivated:
            CachedDisplayData(
                subtitle: Localization.tangempayStatusDeactivated,
                trailing: .balance(cachedBalanceState())
            )

        case .none:
            nil
        }
    }

    func cachedAccountSubtitle(_ summary: TangemPayCachedLocalState.CardsSummary) -> String {
        switch summary {
        case .single(let cardNumberEnd):
            "*" + cardNumberEnd
        case .multiple(let count):
            Localization.tangempayCardsCount(count)
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
        case normal(card: CardInfo, balance: LoadableBalanceView.State, cardCount: Int)
        case cardDeactivated(balance: LoadableBalanceView.State)
        case syncNeeded(cached: CachedDisplayData? = nil)
        case replacingCard(balance: LoadableBalanceView.State)
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
            case .normal(let card, _, let count):
                count > 1 ? Localization.tangempayCardsCount(count) : "*" + card.cardNumberEnd
            case .cardDeactivated:
                Localization.tangempayStatusDeactivated
            case .replacingCard:
                Localization.tangempayReissueCardInProgress
            case .syncNeeded:
                Localization.commonSessionExpired
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
            case .kycInProgress, .issuingYourCard, .failedToIssueCard, .normal, .skeleton, .kycDeclined, .cardDeactivated, .replacingCard:
                true
            case .syncNeeded, .unavailable, .rootedDevice:
                false
            }
        }

        var showsCachedIndicator: Bool {
            switch self {
            case .unavailable(let cached), .syncNeeded(let cached):
                return cached != nil
            case .skeleton, .normal, .kycInProgress, .kycDeclined,
                 .issuingYourCard, .failedToIssueCard, .rootedDevice,
                 .replacingCard, .cardDeactivated:
                return false
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
