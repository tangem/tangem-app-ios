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
import TangemLocalization

@MainActor
final class CollectiblesConfirmOrderViewModel: ObservableObject {
    // MARK: - Properties

    private let machineID: String
    private let price: Decimal
    private let platformFee: Decimal
    private let total: Decimal
    private let buybackRate: Decimal
    private let isTurboModeOn: Bool
    private let purchaseInteractor: any CollectiblesPackPurchaseInteractor
    private let revealAssetsPreloader: any CollectiblesRevealAssetsPreloader
    private let refreshBalance: () async -> Void

    private weak var routable: (any CollectiblesConfirmOrderRoutable)?

    private var balanceState: BalanceState = .loading
    private var orderPhase: OrderPhase = .idle
    private var revealColorScheme: ColorScheme?
    private var bag = Set<AnyCancellable>()
    private var errorDismissTask: Task<Void, Error>?

    let artworkURL: URL?
    let rows: [OrderRow]

    private(set) lazy var lowInventorySheetViewModel = CollectiblesInfoSheetViewModel(
        model: .lowInventory(
            explorePacks: { [weak self] in self?.routable?.closePackFlow() },
            enableTurboMode: { [weak self] in self?.routable?.returnToMachine() }
        )
    )

    private(set) lazy var buybackCompleteSheetViewModel = CollectiblesInfoSheetViewModel(
        model: buybackCompleteModel(amount: nil)
    )

    private(set) lazy var packUnopenedSheetViewModel = CollectiblesInfoSheetViewModel(
        model: .packUnopened(openPack: { [weak self] in self?.approve() }),
        actionTiming: .immediately
    )

    // MARK: - Publishers

    @Published private(set) var buttonState: ButtonState = .balanceLoading
    @Published private(set) var revealViewModel: CollectiblesPackRevealViewModel?
    @Published private(set) var errorMessage: String?

    // MARK: - Init

    init(
        machineID: String,
        machine: CollectiblesMachine,
        isTurboModeOn: Bool,
        usdcBalanceProvider: any TokenBalanceProvider,
        purchaseInteractor: any CollectiblesPackPurchaseInteractor,
        routable: (any CollectiblesConfirmOrderRoutable)?,
        revealAssetsPreloader: any CollectiblesRevealAssetsPreloader,
        refreshBalance: @escaping () async -> Void
    ) {
        self.machineID = machineID
        price = machine.price
        platformFee = machine.platformFee
        total = machine.price + machine.platformFee
        buybackRate = machine.buybackRate
        self.isTurboModeOn = isTurboModeOn
        self.purchaseInteractor = purchaseInteractor
        self.revealAssetsPreloader = revealAssetsPreloader
        self.routable = routable
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

        bind(usdcBalanceProvider: usdcBalanceProvider)
    }

    // MARK: - Methods

    func approve() {
        guard buttonState == .approve else { return }

        dismissError()
        orderPhase = .generating
        updateButtonState()

        if let revealColorScheme {
            revealAssetsPreloader.preload(for: revealColorScheme)
        }

        Task { [weak self, purchaseInteractor, revealAssetsPreloader, machineID, price, platformFee, isTurboModeOn, refreshBalance] in
            do {
                let result = try await purchaseInteractor.purchase(
                    machineID: machineID,
                    price: price,
                    platformFee: platformFee,
                    isTurboModeOn: isTurboModeOn,
                    onStep: { [weak self] step in self?.apply(step) }
                )

                switch result {
                case .wonCard(let wonCard):
                    let imageURLs = [wonCard.imageFrontURL, wonCard.imageBackURL].compactMap { $0 }
                    let assets = await revealAssetsPreloader.assets(prefetchingImages: imageURLs)

                    // [REDACTED_TODO_COMMENT]
                    self?.showReveal(of: wonCard, assets: assets)
                case .autoSold(let amount):
                    self?.showBuybackComplete(amount: amount)
                }
            } catch {
                self?.handlePurchaseFailure(error)
            }

            await refreshBalance()
        }
    }

    func close() {
        routable?.closePackFlow()
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
        case generating
        case confirming
        case opening
        case packGenerated
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
}

// MARK: - Private logic

private extension CollectiblesConfirmOrderViewModel {
    func bind(usdcBalanceProvider: any TokenBalanceProvider) {
        usdcBalanceProvider.balanceTypePublisher
            .map(Self.balanceState(from:))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] balanceState in
                self?.update(balanceState: balanceState)
            }
            .store(in: &bag)
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

    func showReveal(of wonCard: CollectiblesWonCard, assets: CollectiblesRevealAssets) {
        revealViewModel = CollectiblesPackRevealViewModel(
            darkVideoURL: assets.darkVideoURL,
            lightVideoURL: assets.lightVideoURL,
            prize: CollectiblesPackRevealView.Prize(wonCard: wonCard, buybackRate: buybackRate),
            player: AVCollectiblesRevealPlayer(skipAudioURL: assets.skipAudioURL)
        )
        orderPhase = .generated
        updateButtonState()
    }

    func showBuybackComplete(amount: Decimal?) {
        orderPhase = .idle
        updateButtonState()
        buybackCompleteSheetViewModel.present(with: buybackCompleteModel(amount: amount))
    }

    func buybackCompleteModel(amount: Decimal?) -> CollectiblesInfoSheetView.Model {
        let ticker = CollectiblesChainEnvironment.usdcTokenItem.currencySymbol

        return .buybackComplete(
            amount: amount.map { CollectiblesPriceFormatter.formatAmount($0, ticker: ticker) },
            price: CollectiblesPriceFormatter.formatAmount(price, ticker: ticker),
            explorePacks: { [weak self] in self?.routable?.closePackFlow() },
            openAgain: { [weak self] in self?.approve() }
        )
    }

    func handlePurchaseFailure(_ error: any Error) {
        CollectiblesLogger.error("Collectibles pack \(machineID) purchase failed", error: error)
        orderPhase = .idle
        updateButtonState()

        switch error as? CollectiblesPackPurchaseError {
        case .lowInventory:
            lowInventorySheetViewModel.present()
        case .packUnopened, .openFailed, .prizeNotDelivered:
            packUnopenedSheetViewModel.present()
        // [REDACTED_TODO_COMMENT]
        case .paymentFailed(.expired):
            showError(message: "Your purchase has expired")
        case .paymentFailed(.refunded):
            showError(message: "Your payment has been refunded")
        default:
            showError()
        }
    }

    func showError(message: String = Localization.commonSomethingWentWrong) {
        errorMessage = message

        errorDismissTask?.cancel()
        errorDismissTask = Task { [weak self] in
            try await Task.sleep(for: Constants.errorDisplayDuration)
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
        static let errorDisplayDuration: Duration = .seconds(3)
    }
}
