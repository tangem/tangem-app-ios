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

    @Published private(set) var contentState: ContentState = .details(
        ContentState.Details(freezingState: .unavailable, dailyLimitState: nil, showsAddToApplePayGuide: false)
    )
    @Published private(set) var cardRenameViewModel: TangemPayCardRenameViewModel?
    @Published private(set) var closeCardRow: DefaultRowViewModel?
    @Published private(set) var isLoadingReissueFee: Bool = false
    @Published var alert: AlertBinder?
    @Published var addToApplePayGuideViewModel: TangemPayAddToAppPayGuideViewModel?

    var hasMultipleCards: Bool {
        cardDetailsItems.count > 1
    }

    private let userWalletInfo: UserWalletInfo
    private let tangemPayAccount: TangemPayAccount
    @Injected(\.tangemPayAssembly) private var tangemPayAssembly: TangemPayAssembly
    private lazy var biometryAuthorizer: TangemPayBiometryAuthorizer = tangemPayAssembly.makeBiometryAuthorizer()
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
    private var shouldOpenActivation: Bool

    init(
        userWalletInfo: UserWalletInfo,
        tangemPayAccount: TangemPayAccount,
        initialEntry: TangemPayCardEntry,
        shouldOpenActivation: Bool = false,
        coordinator: TangemPayCardManagementRoutable
    ) {
        self.userWalletInfo = userWalletInfo
        self.tangemPayAccount = tangemPayAccount
        selectedCardId = initialEntry.id
        self.shouldOpenActivation = shouldOpenActivation
        self.coordinator = coordinator

        rebuildCardDetailsItems(entries: tangemPayAccount.cardEntries)
        selectionAnchor = SelectionAnchor(entry: initialEntry)

        contentState = makeContentState(
            entries: tangemPayAccount.cardEntries,
            selectedCardId: initialEntry.id,
            renameViewModel: nil,
            lifecycle: initialEntry.card.map(makeLifecycle(for:)),
            showsAddToApplePayGuide: false
        )

        bindMultiCard()
    }

    func onAppear() {
        Analytics.log(.visaCardManagementScreenOpened, contextParams: .userWallet(userWalletInfo.id))

        if shouldOpenActivation {
            shouldOpenActivation = false
            openPlasticCardActivation()
        }
    }

    func selectDeliveringPlasticCard() {
        guard let entry = tangemPayAccount.cardEntries.first(where: { $0.plasticCard?.isDelivering == true }) else {
            return
        }

        selectedCardId = entry.id
    }

    func openChangeDailyLimit() {
        guard case .details(let details) = contentState, case .loaded = details.dailyLimitState else { return }
        guard let card = currentCard else { return }
        Analytics.log(.visaScreenDailyLimitChangeClicked, contextParams: .userWallet(userWalletInfo.id))
        coordinator?.openChangeDailyLimit(card: card)
    }

    func openAddToApplePayGuide() {
        Analytics.log(.visaScreenAddToWalletClicked, contextParams: .userWallet(userWalletInfo.id))
        guard let card = currentCard else { return }
        let repository = tangemPayAssembly.makeCardDetailsRepository(for: card)
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
            case ghost
            case plastic
        }
    }
}

// MARK: - Selection anchor

private extension TangemPayCardManagementViewModel {
    struct SelectionAnchor {
        let entryId: String
        let productInstanceId: String?
        let isPlastic: Bool

        init(entry: TangemPayCardEntry) {
            entryId = entry.id
            productInstanceId = entry.productInstanceId
            isPlastic = entry.plasticCard != nil
        }

        func resolveSelection(in entries: [TangemPayCardEntry]) -> (entry: TangemPayCardEntry, newAnchor: SelectionAnchor)? {
            if let pid = productInstanceId,
               let entry = entries.first(where: { $0.productInstanceId == pid }) {
                return (entry, SelectionAnchor(entry: entry))
            }
            if let entry = entries.first(where: { $0.id == entryId }) {
                return (entry, SelectionAnchor(entry: entry))
            }
            // The card entry replacing a plastic order shares nothing with its anchor but being plastic.
            if isPlastic, let entry = entries.first(where: { $0.plasticCard != nil }) {
                return (entry, SelectionAnchor(entry: entry))
            }
            return nil
        }
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

