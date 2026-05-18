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
    @Published private(set) var dailyLimitState: TangemPayDailyLimitState?
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

    private let dailyLimitFormatter = BalanceFormatter().makeDefaultFiatFormatter(
        forCurrencyCode: AppConstants.usdCurrencyCode,
        locale: .posixEnUS,
        formattingOptions: .init(
            minFractionDigits: 0,
            maxFractionDigits: 0,
            formatEpsilonAsLowestRepresentableValue: false
        )
    )

    /// Stable handle to the user's selection across the `order → pending PI → issued card`
    /// lifecycle. Each transition changes `entry.id`, but `productInstanceId` stays put once
    /// the BFF has assigned one — so we anchor on that and fall back to the original entry id
    /// only while the order hasn't been tied to a product instance yet.
    private var selectionAnchor: SelectionAnchor?

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
        selectionAnchor = SelectionAnchor(entry: initialEntry)

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
        /// Stable identity across the `order → pending PI → issued card` lifecycle, used to
        /// preserve embedded view-model state when an entry's `id` flips from `orderId` to
        /// `cardId`. `nil` only for fresh `.issuing(.order)` entries the BFF hasn't tied to
        /// a product instance yet.
        let productInstanceId: String?
        let content: Content

        enum Content {
            case issued(TangemPayCardDetailsViewModel)
            case issuing
        }
    }
}

// MARK: - Selection anchor

private extension TangemPayCardManagementViewModel {
    struct SelectionAnchor {
        var entryId: String
        var productInstanceId: String?

        init(entry: TangemPayCardEntry) {
            entryId = entry.id
            productInstanceId = entry.productInstanceId
        }

        /// Picks up a `productInstanceId` for the original entry if the BFF has now assigned
        /// one — relevant only while the user is anchored to a freshly placed `.issuing(.order)`
        /// that hasn't yet been tied to a product instance.
        mutating func upgradeProductInstanceIdIfDiscovered(in entries: [TangemPayCardEntry]) {
            guard productInstanceId == nil,
                  let entry = entries.first(where: { $0.id == entryId }) else { return }
            productInstanceId = entry.productInstanceId
        }

        func resolve(in entries: [TangemPayCardEntry]) -> TangemPayCardEntry? {
            if let pid = productInstanceId,
               let entry = entries.first(where: { $0.productInstanceId == pid }) {
                return entry
            }
            return entries.first(where: { $0.id == entryId })
        }
    }
}

// MARK: - Bindings

