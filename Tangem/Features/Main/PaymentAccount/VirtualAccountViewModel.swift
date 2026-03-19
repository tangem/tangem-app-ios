//
//  VirtualAccountViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemFoundation
import TangemLocalization
import TangemPay
import TangemUI
import TangemAssets

final class VirtualAccountViewModel: ObservableObject {
    @Published private(set) var state: PaymentAccountViewState = .skeleton

    private let virtualAccountLocalState: VirtualAccountLocalState
    private let userWalletId: UserWalletId
    private let cachedStateStorage: VirtualAccountCachedStateStorage
    private weak var router: VirtualAccountAccountRoutable?

    init(
        virtualAccountLocalState: VirtualAccountLocalState,
        userWalletId: UserWalletId,
        cachedStateStorage: VirtualAccountCachedStateStorage,
        router: VirtualAccountAccountRoutable?
    ) {
        self.virtualAccountLocalState = virtualAccountLocalState
        self.userWalletId = userWalletId
        self.cachedStateStorage = cachedStateStorage
        self.router = router

        bind()
    }

    func userDidTapView() {
        switch virtualAccountLocalState {
        case .loading, .syncNeeded, .syncInProgress, .unavailable, .userCreatedWalletBlocked:
            break
        case .orderCreated:
            break
        case .kycRequired(let paymentAccountKYCInteractor):
            router?.openVirtualAccountKYCInProgressPopup(
                paymentAccountKYCInteractor: paymentAccountKYCInteractor
            )
        case .kycDeclined(let paymentAccountKYCInteractor):
            router?.openVirtualAccountKYCDeclinedPopup(
                paymentAccountKYCInteractor: paymentAccountKYCInteractor
            )
        case .provisioning:
            router?.openVirtualAccountProvisioningPopup()
        case .failedToProvision:
            router?.openVirtualAccountFailedToProvisionPopup()
        case .active(let activeState):
            router?.openVirtualAccountMainView(activeState: activeState)
        }
    }
}

// MARK: - PaymentAccountViewModel

// [REDACTED_TODO_COMMENT]
extension VirtualAccountViewModel: PaymentAccountViewModel {
    var avatarImage: Image {
        Assets.Visa.accountAvatar.image
    }

    var title: String {
        Localization.tangempayPaymentAccount
    }

    var currencySymbol: String {
        VirtualAccountUtilities.usdcTokenItem.currencySymbol
    }

    var subtitle: String {
        switch state {
        case .kycInProgress:
            Localization.tangempayKycInProgress
        case .pendingActivation:
            Localization.tangempayIssuingYourCard
        case .activationFailed:
            Localization.tangempayFailedToIssueCard
        case .normal:
            Localization.tangempayPaymentAccount
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

private extension VirtualAccountViewModel {
    func bind() {
        Just(virtualAccountLocalState)
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
                case .unavailable, .userCreatedWalletBlocked:
                    .just(output: .unavailable(cached: viewModel.makeCachedDisplayData()))
                case .orderCreated, .kycRequired:
                    .just(output: .kycInProgress)
                case .kycDeclined:
                    .just(output: .kycDeclined)
                case .provisioning:
                    .just(output: .pendingActivation)
                case .failedToProvision:
                    .just(output: .activationFailed)
                case .active:
                    .just(output: .normal(subtitle: nil, balance: .empty))
                }
            }
            .receiveOnMain()
            .assign(to: &$state)
    }

    // [REDACTED_TODO_COMMENT]
    func makeCachedDisplayData() -> PaymentAccountViewState.CachedDisplayData? {
        switch cachedStateStorage.cachedLocalState(customerWalletId: userWalletId.stringValue) {
        case .orderCreated, .kycRequired:
            PaymentAccountViewState.CachedDisplayData(
                subtitle: Localization.tangempayKycInProgress,
                trailing: .empty
            )

        case .kycDeclined:
            PaymentAccountViewState.CachedDisplayData(
                subtitle: Localization.tangempayKycHasFailed,
                trailing: .empty
            )

        case .provisioning:
            PaymentAccountViewState.CachedDisplayData(
                subtitle: Localization.tangempayIssuingYourCard,
                trailing: .empty
            )

        case .failedToProvision:
            PaymentAccountViewState.CachedDisplayData(
                subtitle: Localization.tangempayFailedToIssueCard,
                trailing: .warningIcon
            )

        case .active:
            PaymentAccountViewState.CachedDisplayData(
                subtitle: Localization.tangempayPaymentAccount,
                trailing: .empty
            )

        case .none:
            nil
        }
    }
}
