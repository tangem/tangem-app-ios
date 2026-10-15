//
//  PolymarketBalanceActionsAvailability.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemPolymarket

final class PolymarketBalanceActionsAvailability {
    private let accountFundsInteractor: PolymarketAccountFundsInteractor
    private let collateralBalancePublisher: AnyPublisher<TokenBalanceType, Never>
    private let withdrawalStatePublisher: AnyPublisher<PolymarketWithdrawState?, Never>

    private var readiness: PolymarketAccountFundsInteractor.State = .loading
    private var collateralBalance: TokenBalanceType = .loading(.none)
    private var isWithdrawalPending = false
    private var preparationTask: Task<Void, Never>?
    private var onChange: ((PolymarketBalanceBlockActionStates) -> Void)?
    private var bag: Set<AnyCancellable> = []

    init(
        accountFundsInteractor: PolymarketAccountFundsInteractor,
        collateralBalancePublisher: AnyPublisher<TokenBalanceType, Never>,
        withdrawalStatePublisher: AnyPublisher<PolymarketWithdrawState?, Never>
    ) {
        self.accountFundsInteractor = accountFundsInteractor
        self.collateralBalancePublisher = collateralBalancePublisher
        self.withdrawalStatePublisher = withdrawalStatePublisher
    }

    deinit {
        preparationTask?.cancel()
    }

    func start(onChange: @escaping (PolymarketBalanceBlockActionStates) -> Void) {
        self.onChange = onChange
        bindCollateralBalance()
        bindWithdrawalState()
        prepare()
    }

    func prepare() {
        preparationTask?.cancel()

        preparationTask = Task { @MainActor [weak self, accountFundsInteractor] in
            let state = await accountFundsInteractor.prepare()

            guard !Task.isCancelled else { return }

            self?.apply(state)
        }
    }
}

// MARK: - Private implementation

private extension PolymarketBalanceActionsAvailability {
    func bindCollateralBalance() {
        collateralBalancePublisher
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { availability, balance in
                availability.collateralBalance = balance
                availability.updateStates()
            }
            .store(in: &bag)
    }

    func bindWithdrawalState() {
        withdrawalStatePublisher
            .map { $0.map { !$0.isTerminal } ?? false }
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { availability, isPending in
                availability.isWithdrawalPending = isPending
                availability.updateStates()
            }
            .store(in: &bag)
    }

    func apply(_ readiness: PolymarketAccountFundsInteractor.State) {
        self.readiness = readiness
        updateStates()
    }

    func updateStates() {
        onChange?(PolymarketBalanceBlockActionStates(
            readiness: readiness,
            collateralBalance: collateralBalance,
            usdToToken: { PolymarketUSDAmount(usd: $0).inToken() },
            isWithdrawalPending: isWithdrawalPending
        ))
    }
}