private extension TangemPayCardManagementViewModel {
    func bind() {
        // Re-anchor whenever the user (or our own resolution) sets a new selection.
        $selectedCardId
            .withWeakCaptureOf(self)
            .sink { vm, id in
                guard let id,
                      let entry = vm.tangemPayAccount.cardEntries.first(where: { $0.id == id }) else { return }
                vm.selectionAnchor = SelectionAnchor(entry: entry)
            }
            .store(in: &bag)

        tangemPayAccount.cardEntriesPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { vm, entries in vm.applyEntries(entries) }
            .store(in: &bag)

        // `isIssuing` is per-entry (covers `.issuing(.order)` where no `TangemPayCard` exists
        // yet), so it observes the entries list directly rather than a per-card publisher.
        Publishers.CombineLatest(tangemPayAccount.cardEntriesPublisher, $selectedCardId)
            .map { entries, id -> Bool in
                guard let id else { return false }
                return entries.first(where: { $0.id == id })?.isIssuing ?? false
            }
            .removeDuplicates()
            .receiveOnMain()
            .assign(to: \.isIssuing, on: self, ownership: .weak)
            .store(in: &bag)

        bindSelectedCard(
            fallback: TangemPayFreezingState.unavailable,
            publisher: { card in
                Publishers.CombineLatest(card.statusPublisher, card.isFreezingUnfreezingPublisher)
                    .map { status, isPending -> TangemPayFreezingState in
                        switch (status == .blocked, isPending) {
                        case (false, false): .normal
                        case (false, true): .freezingInProgress
                        case (true, false): .frozen
                        case (true, true): .unfreezingInProgress
                        }
                    }
                    .eraseToAnyPublisher()
            },
            to: \.freezingState
        )

        bindSelectedCard(
            fallback: TangemPayDailyLimitState?.none,
            publisher: { [dailyLimitFormatter] card in
                let initial: TangemPayDailyLimitState? = .loading
                return card.cardLimitPublisher
                    .map { amount -> TangemPayDailyLimitState? in
                        if let formatted = dailyLimitFormatter.string(from: .init(value: amount)) {
                            return .loaded(TangemPayDailyLimit(currentLimit: formatted))
                        }
                        return .error
                    }
                    .prepend(initial)
                    .eraseToAnyPublisher()
            },
            to: \.dailyLimitState
        )

        // Reissue progress lives on each `TangemPayCard.isReissuingPublisher` in the multi-card
        // model — switch the observed publisher whenever the user selects a different card.
        bindSelectedCard(
            fallback: false,
            publisher: { $0.isReissuingPublisher },
            to: \.isReissuing
        )

        // `freezingState` drives both the embedded card-details VM state and the action rows.
        $freezingState
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { vm, freezing in
                vm.propagateFreezingStateToDetailsVM(freezing)
                vm.updateCardSettingsRows(freezingState: freezing)
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
    }

    /// Subscribes to a per-card publisher, switching whenever `selectedCardId` changes. When no
    /// card is selected (or the selection points at an `.issuing(.order)` entry with no
    /// `TangemPayCard` yet), `fallback` is emitted instead.
    func bindSelectedCard<T>(
        fallback: T,
        publisher: @escaping (TangemPayCard) -> AnyPublisher<T, Never>,
        to keyPath: ReferenceWritableKeyPath<TangemPayCardManagementViewModel, T>
    ) {
        $selectedCardId
            .map { [weak tangemPayAccount] id -> AnyPublisher<T, Never> in
                guard let id, let card = tangemPayAccount?.card(cardId: id) else {
                    return Just(fallback).eraseToAnyPublisher()
                }
                return publisher(card)
            }
            .switchToLatest()
            .receiveOnMain()
            .assign(to: keyPath, on: self, ownership: .weak)
            .store(in: &bag)
    }
}

// MARK: - Private

private extension TangemPayCardManagementViewModel {
    func applyEntries(_ entries: [TangemPayCardEntry]) {
        selectionAnchor?.upgradeProductInstanceIdIfDiscovered(in: entries)

        let resolved = selectionAnchor?.resolve(in: entries)
        rebuildCardDetailsItems(entries: entries)

        guard let resolved else {
            // Anchor was set but the selection's card/order has vanished from BFF entirely.
            // Pop back to the card list (FR-MOB-EDGE-007) and forget the anchor so we don't
            // re-pop on the next entries refresh.
            if selectionAnchor != nil {
                coordinator?.popToCardListScreen()
                selectionAnchor = nil
            }
            selectedCardId = nil
            return
        }

        if resolved.id != selectedCardId {
            selectedCardId = resolved.id
        }
    }

