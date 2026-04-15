//
//  TangemPayCardManagementViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import PassKit
import TangemUI
import TangemSdk
import TangemVisa
import TangemFoundation
import TangemLocalization
import TangemPay

final class TangemPayCardManagementViewModel: ObservableObject {
    let tangemPayCardDetailsViewModel: TangemPayCardDetailsViewModel

    @Published private(set) var cardRenameViewModel: TangemPayCardRenameViewModel?
    @Published private(set) var freezingState: TangemPayFreezingState = .normal
    @Published private(set) var shouldDisplayAddToApplePayGuide: Bool = false
    @Published private(set) var cardSettingsRows: [DefaultRowViewModel] = []

    private let userWalletInfo: UserWalletInfo
    private let tangemPayAccount: TangemPayAccount
    private let cardDetailsRepository: TangemPayCardDetailsRepository
    private weak var coordinator: TangemPayCardManagementRoutable?

    private var bag = Set<AnyCancellable>()

    init(
        userWalletInfo: UserWalletInfo,
        tangemPayAccount: TangemPayAccount,
        coordinator: TangemPayCardManagementRoutable
    ) {
        self.userWalletInfo = userWalletInfo
        self.tangemPayAccount = tangemPayAccount
        self.coordinator = coordinator

        cardDetailsRepository = .init(tangemPayAccount: tangemPayAccount)

        tangemPayCardDetailsViewModel = TangemPayCardDetailsViewModel(
            userWalletId: userWalletInfo.id,
            repository: cardDetailsRepository,
            cardNameDisplayMode: .interactive
        )

        tangemPayCardDetailsViewModel.onCardNameTapped = { [weak self] in
            self?.openCardRename()
        }

        bind()
    }

    func openAddToApplePayGuide() {
        Analytics.log(.visaScreenAddToWalletClicked, contextParams: .userWallet(userWalletInfo.id))
        coordinator?.openAddToApplePayGuide(
            viewModel: .init(
                userWalletId: userWalletInfo.id,
                repository: cardDetailsRepository
            )
        )
    }

    func dismissAddToApplePayGuideBanner() {
        AppSettings.shared.tangemPayShowAddToApplePayGuide = false
    }
}

// MARK: - Private

private extension TangemPayCardManagementViewModel {
    func bind() {
        tangemPayAccount.statusPublisher
            .map { $0 == .blocked ? .frozen : .normal }
            .receiveOnMain()
            .assign(to: \.freezingState, on: self, ownership: .weak)
            .store(in: &bag)

        $freezingState
            .map(\.cardDetailsState)
            .receiveOnMain()
            .assign(to: \.state, on: tangemPayCardDetailsViewModel, ownership: .weak)
            .store(in: &bag)

        $freezingState
            .receiveOnMain()
            .sink { [weak self] state in
                self?.updateCardSettingsRows(freezingState: state)
            }
            .store(in: &bag)

        Publishers.CombineLatest(
            AppSettings.shared.$tangemPayShowAddToApplePayGuide,
            tangemPayAccount.statusPublisher
        )
        .map { tangemPayShowAddToApplePayGuide, status in
            PKPaymentAuthorizationViewController.canMakePayments()
                && status == .active
                && tangemPayShowAddToApplePayGuide
        }
        .receiveOnMain()
        .assign(to: \.shouldDisplayAddToApplePayGuide, on: self, ownership: .weak)
        .store(in: &bag)
    }

    func updateCardSettingsRows(freezingState: TangemPayFreezingState) {
        let changePinRow = DefaultRowViewModel(
            title: Localization.tangempayCardDetailsChangePin,
            action: freezingState.isFreezingUnfreezingInProgress ? nil : { [weak self] in
                self?.onPin()
            }
        )

        let freezeTitle = freezingState.isFrozen
            ? Localization.tangempayCardDetailsUnfreezeCard
            : Localization.tangempayCardDetailsFreezeCard

        let freezeRow = DefaultRowViewModel(
            title: freezeTitle,
            action: freezingState.isFreezingUnfreezingInProgress ? nil : { [weak self] in
                guard let self else { return }
                if freezingState.isFrozen {
                    unfreeze()
                } else {
                    showFreezePopup()
                }
            }
        )

        cardSettingsRows = [changePinRow, freezeRow]
    }

    func setPin() {
        coordinator?.openTangemPaySetPin(tangemPayAccount: tangemPayAccount)
    }

    func checkPin() {
        coordinator?.openTangemPayCheckPin(tangemPayAccount: tangemPayAccount)
    }

    func freeze() {
        freezingState = .freezingInProgress
        tangemPayCardDetailsViewModel.state = .loading(isFrozen: tangemPayCardDetailsViewModel.state.isFrozen)

        Task { @MainActor in
            do {
                try await tangemPayAccount.freeze()
            } catch {
                freezingState = .normal
                showFreezeUnfreezeErrorToast(freeze: true)
            }
        }
    }

    func onPin() {
        Analytics.log(.visaScreenPinCodeClicked, contextParams: .userWallet(userWalletInfo.id))
        guard tangemPayAccount.card?.isPinSet == true else {
            setPin()
            return
        }

        runTask(in: self) { viewModel in
            do {
                _ = try await BiometricsUtil.requestAccess(
                    localizedReason: Localization.biometryTouchIdReason
                )
                viewModel.checkPin()
            } catch {
                VisaLogger.error("Failed to receive biometry for PIN", error: error)
                return
            }
        }
    }

    func showFreezePopup() {
        Analytics.log(.visaScreenFreezeCardClicked, contextParams: .userWallet(userWalletInfo.id))
        coordinator?.openTangemPayFreezeSheet(userWalletId: userWalletInfo.id) { [weak self] in
            self?.freeze()
        }
    }

    func unfreeze() {
        Analytics.log(.visaScreenUnfreezeCardClicked, contextParams: .userWallet(userWalletInfo.id))
        freezingState = .unfreezingInProgress
        tangemPayCardDetailsViewModel.state = .loading(isFrozen: tangemPayCardDetailsViewModel.state.isFrozen)

        Task { @MainActor in
            do {
                try await tangemPayAccount.unfreeze()
            } catch {
                freezingState = .frozen
                showFreezeUnfreezeErrorToast(freeze: false)
            }
        }
    }

    func showFreezeUnfreezeErrorToast(freeze: Bool) {
        let message = freeze
            ? Localization.tangemPayFreezeCardFailed
            : Localization.tangemPayUnfreezeCardFailed

        Toast(view: WarningToast(text: message))
            .present(
                layout: .top(padding: 20),
                type: .temporary()
            )
    }

    func openCardRename() {
        cardRenameViewModel = TangemPayCardRenameViewModel(
            userWalletId: userWalletInfo.id,
            repository: cardDetailsRepository,
            onDismiss: { [weak self] in
                self?.cardRenameViewModel = nil
            }
        )
    }
}

// MARK: - TangemPayFreezingState+TangemPayCardDetailsState

private extension TangemPayFreezingState {
    var cardDetailsState: TangemPayCardDetailsState {
        switch self {
        case .normal:
            .hidden(isFrozen: false)
        case .freezingInProgress:
            .loading(isFrozen: false)
        case .frozen:
            .hidden(isFrozen: true)
        case .unfreezingInProgress:
            .loading(isFrozen: true)
        }
    }
}
