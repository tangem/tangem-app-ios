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
    /// Selected at construction: the legacy single-card flow uses `init(...cardDetailsRepository:...)`,
    /// the multi-card flow uses `init(...initialEntry:...)`.
    let multipleCardsEnabled: Bool

    // Multi-card
    @Published private(set) var cardDetailsItems: [CardDetailsItem] = []
    @Published var selectedCardId: String?

    /// Legacy single-card
    let tangemPayCardDetailsViewModel: TangemPayCardDetailsViewModel?

    // Shared
    @Published private(set) var cardRenameViewModel: TangemPayCardRenameViewModel?
    @Published private(set) var freezingState: TangemPayFreezingState = .normal
    @Published private(set) var shouldDisplayAddToApplePayGuide: Bool = false
    @Published private(set) var cardSettingsRows: [DefaultRowViewModel] = []
    @Published private(set) var closeCardRow: DefaultRowViewModel?
    @Published private(set) var dailyLimitState: TangemPayDailyLimitState?
    @Published private(set) var isIssuing: Bool = false
    @Published private(set) var isReissuing: Bool = false
    @Published private(set) var isClosing: Bool = false
    @Published private(set) var isLoadingReissueFee: Bool = false
    @Published var alert: AlertBinder?
    @Published var addToApplePayGuideViewModel: TangemPayAddToAppPayGuideViewModel?

    var hasMultipleCards: Bool {
        cardDetailsItems.count > 1
    }

    private let userWalletInfo: UserWalletInfo
    private let tangemPayAccount: TangemPayAccount
    private let cardDetailsRepository: TangemPayCardDetailsRepository?
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

    private var selectionAnchor: SelectionAnchor?

    init(
        userWalletInfo: UserWalletInfo,
        tangemPayAccount: TangemPayAccount,
        cardDetailsRepository: TangemPayCardDetailsRepository,
        coordinator: TangemPayCardManagementRoutable
    ) {
        multipleCardsEnabled = false
        self.userWalletInfo = userWalletInfo
        self.tangemPayAccount = tangemPayAccount
        self.cardDetailsRepository = cardDetailsRepository
        self.coordinator = coordinator

        let detailsViewModel = TangemPayCardDetailsViewModel(
            userWalletId: userWalletInfo.id,
            repository: cardDetailsRepository,
            cardNameDisplayMode: .interactive
        )
        tangemPayCardDetailsViewModel = detailsViewModel

        detailsViewModel.onCardNameTapped = { [weak self] in
            self?.openCardRenameLegacy()
        }

        dailyLimitState = .loading
        bindLegacy()
    }

    init(
        userWalletInfo: UserWalletInfo,
        tangemPayAccount: TangemPayAccount,
        initialEntry: TangemPayCardEntry,
        coordinator: TangemPayCardManagementRoutable
    ) {
        multipleCardsEnabled = true
        self.userWalletInfo = userWalletInfo
        self.tangemPayAccount = tangemPayAccount
        cardDetailsRepository = nil
        tangemPayCardDetailsViewModel = nil
        selectedCardId = initialEntry.id
        self.coordinator = coordinator

        rebuildCardDetailsItems(entries: tangemPayAccount.cardEntries)
        selectionAnchor = SelectionAnchor(entry: initialEntry)

        bindMultiCard()
    }

    func onAppear() {
        Analytics.log(.visaCardManagementScreenOpened, contextParams: .userWallet(userWalletInfo.id))
    }

    func openChangeDailyLimit() {
        guard case .loaded = dailyLimitState else { return }

        if multipleCardsEnabled {
            guard let card = currentCard else { return }
            Analytics.log(.visaScreenDailyLimitChangeClicked, contextParams: .userWallet(userWalletInfo.id))
            coordinator?.openChangeDailyLimit(card: card)
        } else {
            Analytics.log(.visaScreenDailyLimitChangeClicked, contextParams: .userWallet(userWalletInfo.id))
            coordinator?.openChangeDailyLimit(tangemPayAccount: tangemPayAccount)
        }
    }

    func openAddToApplePayGuide() {
        Analytics.log(.visaScreenAddToWalletClicked, contextParams: .userWallet(userWalletInfo.id))
        let repository: TangemPayCardDetailsRepository
        if multipleCardsEnabled {
            guard let card = currentCard else { return }
            repository = tangemPayAssembly.makeCardDetailsRepository(for: card)
        } else {
            guard let cardDetailsRepository else { return }
            repository = cardDetailsRepository
        }
        addToApplePayGuideViewModel = TangemPayAddToAppPayGuideViewModel(
            tangemPayCardDetailsViewModel: TangemPayCardDetailsViewModel(
                userWalletId: userWalletInfo.id,
                repository: repository
            ),
            coordinator: self
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
        let entryId: String
        let productInstanceId: String?

        init(entry: TangemPayCardEntry) {
            entryId = entry.id
            productInstanceId = entry.productInstanceId
        }

        func resolveSelection(in entries: [TangemPayCardEntry]) -> (entry: TangemPayCardEntry, newAnchor: SelectionAnchor)? {
            if let pid = productInstanceId,
               let entry = entries.first(where: { $0.productInstanceId == pid }) {
                return (entry, SelectionAnchor(entry: entry))
            }
            if let entry = entries.first(where: { $0.id == entryId }) {
                return (entry, SelectionAnchor(entry: entry))
            }
            return nil
        }
    }
}

