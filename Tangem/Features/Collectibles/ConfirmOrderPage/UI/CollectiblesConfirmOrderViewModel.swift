//
//  CollectiblesConfirmOrderViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import SwiftUI
import TangemCollectibles
import TangemFoundation
import TangemLocalization

@MainActor
final class CollectiblesConfirmOrderViewModel: ObservableObject {
    // MARK: - Properties

    private let machineID: String
    private let price: Decimal
    private let platformFee: Decimal
    private let total: Decimal
    private let isTurboModeOn: Bool
    private let unfinishedPurchase: CollectiblesPendingPurchase?
    private let purchaseInteractor: any CollectiblesPackPurchaseInteractor
    private let revealAssetsPreloader: any CollectiblesRevealAssetsPreloader
    private let delayProvider: any PollDelayProvider
    private let refreshBalance: () async -> Void

    private weak var routable: (any CollectiblesConfirmOrderRoutable)?

    private var balanceState: BalanceState = .loading
    private var orderPhase: OrderPhase = .idle
    private var isResumingPurchase = false
    private var revealColorScheme: ColorScheme?
    private var bag = Set<AnyCancellable>()
    private var errorDismissTask: Task<Void, Error>?
    private var sheetDismissal: SheetDismissal?
    private var presentedSheet: Sheet?

    let artworkURL: URL?
    let rows: [OrderRow]

    // MARK: - Publishers

    @Published private(set) var buttonState: ButtonState = .balanceLoading
    @Published private(set) var revealViewModel: CollectiblesPackRevealViewModel?
    @Published private(set) var errorMessage: String?
    @Published var sheet: Sheet?
    @Published var isPackOpenFailedPresented = false

    // MARK: - Init

    init(
        machineID: String,
        machine: CollectiblesMachine,
        isTurboModeOn: Bool,
        unfinishedPurchase: CollectiblesPendingPurchase? = nil,
        usdcBalanceProvider: any TokenBalanceProvider,
        purchaseInteractor: any CollectiblesPackPurchaseInteractor,
        relinkStatusProvider: (any CollectiblesRelinkStatusProvider)?,
        routable: (any CollectiblesConfirmOrderRoutable)?,
        revealAssetsPreloader: any CollectiblesRevealAssetsPreloader,
        delayProvider: any PollDelayProvider = TaskSleepPollDelayProvider(),
        refreshBalance: @escaping () async -> Void
    ) {
        self.machineID = machineID
        price = machine.price
        platformFee = machine.platformFee
        total = machine.price + machine.platformFee
        self.isTurboModeOn = isTurboModeOn
        self.unfinishedPurchase = unfinishedPurchase
        self.purchaseInteractor = purchaseInteractor
        self.revealAssetsPreloader = revealAssetsPreloader
        self.routable = routable
        self.delayProvider = delayProvider
        self.refreshBalance = refreshBalance
        artworkURL = machine.artworkURL
        rows = [
            OrderRow(
                kind: .pack,
                title: "\(machine.name) x1",
                value: CollectiblesPriceFormatter.format(machine.price)
            ),
            OrderRow(
                kind: .fee,
                title: Localization.collectiblesConfirmOrderPlatformFee,
                value: CollectiblesPriceFormatter.format(machine.platformFee)
            ),
            OrderRow(
                kind: .total,
                title: Localization.collectiblesConfirmOrderTotal,
                value: CollectiblesPriceFormatter.formatAmount(
                    total,
                    ticker: CollectiblesChainEnvironment.usdcTokenItem.currencySymbol
                )
            ),
        ]

        bind(usdcBalanceProvider: usdcBalanceProvider, relinkStatusProvider: relinkStatusProvider)
    }

    // MARK: - Methods

    func onFirstDidAppear() {
        guard unfinishedPurchase != nil else { return }

        resumeUnfinishedPurchase()
    }

    func approve() {
        guard buttonState == .approve else { return }

        guard unfinishedPurchase == nil else {
            resumeUnfinishedPurchase()
            return
        }

        isResumingPurchase = false
        runOrder { [purchaseInteractor, machineID, price, platformFee, isTurboModeOn] onStep in
            try await purchaseInteractor.purchase(
                machineID: machineID,
                price: price,
                platformFee: platformFee,
                isTurboModeOn: isTurboModeOn,
                onStep: onStep
            )
        }
    }

    func close() {
        routable?.closePackFlow()
    }

    func show(reveal viewModel: CollectiblesPackRevealViewModel) {
        revealViewModel = viewModel
        orderPhase = .generated
        updateButtonState()
    }

    func preloadRevealAssets(for colorScheme: ColorScheme, isReduceMotionEnabled: Bool) {
        guard !isReduceMotionEnabled else {
            revealColorScheme = nil
            return
        }

        revealColorScheme = colorScheme
        revealAssetsPreloader.preload(for: colorScheme)
    }

