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
    @Published private(set) var cardDetailsItems: [CardDetailsItem] = []
    @Published var selectedCardId: String?
    @Published private(set) var cardRenameViewModel: TangemPayCardRenameViewModel?
    @Published private(set) var freezingState: TangemPayFreezingState = .normal
    @Published private(set) var shouldDisplayAddToApplePayGuide: Bool = false
    @Published private(set) var cardSettingsRows: [DefaultRowViewModel] = []
    @Published private(set) var dailyLimitState: TangemPayDailyLimitState = .loading
    @Published private(set) var isIssuing: Bool = false
    @Published private(set) var isReissuing: Bool = false
    @Published var alert: AlertBinder?

    var hasMultipleCards: Bool {
        cardDetailsItems.count > 1
    }

    private let userWalletInfo: UserWalletInfo
    private let tangemPayAccount: TangemPayAccount
    @Injected(\.tangemPayAssembly) private var tangemPayAssembly: TangemPayAssembly
    private weak var coordinator: TangemPayCardManagementRoutable?

    private var bag = Set<AnyCancellable>()
    private var productInstanceIdByOrderId: [String: String] = [:]

    init(
        userWalletInfo: UserWalletInfo,
        tangemPayAccount: TangemPayAccount,
        initialEntry: TangemPayCardEntry,
        coordinator: TangemPayCardManagementRoutable
    ) {
        self.userWalletInfo = userWalletInfo
        self.tangemPayAccount = tangemPayAccount
        selectedCardId = initialEntry.id
        isIssuing = initialEntry.isIssuing
        self.coordinator = coordinator

        rebuildCardDetailsItems(entries: tangemPayAccount.cardEntries)

        bind()
    }

    func onAppear() {
        Analytics.log(.visaCardManagementScreenOpened, contextParams: .userWallet(userWalletInfo.id))
    }

    func openChangeDailyLimit() {
        guard case .loaded = dailyLimitState, let card = currentCard else { return }

        Analytics.log(.visaScreenDailyLimitChangeClicked, contextParams: .userWallet(userWalletInfo.id))

        coordinator?.openChangeDailyLimit(card: card)
    }

    func openAddToApplePayGuide() {
        guard let card = currentCard else { return }
        Analytics.log(.visaScreenAddToWalletClicked, contextParams: .userWallet(userWalletInfo.id))
        coordinator?.openAddToApplePayGuide(
            viewModel: TangemPayCardDetailsViewModel(
                userWalletId: userWalletInfo.id,
                repository: tangemPayAssembly.makeCardDetailsRepository(for: card)
            )
        )
    }

    func dismissAddToApplePayGuideBanner() {
        AppSettings.shared.tangemPayShowAddToApplePayGuide = false
    }

    private var currentCard: TangemPayCard? {
        guard let id = selectedCardId else { return nil }
        return tangemPayAccount.card(cardId: id)
    }
}

extension TangemPayCardManagementViewModel {
    struct CardDetailsItem: Identifiable {
        let id: String
        let content: Content

        enum Content {
            case issued(TangemPayCardDetailsViewModel)
            case issuing
        }
    }
}

// MARK: - Private