// MARK: - Legacy single-card bindings

private extension TangemPayCardManagementViewModel {
    func bindLegacy() {
        guard let tangemPayCardDetailsViewModel else { return }

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
                self?.updateCardSettingsRowsLegacy(freezingState: state)
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

        let initialDailyLimitState: TangemPayDailyLimitState? = .loading
        tangemPayAccount.cardLimitPublisher
            .map { [dailyLimitFormatter] amount -> TangemPayDailyLimitState? in
                if let amount, let limit = dailyLimitFormatter.string(from: .init(value: amount)) {
                    return .loaded(TangemPayDailyLimit(currentLimit: limit))
                } else {
                    return .error
                }
            }
            .prepend(initialDailyLimitState)
            .receiveOnMain()
            .assign(to: \.dailyLimitState, on: self, ownership: .weak)
            .store(in: &bag)
    }

    func updateCardSettingsRowsLegacy(freezingState: TangemPayFreezingState) {
        let changePinRow = DefaultRowViewModel(
            title: Localization.tangempayCardDetailsChangePin,
            accessibilityIdentifier: TangemPayAccessibilityIdentifiers.changePinRow,
            action: freezingState.isFreezingUnfreezingInProgress ? nil : { [weak self] in
                self?.onPinLegacy()
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
                    unfreezeLegacy()
                } else {
                    showFreezePopupLegacy()
                }
            }
        )

        let replaceCardRow = DefaultRowViewModel(
            title: Localization.tangempayCardDetailsReissueCard,
            action: freezingState.isFreezingUnfreezingInProgress ? nil : { [weak self] in
                self?.onReplaceCardLegacy()
            }
        )

