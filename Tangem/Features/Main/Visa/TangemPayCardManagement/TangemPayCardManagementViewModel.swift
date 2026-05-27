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
import TangemUIUtils
import TangemSdk
import TangemVisa
import TangemFoundation
import TangemLocalization
import TangemPay
import TangemAccessibilityIdentifiers

final class TangemPayCardManagementViewModel: ObservableObject {
    let tangemPayCardDetailsViewModel: TangemPayCardDetailsViewModel

    @Published private(set) var cardRenameViewModel: TangemPayCardRenameViewModel?
    @Published private(set) var freezingState: TangemPayFreezingState = .normal
    @Published private(set) var shouldDisplayAddToApplePayGuide: Bool = false
    @Published private(set) var cardSettingsRows: [DefaultRowViewModel] = []
    @Published private(set) var dailyLimitState: TangemPayDailyLimitState = .loading
    @Published private(set) var isReissuing: Bool = false
    @Published private(set) var isLoadingReissueFee: Bool = false
    @Published var alert: AlertBinder?

    private let userWalletInfo: UserWalletInfo
    private let tangemPayAccount: TangemPayAccount
    private let cardDetailsRepository: TangemPayCardDetailsRepository
    private weak var coordinator: TangemPayCardManagementRoutable?

    private var bag = Set<AnyCancellable>()

    init(
        userWalletInfo: UserWalletInfo,
        tangemPayAccount: TangemPayAccount,
        cardDetailsRepository: TangemPayCardDetailsRepository,
        coordinator: TangemPayCardManagementRoutable
    ) {
        self.userWalletInfo = userWalletInfo
        self.tangemPayAccount = tangemPayAccount
        self.cardDetailsRepository = cardDetailsRepository
        self.coordinator = coordinator

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

    func onAppear() {
        Analytics.log(.visaCardManagementScreenOpened, contextParams: .userWallet(userWalletInfo.id))
    }

    func openChangeDailyLimit() {
        guard case .loaded = dailyLimitState else { return }

        Analytics.log(.visaScreenDailyLimitChangeClicked, contextParams: .userWallet(userWalletInfo.id))

        coordinator?.openChangeDailyLimit(tangemPayAccount: tangemPayAccount)
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

        tangemPayAccount.isReissuingCardPublisher
            .receiveOnMain()
            .assign(to: \.isReissuing, on: self, ownership: .weak)
            .store(in: &bag)

        tangemPayAccount.cardLimitPublisher
            .map { amount -> TangemPayDailyLimitState in
                let formatter = BalanceFormatter().makeDefaultFiatFormatter(
                    forCurrencyCode: AppConstants.usdCurrencyCode,
                    locale: .posixEnUS,
                    formattingOptions: .init(minFractionDigits: 0, maxFractionDigits: 0, formatEpsilonAsLowestRepresentableValue: false)
                )
                if let amount, let limit = formatter.string(from: .init(value: amount)) {
                    return .loaded(currentLimit: limit)
                } else {
                    return .error
                }
            }
            .prepend(.loading)
            .receiveOnMain()
            .assign(to: \.dailyLimitState, on: self, ownership: .weak)
            .store(in: &bag)
    }

    func updateCardSettingsRows(freezingState: TangemPayFreezingState) {
        let changePinRow = DefaultRowViewModel(
            title: Localization.tangempayCardDetailsChangePin,
            accessibilityIdentifier: TangemPayAccessibilityIdentifiers.changePinRow,
            action: freezingState.isFreezingUnfreezingInProgress ? nil : { [weak self] in
                self?.onPin()
            }
        )

        let freezeTitle = freezingState.isFrozen
            ? Localization.tangempayCardDetailsUnfreezeCard
            : Localization.tangempayCardDetailsFreezeCard

        let freezeRowIdentifier = freezingState.isFrozen
            ? TangemPayAccessibilityIdentifiers.freezeCardRowStateFrozen
            : TangemPayAccessibilityIdentifiers.freezeCardRowStateActive

        let freezeRow = DefaultRowViewModel(
            title: freezeTitle,
            accessibilityIdentifier: freezeRowIdentifier,
            action: freezingState.isFreezingUnfreezingInProgress ? nil : { [weak self] in
                guard let self else { return }
                if freezingState.isFrozen {
                    unfreeze()
                } else {
                    showFreezePopup()
                }
            }
        )

        let replaceCardRow = DefaultRowViewModel(
            title: Localization.tangempayCardDetailsReissueCard,
            action: freezingState.isFreezingUnfreezingInProgress ? nil : { [weak self] in
                self?.onReplaceCard()
            }
        )

        cardSettingsRows = [changePinRow, freezeRow, replaceCardRow]
    }

    func onReplaceCard() {
        Analytics.log(.visaReplaceCardClicked, contextParams: .userWallet(userWalletInfo.id))
        coordinator?.openTangemPayReissueSheet(
            userWalletId: userWalletInfo.id,
            tangemPayAccount: tangemPayAccount,
            onLoadingChange: { [weak self] in self?.isLoadingReissueFee = $0 },
            onError: { [weak self] in self?.showReissueError() }
        )
    }

    func showReissueError() {
        alert = AlertBinder(
            title: Localization.commonSomethingWentWrong,
            message: Localization.tangempayReissueCardFeeUnreachableErrorTitle
        )
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
        let renameViewModel = TangemPayCardRenameViewModel(
            userWalletId: userWalletInfo.id,
            repository: cardDetailsRepository,
            onDismiss: { [weak self] in
                self?.cardRenameViewModel = nil
            }
        )

        renameViewModel.$alert.assign(to: &$alert)

        cardRenameViewModel = renameViewModel
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