    func rebuildCardDetailsItems(entries: [TangemPayCardEntry]) {
        // Two-axis lookup: prefer `productInstanceId` (stable across order → PI → card
        // transitions) and fall back to `id` for entries the BFF hasn't tied to a product
        // instance yet. This is the same anchoring strategy `SelectionAnchor` uses.
        var existingByProductInstanceId: [String: CardDetailsItem] = [:]
        var existingById: [String: CardDetailsItem] = [:]
        for item in cardDetailsItems {
            existingById[item.id] = item
            if let pid = item.productInstanceId {
                existingByProductInstanceId[pid] = item
            }
        }

        cardDetailsItems = entries.map { entry in
            let preservedItem: CardDetailsItem? = {
                if let pid = entry.productInstanceId, let match = existingByProductInstanceId[pid] {
                    return match
                }
                return existingById[entry.id]
            }()

            switch entry {
            case .issued(let card):
                if case .issued(let preservedVM) = preservedItem?.content {
                    return CardDetailsItem(
                        id: card.cardId,
                        productInstanceId: entry.productInstanceId,
                        content: .issued(preservedVM)
                    )
                }
                let detailsVM = TangemPayCardDetailsViewModel(
                    userWalletId: userWalletInfo.id,
                    repository: tangemPayAssembly.makeCardDetailsRepository(for: card),
                    cardNameDisplayMode: .interactive
                )
                detailsVM.onCardNameTapped = { [weak self] in
                    self?.openCardRename()
                }
                return CardDetailsItem(
                    id: card.cardId,
                    productInstanceId: entry.productInstanceId,
                    content: .issued(detailsVM)
                )
            case .issuing:
                return CardDetailsItem(
                    id: entry.id,
                    productInstanceId: entry.productInstanceId,
                    content: .issuing
                )
            }
        }
    }

    func propagateFreezingStateToDetailsVM(_ freezing: TangemPayFreezingState) {
        guard let id = selectedCardId,
              case .issued(let detailsVM) = cardDetailsItems.first(where: { $0.id == id })?.content else {
            return
        }
        detailsVM.state = freezing.cardDetailsState
    }

    func updateCardSettingsRows(freezingState: TangemPayFreezingState) {
        let isBusy = freezingState.isFreezingUnfreezingInProgress
        cardSettingsRows = [
            row(
                title: Localization.tangempayCardDetailsChangePin,
                accessibilityIdentifier: TangemPayAccessibilityIdentifiers.changePinRow,
                isBusy: isBusy,
                action: { [weak self] in self?.onPin() }
            ),
            row(
                title: freezingState.isFrozen
                    ? Localization.tangempayCardDetailsUnfreezeCard
                    : Localization.tangempayCardDetailsFreezeCard,
                accessibilityIdentifier: freezingState.isFrozen
                    ? TangemPayAccessibilityIdentifiers.freezeCardRowStateFrozen
                    : TangemPayAccessibilityIdentifiers.freezeCardRowStateActive,
                isBusy: isBusy,
                action: { [weak self] in
                    guard let self else { return }
                    if freezingState.isFrozen {
                        unfreeze()
                    } else {
                        showFreezePopup()
                    }
                }
            ),
            row(
                title: Localization.tangempayCardDetailsReissueCard,
                isBusy: isBusy,
                action: { [weak self] in self?.onReplaceCard() }
            ),
        ]
    }

    /// Builds a row that disables itself (`action: nil`) while a freeze/unfreeze operation is
    /// in flight on the selected card.
    func row(
        title: String,
        accessibilityIdentifier: String? = nil,
        isBusy: Bool,
        action: @escaping () -> Void
    ) -> DefaultRowViewModel {
        DefaultRowViewModel(
            title: title,
            accessibilityIdentifier: accessibilityIdentifier,
            action: isBusy ? nil : action
        )
    }
}

// MARK: - Actions

private extension TangemPayCardManagementViewModel {
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

    func onPin() {
        guard let card = currentCard else { return }
        Analytics.log(.visaScreenPinCodeClicked, contextParams: .userWallet(userWalletInfo.id))
        guard card.isPinSet else {
            setPin()
            return
        }

        Task { @MainActor in
            do {
                _ = try await BiometricsUtil.requestAccess(
                    localizedReason: Localization.biometryTouchIdReason
                )
                checkPin()
            } catch {
                VisaLogger.error("Failed to receive biometry for PIN", error: error)
            }
        }
    }

    func showFreezePopup() {
        Analytics.log(.visaScreenFreezeCardClicked, contextParams: .userWallet(userWalletInfo.id))
        coordinator?.openTangemPayFreezeSheet(userWalletId: userWalletInfo.id) { [weak self] in
            self?.freeze()
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