        cardSettingsRows = [changePinRow, freezeRow, replaceCardRow]
    }

    func onReplaceCardLegacy() {
        Analytics.log(.visaReplaceCardClicked, contextParams: .userWallet(userWalletInfo.id))
        coordinator?.openTangemPayReissueSheet(
            userWalletId: userWalletInfo.id,
            tangemPayAccount: tangemPayAccount,
            onLoadingChange: { [weak self] in self?.isLoadingReissueFee = $0 },
            onError: { [weak self] in self?.showReissueError() }
        )
    }

    func setPinLegacy() {
        coordinator?.openTangemPaySetPin(tangemPayAccount: tangemPayAccount)
    }

    func checkPinLegacy() {
        coordinator?.openTangemPayCheckPin(tangemPayAccount: tangemPayAccount)
    }

    func freezeLegacy() {
        freezingState = .freezingInProgress
        tangemPayCardDetailsViewModel?.state = .loading(isFrozen: tangemPayCardDetailsViewModel?.state.isFrozen ?? false)

        Task { @MainActor in
            do {
                try await tangemPayAccount.freeze()
            } catch {
                freezingState = .normal
                showFreezeUnfreezeErrorToast(freeze: true)
            }
        }
    }

    func unfreezeLegacy() {
        Analytics.log(.visaScreenUnfreezeCardClicked, contextParams: .userWallet(userWalletInfo.id))
        freezingState = .unfreezingInProgress
        tangemPayCardDetailsViewModel?.state = .loading(isFrozen: tangemPayCardDetailsViewModel?.state.isFrozen ?? false)

        Task { @MainActor in
            do {
                try await tangemPayAccount.unfreeze()
            } catch {
                freezingState = .frozen
                showFreezeUnfreezeErrorToast(freeze: false)
            }
        }
    }

    func onPinLegacy() {
        Analytics.log(.visaScreenPinCodeClicked, contextParams: .userWallet(userWalletInfo.id))
        guard tangemPayAccount.card?.isPinSet == true else {
            setPinLegacy()
            return
        }

        guard BiometricsUtil.isAvailable else {
            if FeatureProvider.isAvailable(.tangemPaySpendRedesign) {
                coordinator?.openTangemPayBiometryNotSetSheet()
            }
            return
        }

        runTask(in: self) { viewModel in
            do {
                _ = try await BiometricsUtil.requestAccess(
                    localizedReason: Localization.biometryTouchIdReason
                )
                viewModel.checkPinLegacy()
            } catch {
                VisaLogger.error("Failed to receive biometry for PIN", error: error)
                return
            }
        }
    }

    func showFreezePopupLegacy() {
        Analytics.log(.visaScreenFreezeCardClicked, contextParams: .userWallet(userWalletInfo.id))
        coordinator?.openTangemPayFreezeSheet(userWalletId: userWalletInfo.id) { [weak self] in
            self?.freezeLegacy()
        }
    }

    func showUnfreezePopupLegacy() {
        coordinator?.openTangemPayUnfreezeSheet(userWalletId: userWalletInfo.id) { [weak self] in
            self?.unfreezeLegacy()
        }
    }

    func openCardRenameLegacy() {
        guard let cardDetailsRepository else { return }
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

// MARK: - TangemPayAddToAppPayGuideRoutable

extension TangemPayCardManagementViewModel: TangemPayAddToAppPayGuideRoutable {
    func closeAddToAppPayGuide() {
        addToApplePayGuideViewModel = nil
    }
}

// MARK: - Multi-card bindings

private extension TangemPayCardManagementViewModel {
    func bindMultiCard() {
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
                Publishers.CombineLatest(card.statusPublisher, card.inflightLifecycleOperationPublisher)
                    .map { status, operation -> TangemPayFreezingState in
                        switch operation {
                        case .freeze: .freezingInProgress
                        case .unfreeze: .unfreezingInProgress
                        case .reissue, .close, nil: status == .blocked ? .frozen : .normal
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

        bindSelectedCard(
            fallback: false,
            publisher: { $0.isReissuingPublisher },
            to: \.isReissuing
        )

        bindSelectedCard(
            fallback: false,
            publisher: { $0.isClosingPublisher },
            to: \.isClosing
        )

        Publishers.CombineLatest($freezingState, $isClosing)
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { vm, output in
                let (freezing, isClosing) = output
                vm.propagateFreezingStateToDetailsVM(freezing)
                vm.updateCardSettingsRows(freezingState: freezing, isClosing: isClosing)
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

        Publishers.CombineLatest($isClosing, $cardDetailsItems)
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, output in
                let (isClosing, cardEntities) = output
                viewModel.updateCloseCardRow(isClosing: isClosing, isOnlyCard: cardEntities.count <= 1)
            }
            .store(in: &bag)
    }

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

// MARK: - Multi-card private

private extension TangemPayCardManagementViewModel {
    func applyEntries(_ entries: [TangemPayCardEntry]) {
        let selectedIndex = cardDetailsItems.firstIndex { $0.id == selectedCardId }

        // When the selected card is gone (e.g. its close order completed), fall back to the card
        // before it so we stay in card management instead of leaving the screen.
        let resolution = selectionAnchor?.resolveSelection(in: entries) ?? fallbackResolution(selectedIndex: selectedIndex, in: entries)

        rebuildCardDetailsItems(entries: entries)

        guard let resolution else {
            if selectionAnchor != nil {
                coordinator?.popToCardListScreen()
                selectionAnchor = nil
            }
            selectedCardId = nil
            return
        }

        selectionAnchor = resolution.newAnchor
        if resolution.entry.id != selectedCardId {
            selectedCardId = resolution.entry.id
        }
    }

    func fallbackResolution(
        selectedIndex: Int?,
        in entries: [TangemPayCardEntry]
    ) -> (entry: TangemPayCardEntry, newAnchor: SelectionAnchor)? {
        let fallbackCard = selectedIndex.flatMap { entries[safe: $0 - 1] } ?? entries.first
        return fallbackCard.map { ($0, SelectionAnchor(entry: $0)) }
    }

    func rebuildCardDetailsItems(entries: [TangemPayCardEntry]) {
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

    var selectedMultiCardDetailsViewModel: TangemPayCardDetailsViewModel? {
        guard let selectedCardId,
              case .issued(let detailsViewModel) = cardDetailsItems.first(where: { $0.id == selectedCardId })?.content
        else {
            return nil
        }
        return detailsViewModel
    }

    func propagateFreezingStateToDetailsVM(_ freezing: TangemPayFreezingState) {
        selectedMultiCardDetailsViewModel?.state = freezing.cardDetailsState
    }

    func updateCardSettingsRows(freezingState: TangemPayFreezingState, isClosing: Bool) {
        let isBusy = freezingState.isFreezingUnfreezingInProgress || isClosing
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

    func updateCloseCardRow(isClosing: Bool, isOnlyCard: Bool) {
        let isBusy = isClosing || isOnlyCard
        let action: () -> Void = { [weak self] in
            self?.showCloseCardPopup()
        }
        closeCardRow = row(title: Localization.tangemPayCloseCardPopupPrimaryButtonTitle, isBusy: isBusy, action: action)
    }

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

    func onReplaceCard() {
        guard let card = currentCard else { return }
        Analytics.log(.visaReplaceCardClicked, contextParams: .userWallet(userWalletInfo.id))
        coordinator?.openTangemPayReissueSheet(
            userWalletId: userWalletInfo.id,
            card: card,
            onLoadingChange: { [weak self] in self?.isLoadingReissueFee = $0 },
            onError: { [weak self] in self?.showReissueError() }
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

        guard BiometricsUtil.isAvailable else {
            if FeatureProvider.isAvailable(.tangemPaySpendRedesign) {
                coordinator?.openTangemPayBiometryNotSetSheet()
            }
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

    func showUnfreezePopup() {
        coordinator?.openTangemPayUnfreezeSheet(userWalletId: userWalletInfo.id) { [weak self] in
            self?.unfreeze()
        }
    }

    func openCardRename() {
        guard let card = currentCard else { return }
        let renameViewModel = TangemPayCardRenameViewModel(
            userWalletId: userWalletInfo.id,
            repository: tangemPayAssembly.makeCardDetailsRepository(for: card),
            onDismiss: { [weak self] in
                self?.cardRenameViewModel = nil
            }
        )

        renameViewModel.$alert.assign(to: &$alert)

        cardRenameViewModel = renameViewModel
    }

    func showCloseCardPopup() {
        guard let card = currentCard else { return }

        Analytics.log(.visaCloseCardClicked, contextParams: .userWallet(userWalletInfo.id))

        coordinator?.openTangemPayCloseCardSheet(
            userWalletId: userWalletInfo.id,
            card: card,
            onError: { [weak self] in self?.showCloseCardErrorToast() }
        )
    }

    func showCloseCardErrorToast() {
        Toast(view: WarningToast(text: Localization.commonSomethingWentWrong))
            .present(layout: .top(padding: 20), type: .temporary())
    }
}

// MARK: - Shared private

private extension TangemPayCardManagementViewModel {
    func showReissueError() {
        alert = AlertBinder(
            title: Localization.commonSomethingWentWrong,
            message: Localization.tangempayReissueCardFeeUnreachableErrorTitle
        )
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

// MARK: - Redesigned card management actions

extension TangemPayCardManagementViewModel {
    var cardActionsDisabled: Bool {
        freezingState.isFreezingUnfreezingInProgress
    }

    func onDetailsButton() {
        currentRedesignedDetailsViewModel?.toggleVisibility()
    }

    func onFreezeButton() {
        if multipleCardsEnabled {
            if freezingState.isFrozen {
                showUnfreezePopup()
            } else {
                showFreezePopup()
            }
        } else {
            if freezingState.isFrozen {
                showUnfreezePopupLegacy()
            } else {
                showFreezePopupLegacy()
            }
        }
    }

    func onPinButton() {
        if multipleCardsEnabled {
            onPin()
        } else {
            onPinLegacy()
        }
    }

    func onReplaceButton() {
        if multipleCardsEnabled {
            onReplaceCard()
        } else {
            onReplaceCardLegacy()
        }
    }

    private var currentRedesignedDetailsViewModel: TangemPayCardDetailsViewModel? {
        guard multipleCardsEnabled else {
            return tangemPayCardDetailsViewModel
        }

        return selectedMultiCardDetailsViewModel
    }
}