    func dismissError() {
        errorDismissTask?.cancel()
        errorDismissTask = nil
        errorMessage = nil
    }

    func retryBalance() {
        guard buttonState == .balanceUnavailable else { return }

        balanceState = .loading
        updateButtonState()

        Task { [refreshBalance] in
            await refreshBalance()
        }
    }

    func explorePacks() {
        dismissSheet { [weak self] in self?.routable?.closePackFlow() }
    }

    func enableTurboMode() {
        dismissSheet { [weak self] in self?.routable?.returnToMachine() }
    }

    func openUnopenedPack() {
        dismissSheet { [weak self] in self?.resumeUnfinishedPurchase() }
    }

    func openAgain() {
        dismissSheet { [weak self] in self?.routable?.returnToMachine() }
    }

    func getAssistance() {
        routable?.openSupport()
    }

    func closePackOpenFailed() {
        isPackOpenFailedPresented = false
    }

    func packOpenFailedDidDismiss() {
        routable?.closePackFlow()
    }

    func sheetDidDismiss() {
        let dismissedSheet = presentedSheet
        presentedSheet = nil

        guard let sheetDismissal else {
            switch dismissedSheet {
            case .buybackComplete:
                routable?.returnToMachine()
            case .refundOnTheWay:
                routable?.closePackFlow()
            case .lowInventory, .packUnopened, .none:
                break
            }

            return
        }

        self.sheetDismissal = nil
        sheetDismissal.action()

        if let queuedSheet = sheetDismissal.queuedSheet {
            present(queuedSheet)
        }
    }
}

// MARK: - Nested types

extension CollectiblesConfirmOrderViewModel {
    struct OrderRow: Identifiable {
        enum Kind {
            case pack
            case fee
            case total
        }

        let kind: Kind
        let title: String
        let value: String

        var id: Kind { kind }
    }

    enum ButtonState {
        case balanceLoading
        case balanceUnavailable
        case approve
        case notEnoughFunds
        case relinkRequired
        case generating
        case confirming
        case opening
        case packGenerated
    }

    enum Sheet: Hashable, Identifiable {
        case lowInventory
        case packUnopened
        case refundOnTheWay
        case buybackComplete(BuybackComplete)

        var id: Self { self }
    }

    struct BuybackComplete: Hashable {
        let cardImageURL: URL?
        let cardName: String?
        let amount: String?
        let price: String
    }
}

// MARK: - Order phase

private extension CollectiblesConfirmOrderViewModel {
    enum OrderPhase {
        case idle
        case generating
        case confirming
        case opening
        case generated
    }

    enum BalanceState {
        case loading
        case known(Decimal)
        case unavailable
    }

    struct SheetDismissal {
        let action: () -> Void
        var queuedSheet: Sheet?
    }
}

// MARK: - Private logic

