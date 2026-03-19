//
//  TangemPayAccountViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemFoundation
import TangemVisa
import TangemLocalization
import TangemPay
import TangemUI
import TangemAssets

protocol TangemPayAccountRoutable: AnyObject {
    func openTangemPayIssuingYourCardPopup()
    func openTangemPayFailedToIssueCardPopup()
    func openTangemPayKYCInProgressPopup(paymentAccountKYCInteractor: PaymentAccountKYCInteractor)
    func openTangemPayKYCDeclinedPopup(paymentAccountKYCInteractor: PaymentAccountKYCInteractor)
    func openTangemPayMainView(tangemPayAccount: TangemPayAccount)
}

final class TangemPayAccountViewModel: ObservableObject {
    @Published private(set) var state: PaymentAccountViewState = .skeleton

    private let tangemPayLocalState: TangemPayLocalState
    private let userWalletId: UserWalletId
    private let cachedStateStorage: TangemPayCachedStateStorage
    private weak var router: TangemPayAccountRoutable?

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
        case .kycRequired(let paymentAccountKYCInteractor):
            router?.openTangemPayKYCInProgressPopup(paymentAccountKYCInteractor: paymentAccountKYCInteractor)
        case .kycDeclined(let paymentAccountKYCInteractor):
            router?.openTangemPayKYCDeclinedPopup(paymentAccountKYCInteractor: paymentAccountKYCInteractor)
        case .issuingCard:
            router?.openTangemPayIssuingYourCardPopup()
        case .failedToIssueCard:
            router?.openTangemPayFailedToIssueCardPopup()
        case .tangemPayAccount(let tangemPayAccount):
            router?.openTangemPayMainView(tangemPayAccount: tangemPayAccount)
        }
    }
}

// MARK: - PaymentAccountViewModel

extension TangemPayAccountViewModel: PaymentAccountViewModel {
    var avatarImage: Image {
        Assets.Visa.accountAvatar.image
    }

    var title: String {
        Localization.tangempayPaymentAccount
    }

    var currencySymbol: String {
        TangemPayUtilities.usdcTokenItem.currencySymbol
    }

    var subtitle: String {
        switch state {
        case .kycInProgress:
            Localization.tangempayKycInProgress
        case .pendingActivation:
            Localization.tangempayIssuingYourCard
        case .activationFailed:
            Localization.tangempayFailedToIssueCard
        case .normal(let subtitle, _):
            subtitle.map { "*" + $0 } ?? "-"
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
}

// MARK: - Private

private extension TangemPayAccountViewModel {
    func bind() {
        Just(tangemPayLocalState)
            .withWeakCaptureOf(self)
            .flatMapLatest { viewModel, state -> AnyPublisher<PaymentAccountViewState, Never> in
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
                    .just(output: .pendingActivation)
                case .failedToIssueCard:
                    .just(output: .activationFailed)
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
                            let balance = LoadableBalanceViewStateBuilder().build(type: balanceType)
                            return .normal(subtitle: card.cardNumberEnd, balance: balance)
                        }
                    }
                    .eraseToAnyPublisher()
                }
            }
            .handleEvents(receiveOutput: { [userWalletId] state in
                switch state {
                case .pendingActivation:
                    Analytics.log(.visaOnboardingVisaIssuingBannerDisplayed, contextParams: .userWallet(userWalletId))
                default:
                    break
                }
            })
            .receiveOnMain()
            .assign(to: &$state)
    }

    func makeCachedDisplayData() -> PaymentAccountViewState.CachedDisplayData? {
        switch cachedStateStorage.cachedLocalState(customerWalletId: userWalletId.stringValue) {
        case .kycRequired:
            PaymentAccountViewState.CachedDisplayData(
                subtitle: Localization.tangempayKycInProgress,
                trailing: .empty
            )

        case .kycDeclined:
            PaymentAccountViewState.CachedDisplayData(
                subtitle: Localization.tangempayKycHasFailed,
                trailing: .empty
            )

        case .issuingCard:
            PaymentAccountViewState.CachedDisplayData(
                subtitle: Localization.tangempayIssuingYourCard,
                trailing: .empty
            )

        case .failedToIssueCard:
            PaymentAccountViewState.CachedDisplayData(
                subtitle: Localization.tangempayFailedToIssueCard,
                trailing: .warningIcon
            )

        case .tangemPayAccount(let cardNumberEnd):
            PaymentAccountViewState.CachedDisplayData(
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
