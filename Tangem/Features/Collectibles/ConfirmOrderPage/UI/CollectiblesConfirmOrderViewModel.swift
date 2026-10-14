//
//  CollectiblesConfirmOrderViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
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
    private let openingVideoURL: URL?
    private let purchaseInteractor: any CollectiblesPackPurchaseInteractor
    private weak var routable: (any CollectiblesConfirmOrderRoutable)?
    private let refreshBalance: () async -> Void

    private var balanceState: BalanceState = .loading
    private var orderPhase: OrderPhase = .idle
    private var bag = Set<AnyCancellable>()
    private var errorDismissTask: Task<Void, Error>?

    let artworkURL: URL?
    let rows: [OrderRow]

    // MARK: - Publishers

    @Published private(set) var buttonState: ButtonState = .balanceLoading
    @Published private(set) var revealViewModel: CollectiblesPackRevealViewModel?
    @Published private(set) var errorMessage: String?

    // MARK: - Init

    init(
        machineID: String,
        machine: CollectiblesMachine,
        usdcBalanceProvider: any TokenBalanceProvider,
        purchaseInteractor: any CollectiblesPackPurchaseInteractor,
        routable: (any CollectiblesConfirmOrderRoutable)?,
        refreshBalance: @escaping () async -> Void
    ) {
        self.machineID = machineID
        price = machine.price
        platformFee = machine.platformFee
        total = machine.price + machine.platformFee
        buybackRate = machine.buybackRate
        openingVideoURL = machine.openingVideoURL
        self.purchaseInteractor = purchaseInteractor
        self.routable = routable
        self.refreshBalance = refreshBalance
        artworkURL = machine.artworkURL
        rows = [
            OrderRow(
                title: "\(machine.name) x1",
                value: CollectiblesPriceFormatter.format(machine.price),
                isTotal: false
            ),
            OrderRow(
                title: Localization.collectiblesConfirmOrderPlatformFee,
                value: CollectiblesPriceFormatter.format(machine.platformFee),
                isTotal: false
            ),
            OrderRow(
                title: Localization.collectiblesConfirmOrderTotal,
                value: CollectiblesPriceFormatter.formatAmount(
                    total,
                    ticker: CollectiblesChainEnvironment.usdcTokenItem.currencySymbol
                ),
                isTotal: true
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

        Task { [weak self, purchaseInteractor, machineID, price, platformFee, refreshBalance] in
            let result: Result<CollectiblesWonCard, any Error>

            do {
                let wonCard = try await purchaseInteractor.purchase(
                    machineID: machineID,
                    price: price,
                    platformFee: platformFee,
                    turboMode: .off,
                    onStep: { [weak self] step in self?.apply(step) }
                )
                result = .success(wonCard)
            } catch {
                result = .failure(error)
            }

            // [REDACTED_TODO_COMMENT]
            self?.handlePurchaseResult(result)
            await refreshBalance()
        }
    }

    func close() {
        routable?.closePackFlow()
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
    struct OrderRow: Hashable {
        let title: String
        let value: String
        let isTotal: Bool
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

    func handlePurchaseResult(_ result: Result<CollectiblesWonCard, any Error>) {
        switch result {
        case .success(let wonCard):
            let bundledVideoURL = Bundle.main.url(forResource: "CollectiblesPackReveal", withExtension: "mp4")
            revealViewModel = CollectiblesPackRevealViewModel(
                videoURL: openingVideoURL ?? bundledVideoURL,
                prize: CollectiblesPackRevealView.Prize(wonCard: wonCard, buybackRate: buybackRate)
            )
            orderPhase = .generated
        case .failure(let error):
            CollectiblesLogger.error("Collectibles pack \(machineID) purchase failed", error: error)
            orderPhase = .idle
            showError()
        }

        updateButtonState()
    }

    func showError() {
        errorMessage = Localization.commonSomethingWentWrong

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