        Publishers.CombineLatest4(
            tangemPayAccount.cardEntriesPublisher,
            $selectedCardId,
            $cardRenameViewModel,
            selectedCardLifecyclePublisher
        )
        .combineLatest(addToApplePayGuidePublisher)
        .withWeakCaptureOf(self)
        .map { viewModel, input in
            let ((entries, selectedCardId, renameViewModel, lifecycle), showsAddToApplePayGuide) = input
            return viewModel.makeContentState(
                entries: entries,
                selectedCardId: selectedCardId,
                renameViewModel: renameViewModel,
                lifecycle: lifecycle,
                showsAddToApplePayGuide: showsAddToApplePayGuide
            )
        }
        .receiveOnMain()
        .assign(to: &$contentState)

        selectedCardFreezingPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, output in
                viewModel.selectedMultiCardDetailsViewModel?.state = output.freezingState.cardDetailsState
            }
            .store(in: &bag)

        $contentState
            .map(\.isPlasticInTransit)
            .removeDuplicates()
            .filter { $0 }
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                Analytics.log(
                    .visaPlasticCardInTransitDetailsShowed,
                    contextParams: .userWallet(viewModel.userWalletInfo.id)
                )
            }
            .store(in: &bag)

        Publishers.CombineLatest($contentState, $cardDetailsItems)
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, output in
                let (state, cardEntities) = output
                viewModel.updateCloseCardRow(isClosing: state.isClosing, isOnlyCard: cardEntities.count <= 1)
            }
            .store(in: &bag)
    }

    var selectedCardLifecyclePublisher: AnyPublisher<CardLifecycle?, Never> {
        $selectedCardId
            .withWeakCaptureOf(self)
            .map { viewModel, id -> AnyPublisher<CardLifecycle?, Never> in
                guard let id, let card = viewModel.tangemPayAccount.card(cardId: id) else {
                    return .just(output: nil)
                }

                return Publishers.CombineLatest3(
                    card.statusPublisher,
                    card.inflightLifecycleOperationPublisher,
                    viewModel.dailyLimitStatePublisher(for: card)
                )
                .map { status, operation, dailyLimitState -> CardLifecycle? in
                    CardLifecycle(status: status, operation: operation, dailyLimitState: dailyLimitState)
                }
                .eraseToAnyPublisher()
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }

    /// The card id is part of the deduplicated value: a switch between two cards sharing a freezing
    /// state must still emit, since a freshly built card details view model starts unfrozen.
    var selectedCardFreezingPublisher: AnyPublisher<(cardId: String?, freezingState: TangemPayFreezingState), Never> {
        $selectedCardId
            .withWeakCaptureOf(self)
            .map { viewModel, id -> AnyPublisher<(cardId: String?, freezingState: TangemPayFreezingState), Never> in
                guard let id, let card = viewModel.tangemPayAccount.card(cardId: id) else {
                    return .just(output: (cardId: id, freezingState: .unavailable))
                }

                return Publishers.CombineLatest(card.statusPublisher, card.inflightLifecycleOperationPublisher)
                    .map { status, operation in
                        (cardId: id, freezingState: TangemPayFreezingState(status: status, operation: operation))
                    }
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .removeDuplicates { $0 == $1 }
            .eraseToAnyPublisher()
    }

    var addToApplePayGuidePublisher: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest(
            AppSettings.shared.$tangemPayShowAddToApplePayGuide,
            tangemPayAccount.statePublisher
        )
        .map { showGuide, customerState in
            PKPaymentAuthorizationViewController.canMakePayments()
                && customerState == .active
                && showGuide
        }
        .eraseToAnyPublisher()
    }

    func dailyLimitStatePublisher(for card: TangemPayCard) -> AnyPublisher<TangemPayDailyLimitState?, Never> {
        card.cardLimitPublisher
            .withWeakCaptureOf(self)
            .map { viewModel, amount in viewModel.dailyLimitState(forLimit: amount) }
            .prepend(.some(.loading))
            .eraseToAnyPublisher()
    }

    func dailyLimitState(forLimit amount: Int) -> TangemPayDailyLimitState? {
        guard let formatted = dailyLimitFormatter.string(from: .init(value: amount)) else {
            return .error
        }
        return .loaded(TangemPayDailyLimit(currentLimit: formatted))
    }

    func makeLifecycle(for card: TangemPayCard) -> CardLifecycle {
        CardLifecycle(
            status: card.productInstance.status,
            operation: card.inflightLifecycleOperation,
            dailyLimitState: dailyLimitState(forLimit: card.cardLimit)
        )
    }

    func makeContentState(
        entries: [TangemPayCardEntry],
        selectedCardId: String?,
        renameViewModel: TangemPayCardRenameViewModel?,
        lifecycle: CardLifecycle?,
        showsAddToApplePayGuide: Bool
    ) -> ContentState {
        if let renameViewModel {
            return .renaming(renameViewModel)
        }

        if lifecycle?.isClosing == true {
            return .closing
        }

        let entry = selectedCardId.flatMap { id in entries.first { $0.id == id } }

        if let plastic = entry?.plasticCard {
            return .plastic(ContentState.Plastic(plastic), email: tangemPayAccount.profile?.email)
        }

        if entry?.isIssuing == true {
            return .issuing
        }

        if lifecycle?.isReissuing == true {
            return .reissuing
        }

        return .details(
            ContentState.Details(
                freezingState: lifecycle?.freezingState ?? .unavailable,
                dailyLimitState: lifecycle?.dailyLimitState,
                showsAddToApplePayGuide: showsAddToApplePayGuide
            )
        )
    }
}