private extension TangemPayCardManagementViewModel {
    func bind() {
        tangemPayAccount.cardEntriesPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { vm, entries in vm.applyEntries(entries) }
            .store(in: &bag)

        Publishers.CombineLatest(
            tangemPayAccount.cardEntriesPublisher,
            $selectedCardId
        )
        .map { entries, id -> Bool in
            guard let id else { return false }
            return entries.first(where: { $0.id == id })?.isIssuing ?? false
        }
        .receiveOnMain()
        .assign(to: \.isIssuing, on: self, ownership: .weak)
        .store(in: &bag)

        $selectedCardId
            .map { [weak tangemPayAccount] id -> AnyPublisher<TangemPayFreezingState, Never> in
                guard let id, let card = tangemPayAccount?.card(cardId: id) else {
                    return Just(.unavailable).eraseToAnyPublisher()
                }
                return Publishers.CombineLatest(card.statusPublisher, card.isFreezingUnfreezingPublisher)
                    .map { status, isPending -> TangemPayFreezingState in
                        switch (status == .blocked, isPending) {
                        case (false, false): .normal
                        case (false, true): .freezingInProgress
                        case (true, false): .frozen
                        case (true, true): .unfreezingInProgress
                        }
                    }
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .receiveOnMain()
            .assign(to: \.freezingState, on: self, ownership: .weak)
            .store(in: &bag)

        $selectedCardId
            .map { [weak tangemPayAccount] id -> AnyPublisher<TangemPayDailyLimitState, Never> in
                guard let id, let card = tangemPayAccount?.card(cardId: id) else {
                    return Just(.unavailable).eraseToAnyPublisher()
                }
                return card.cardLimitPublisher
                    .map { amount -> TangemPayDailyLimitState in
                        let formatter = BalanceFormatter().makeDefaultFiatFormatter(
                            forCurrencyCode: AppConstants.usdCurrencyCode,
                            locale: .posixEnUS,
                            formattingOptions: .init(minFractionDigits: 0, maxFractionDigits: 0, formatEpsilonAsLowestRepresentableValue: false)
                        )
                        if let limit = formatter.string(from: .init(value: amount)) {
                            return .loaded(currentLimit: limit)
                        }
                        return .error
                    }
                    .prepend(.loading)
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .receiveOnMain()
            .assign(to: \.dailyLimitState, on: self, ownership: .weak)
            .store(in: &bag)

        $freezingState
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { vm, freezing in
                guard let id = vm.selectedCardId,
                      case .issued(let detailsVM) = vm.cardDetailsItems.first(where: { $0.id == id })?.content else {
                    return
                }
                detailsVM.state = freezing.cardDetailsState
            }
            .store(in: &bag)

        Publishers.CombineLatest(
            AppSettings.shared.$tangemPayShowAddToApplePayGuide,
            tangemPayAccount.statePublisher
        )
        .map { showGuide, customerState in
            PKPaymentAuthorizationViewController.canMakePayments()
                && customerState == .active
                && showGuide
        }
        .receiveOnMain()
        .assign(to: \.shouldDisplayAddToApplePayGuide, on: self, ownership: .weak)
        .store(in: &bag)

        // Track reissue progress for the currently selected card. In the multi-card model
        // reissue state lives on each `TangemPayCard.isReissuingPublisher`; we switch the
        // observed publisher whenever the user selects a different card.
        $selectedCardId
            .map { [weak tangemPayAccount] id -> AnyPublisher<Bool, Never> in
                guard let id, let card = tangemPayAccount?.card(cardId: id) else {
                    return Just(false).eraseToAnyPublisher()
                }
                return card.isReissuingPublisher
            }
            .switchToLatest()
            .receiveOnMain()
            .assign(to: \.isReissuing, on: self, ownership: .weak)
            .store(in: &bag)

        $freezingState
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { vm, state in
                vm.updateCardSettingsRows(freezingState: state)
            }
            .store(in: &bag)
    }

    func applyEntries(_ entries: [TangemPayCardEntry]) {
        captureProductInstanceIds(from: tangemPayAccount.activeIssueOrders)

        let resolvedId = Self.resolveSelectedId(
            currentId: selectedCardId,
            entries: entries,
            productInstanceIdByOrderId: productInstanceIdByOrderId
        )
        rebuildCardDetailsItems(entries: entries)

        guard let resolvedId else {
            selectedCardId = nil
            return
        }

        if entries.contains(where: { $0.id == resolvedId }) {
            if resolvedId != selectedCardId {
                selectedCardId = resolvedId
            }
        } else {
            coordinator?.popToCardListScreen()
        }
    }

    func captureProductInstanceIds(from orders: [TangemPayOrderResponse]) {
        for order in orders {
            if let pid = order.data?.productInstanceId {
                productInstanceIdByOrderId[order.id] = pid
            }
        }
    }

    static func resolveSelectedId(
        currentId: String?,
        entries: [TangemPayCardEntry],
        productInstanceIdByOrderId: [String: String]
    ) -> String? {
        guard let currentId else { return nil }
        let productInstanceId = productInstanceIdByOrderId[currentId] ?? currentId
        let pendingInstances = entries.compactMap(\.pendingProductInstance)
        let cards = entries.compactMap(\.card)

        if pendingInstances.contains(where: { $0.id == productInstanceId }) {
            return productInstanceId
        }
        if let card = cards.first(where: { $0.productInstance.id == productInstanceId }) {
            return card.cardId
        }
        return currentId
    }

    func rebuildCardDetailsItems(entries: [TangemPayCardEntry]) {
        var existing: [String: CardDetailsItem] = .init(
            uniqueKeysWithValues: cardDetailsItems.map { ($0.id, $0) }
        )

        cardDetailsItems = entries.map { entry in
            let existingItem = existing.removeValue(forKey: entry.id)
            switch entry {
            case .issued(let card):
                if case .issued(let preservedVM) = existingItem?.content {
                    return CardDetailsItem(id: card.cardId, content: .issued(preservedVM))
                }
                let detailsVM = TangemPayCardDetailsViewModel(
                    userWalletId: userWalletInfo.id,
                    repository: tangemPayAssembly.makeCardDetailsRepository(for: card),
                    cardNameDisplayMode: .interactive
                )
                detailsVM.onCardNameTapped = { [weak self] in
                    self?.openCardRename()
                }
                return CardDetailsItem(id: card.cardId, content: .issued(detailsVM))
            case .issuing:
                return CardDetailsItem(id: entry.id, content: .issuing)
            }
        }
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
        guard let card = currentCard else { return }
        Analytics.log(.visaReplaceCardClicked, contextParams: .userWallet(userWalletInfo.id))
        coordinator?.openTangemPayReissueSheet(
            userWalletId: userWalletInfo.id,
            card: card,
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
        guard let card = currentCard else { return }
        coordinator?.openTangemPaySetPin(card: card)
    }

    func checkPin() {
        guard let card = currentCard else { return }
        coordinator?.openTangemPayCheckPin(card: card)
    }

    func freeze() {
        guard let card = currentCard else { return }

        Task { @MainActor in
            do {
                try await card.freeze()
            } catch {
                showFreezeUnfreezeErrorToast(freeze: true)
            }
        }
    }

    func onPin() {
        guard let card = currentCard else { return }
        Analytics.log(.visaScreenPinCodeClicked, contextParams: .userWallet(userWalletInfo.id))
        guard card.isPinSet else {
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
        guard let card = currentCard else { return }
        Analytics.log(.visaScreenUnfreezeCardClicked, contextParams: .userWallet(userWalletInfo.id))

        Task { @MainActor in
            do {
                try await card.unfreeze()
            } catch {
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
        guard let card = currentCard else { return }
        cardRenameViewModel = TangemPayCardRenameViewModel(
            userWalletId: userWalletInfo.id,
            repository: tangemPayAssembly.makeCardDetailsRepository(for: card),
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
        case .normal, .unavailable:
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