private extension CollectiblesConfirmOrderViewModel {
    func bind(
        usdcBalanceProvider: any TokenBalanceProvider,
        relinkStatusProvider: (any CollectiblesRelinkStatusProvider)?
    ) {
        usdcBalanceProvider.balanceTypePublisher
            .map(Self.balanceState(from:))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] balanceState in
                self?.update(balanceState: balanceState)
            }
            .store(in: &bag)

        relinkStatusProvider?.isRelinkRequiredPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateButtonState()
            }
            .store(in: &bag)
    }

    func resumeUnfinishedPurchase() {
        isResumingPurchase = true
        runOrder { [purchaseInteractor, machineID, unfinishedPurchase] onStep in
            guard let unfinishedPurchase else {
                return try await purchaseInteractor.resumeKeptPurchase(machineID: machineID, onStep: onStep)
            }

            return try await purchaseInteractor.resumePurchase(unfinishedPurchase, onStep: onStep)
        }
    }

    func runOrder(
        _ request: @escaping (_ onStep: @escaping (CollectiblesPackPurchaseStep) -> Void) async throws -> CollectiblesPackPurchaseResult
    ) {
        dismissError()
        orderPhase = .generating
        updateButtonState()

        if let revealColorScheme {
            revealAssetsPreloader.preload(for: revealColorScheme)
        }

        Task { [weak self, revealAssetsPreloader, refreshBalance] in
            do {
                let result = try await request { [weak self] step in self?.apply(step) }

                switch result {
                case .wonCard(let wonCard):
                    let imageURLs = [wonCard.imageFrontURL, wonCard.imageBackURL].compactMap { $0 }
                    let assets = await revealAssetsPreloader.assets(prefetchingImages: imageURLs)

                    // [REDACTED_TODO_COMMENT]
                    self?.openReveal(of: wonCard, assets: assets)
                case .autoSold(let amount, let wonCard):
                    self?.showBuybackComplete(amount: amount, wonCard: wonCard)
                }
            } catch {
                self?.handlePurchaseFailure(error)
            }

            await refreshBalance()
        }
    }

    func update(balanceState newState: BalanceState) {
        if case .loading = newState, case .known = balanceState {
            return
        }

        balanceState = newState
        updateButtonState()
    }

    func apply(_ step: CollectiblesPackPurchaseStep) {
        switch step {
        case .generating: orderPhase = .generating
        case .confirming: orderPhase = .confirming
        case .opening: orderPhase = .opening
        }

        updateButtonState()
    }

    func openReveal(of wonCard: CollectiblesWonCard, assets: CollectiblesRevealAssets) {
        routable?.openPackReveal(wonCard: wonCard, assets: assets)
    }

    func showBuybackComplete(amount: Decimal?, wonCard: CollectiblesWonCard?) {
        orderPhase = .idle
        updateButtonState()

        let ticker = CollectiblesChainEnvironment.usdcTokenItem.currencySymbol
        present(.buybackComplete(BuybackComplete(
            cardImageURL: wonCard?.imageFrontURL,
            cardName: wonCard.flatMap(Self.cardName(of:)),
            amount: amount.map { CollectiblesPriceFormatter.formatAmount($0, ticker: ticker) },
            price: CollectiblesPriceFormatter.formatAmount(price, ticker: ticker)
        )))
    }

    static func cardName(of wonCard: CollectiblesWonCard) -> String? {
        let parts = [wonCard.year, wonCard.set, wonCard.serialNumber.map { "#\($0)" }].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }

    func present(_ sheet: Sheet) {
        guard sheetDismissal == nil else {
            sheetDismissal?.queuedSheet = sheet
            return
        }

        presentedSheet = sheet
        self.sheet = sheet
    }

    func dismissSheet(then action: @escaping () -> Void = {}) {
        guard sheet != nil else { return }

        sheetDismissal = SheetDismissal(action: action)
        sheet = nil
    }

    func handlePurchaseFailure(_ error: any Error) {
        CollectiblesLogger.error("Collectibles pack \(machineID) purchase failed", error: error)
        orderPhase = .idle
        updateButtonState()

        switch error as? CollectiblesPackPurchaseError {
        case .relinkRequired:
            buttonState = .relinkRequired
        case .lowInventory:
            present(.lowInventory)
        case .packUnopened, .openFailed, .prizeNotDelivered, .paymentTimedOut:
            present(.packUnopened)
        case .openRefused, .paymentFailed(.expired), .paymentFailed(.packOpeningError):
            isPackOpenFailedPresented = true
        case .paymentFailed(.refunded):
            present(.refundOnTheWay)
        case .paymentFailed where isResumingPurchase:
            routable?.closePackFlow()
        // [REDACTED_TODO_COMMENT]
        case .anotherPurchaseInProgress:
            showError(message: "Open your other pack first")
        case .noUnfinishedPurchase:
            routable?.closePackFlow()
        default:
            showError()
        }
    }

    func showError(message: String = Localization.commonSomethingWentWrong) {
        errorMessage = message

        errorDismissTask?.cancel()
        errorDismissTask = Task { [weak self, delayProvider] in
            try await delayProvider.wait(for: Constants.errorDisplayDuration)
            self?.errorMessage = nil
            self?.errorDismissTask = nil
        }
    }

    func updateButtonState() {
        switch orderPhase {
        case .idle:
            break
        case .generating:
            buttonState = .generating
            return
        case .confirming:
            buttonState = .confirming
            return
        case .opening:
            buttonState = .opening
            return
        case .generated:
            buttonState = .packGenerated
            return
        }

        if purchaseInteractor.isPurchaseLocked(machineID: machineID) {
            buttonState = .relinkRequired
            return
        }

        if purchaseInteractor.hasUnfinishedPurchase(machineID: machineID) {
            buttonState = .approve
            return
        }

        switch balanceState {
        case .loading:
            buttonState = .balanceLoading
        case .unavailable:
            buttonState = .balanceUnavailable
        case .known(let balance):
            buttonState = balance >= total ? .approve : .notEnoughFunds
        }
    }

    nonisolated static func balanceState(from balanceType: TokenBalanceType) -> BalanceState {
        switch balanceType {
        case .loaded(let balance): .known(balance)
        case .loading: .loading
        case .failure, .empty: .unavailable
        }
    }
}

// MARK: - Constants

private extension CollectiblesConfirmOrderViewModel {
    enum Constants {
        static let errorDisplayDuration: TimeInterval = 3
    }
}