// MARK: - Multi-card private

private extension TangemPayCardManagementViewModel {
    func applyEntries(_ entries: [TangemPayCardEntry]) {
        let selectedIndex = cardDetailsItems.firstIndex { $0.id == selectedCardId }

        let resolution = selectionAnchor?.resolveSelection(in: entries)

        rebuildCardDetailsItems(entries: entries)

        if let resolution {
            selectionAnchor = resolution.newAnchor
            if resolution.entry.id != selectedCardId {
                selectedCardId = resolution.entry.id
            }
            return
        }

        if selectionAnchor?.isPlastic == true, tangemPayAccount.isPlasticDeliveryInProgress {
            return
        }

        // When the selected card is gone (e.g. its close order completed), fall back to the card
        // before it so we stay in card management instead of leaving the screen.
        guard let fallback = fallbackResolution(selectedIndex: selectedIndex, in: entries) else {
            if selectionAnchor != nil {
                coordinator?.popToCardListScreen()
                selectionAnchor = nil
            }
            selectedCardId = nil
            return
        }

        selectionAnchor = fallback.newAnchor
        if fallback.entry.id != selectedCardId {
            selectedCardId = fallback.entry.id
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
                    content: entry.isGhost ? .ghost : .issuing
                )
            case .plastic:
                return CardDetailsItem(
                    id: entry.id,
                    productInstanceId: entry.productInstanceId,
                    content: .plastic
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

        let onLoadingChange: (Bool) -> Void = { [weak self] in self?.isLoadingReissueFee = $0 }
        let onError: () -> Void = { [weak self] in self?.showReissueError() }

        if FeatureProvider.isAvailable(.tangemPayPlastic), card.isPhysical {
            coordinator?.openPlasticCardReissueSheet(
                userWalletId: userWalletInfo.id,
                card: card,
                onLoadingChange: onLoadingChange,
                onError: onError
            )
        } else {
            coordinator?.openTangemPayReissueSheet(
                userWalletId: userWalletInfo.id,
                card: card,
                onLoadingChange: onLoadingChange,
                onError: onError
            )
        }
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

        guard biometryAuthorizer.isAvailable else {
            coordinator?.openTangemPayBiometryNotSetSheet()
            return
        }

        Task { @MainActor in
            do {
                try await biometryAuthorizer.requestAccess()
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
    private var activatablePlasticCard: TangemPayCard? {
        guard case .plastic(.awaitingActivation, _) = contentState, let selectedCardId else {
            return nil
        }

        return tangemPayAccount.cardEntries.first { $0.id == selectedCardId }?.plasticCard?.deliveredCard
    }

    func onDetailsButton() {
        currentRedesignedDetailsViewModel?.toggleVisibility()
    }

    func onFreezeButton() {
        if contentState.freezingState?.isFrozen == true {
            showUnfreezePopup()
        } else {
            showFreezePopup()
        }
    }

    func onPinButton() {
        onPin()
    }

    func onReplaceButton() {
        onReplaceCard()
    }

    func onActivatePlasticCardButton() {
        Analytics.log(.visaPlasticActivateCardManagementButtonClicked, contextParams: .userWallet(userWalletInfo.id))
        openPlasticCardActivation()
    }

    private func openPlasticCardActivation() {
        guard let card = activatablePlasticCard else { return }

        coordinator?.openPlasticCardActivation(
            productInstanceId: card.productInstance.id,
            activationImageURL: card.activationImageURL
        )
    }

    func onContactSupportButton() {
        coordinator?.openSupport()
    }

    private var currentRedesignedDetailsViewModel: TangemPayCardDetailsViewModel? {
        selectedMultiCardDetailsViewModel
    }
}
