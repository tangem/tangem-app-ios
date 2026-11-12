//
//  LendingPositionCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import BlockchainSdk
import struct TangemUIUtils.AlertBinder

final class LendingPositionCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    @Injected(\.safariManager) private var safariManager: SafariManager
    @Injected(\.yieldModuleAPIService) private var yieldModuleAPIService: YieldModuleAPIService

    @Published private(set) var positionViewModel: LendingPositionViewModel?
    @Published var withdrawCoordinator: LendingWithdrawCoordinator?
    @Published var depositCoordinator: LendingDepositCoordinator?
    @Published var alert: AlertBinder?

    private var options: Options?
    private var routeTask: Task<Void, Never>?

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    deinit {
        routeTask?.cancel()
    }

    func start(with options: Options) {
        self.options = options

        let currencyId = options.token.tokenItem.currencyId
        let apyHistoryProvider = CommonLendingApyHistoryProvider(
            apiService: yieldModuleAPIService,
            chainId: LendingOnAave.blockchain.chainId ?? 0,
            wrappedNative: { LendingOnAave.wrappedNativeAddress }
        )

        MainActor.assumeIsolated {
            positionViewModel = LendingPositionViewModel(
                tokenItem: options.token.tokenItem,
                currentApy: options.currentApy,
                performanceFee: LendingOnAave.performanceFee,
                // [REDACTED_TODO_COMMENT]
                details: .lendingOnAave(performanceFee: LendingOnAave.performanceFee, auditReportURL: nil),
                currencyCode: AppSettings.shared.selectedCurrencyCode,
                liquidityProvider: options.liquidityProvider,
                apyHistoryProvider: apyHistoryProvider,
                fiatConverter: { value in
                    guard let currencyId else { return nil }
                    return try? await BalanceConverter().convertToFiat(value, currencyId: currencyId)
                },
                pendingTransactions: options.pendingTransactions,
                router: self
            )
        }
    }
}

// MARK: - Options

extension LendingPositionCoordinator {
    struct Options {
        let token: SendTransferableToken
        let currentApy: Decimal?
        let liquidityProvider: YieldModuleLendingLiquidityProvider
        let entryLoader: LendingDepositEntryLoader
        let pendingTransactions: AnyPublisher<[PendingTransactionRecord], Never>
    }
}

// MARK: - LendingPositionRoutable

extension LendingPositionCoordinator: LendingPositionRoutable {
    func openWithdraw(position: Decimal, available: Decimal?) {
        guard let options, routeTask == nil else {
            return
        }

        routeTask = Task { @MainActor [weak self] in
            self?.positionViewModel?.setWithdrawLoading(true)
            let result: Result<LendingWithdrawalTarget?, Error>

            do {
                result = try await .success(options.entryLoader.withdrawalTarget())
            } catch {
                result = .failure(error)
            }

            self?.positionViewModel?.setWithdrawLoading(false)
            self?.routeTask = nil

            guard let self, !Task.isCancelled else {
                return
            }

            guard case .success(.some(let target)) = result else {
                alert = withdrawalUnavailableAlert(result, position: position, available: available)
                return
            }

            let coordinator = LendingWithdrawCoordinator(
                dismissAction: { [weak self] _ in
                    self?.withdrawCoordinator = nil
                    self?.reloadPosition()
                },
                popToRootAction: popToRootAction
            )

            coordinator.start(with: LendingWithdrawCoordinator.Options(
                token: options.token,
                yieldModule: target.yieldModule,
                upgradeImplementation: target.upgradeImplementation,
                positionBalance: position,
                availableToWithdraw: available,
                liquidityProvider: options.liquidityProvider,
                pendingTransactions: options.pendingTransactions
            ))

            withdrawCoordinator = coordinator
        }
    }

    func openAddFunds() {
        guard let options, routeTask == nil else {
            return
        }

        routeTask = Task { @MainActor [weak self] in
            self?.positionViewModel?.setAddFundsLoading(true)
            let entry = await options.entryLoader.load()
            let currentApy = await Self.currentApy(known: options.currentApy)

            self?.positionViewModel?.setAddFundsLoading(false)
            self?.routeTask = nil

            guard let self, !Task.isCancelled else {
                return
            }

            switch (options.entryLoader.depositRequest(for: entry), currentApy) {
            case (.some(let request), .some(let currentApy)):
                let coordinator = LendingDepositCoordinator(
                    dismissAction: { [weak self] output in
                        self?.handleDepositOutput(output)
                    },
                    popToRootAction: popToRootAction
                )

                coordinator.start(with: LendingDepositCoordinator.Options(
                    token: options.token,
                    request: request,
                    currentApy: currentApy,
                    performanceFee: LendingOnAave.performanceFee,
                    source: .infoScreen
                ))

                depositCoordinator = coordinator
            case (.none, _) where entry == .blocked(.unsupportedModule):
                alert = LendingDepositEntryAlertBuilder.updateRequiredAlert()
            case (.none, _), (.some, .none):
                alert = LendingDepositEntryAlertBuilder.readFailedAlert { [weak self] in
                    self?.openAddFunds()
                }
            }
        }
    }

    func openHowItWorks() {
        // [REDACTED_TODO_COMMENT]
    }

    func openURL(_ url: URL) {
        safariManager.openURL(url)
    }

    func closeLendingPosition() {
        dismissAction(())
    }
}

// MARK: - Private

private extension LendingPositionCoordinator {
    static func currentApy(known: Decimal?) async -> Decimal? {
        if let known {
            return known
        }

        return try? await InjectedValues[\.lendingRateRepository].refreshApy()
    }

    func handleDepositOutput(_ output: LendingDepositCoordinator.OutputOptions) {
        depositCoordinator = nil

        switch output {
        case .close, .yield:
            reloadPosition()
        case .token:
            dismissAction(())
        }
    }

    func withdrawalUnavailableAlert(_ result: Result<LendingWithdrawalTarget?, Error>, position: Decimal, available: Decimal?) -> AlertBinder {
        guard case .failure(let error) = result else {
            return LendingDepositEntryAlertBuilder.readFailedAlert { [weak self] in
                self?.openWithdraw(position: position, available: available)
            }
        }

        if error as? LendingWithdrawalTargetError == .unsupportedModule {
            return LendingDepositEntryAlertBuilder.updateRequiredAlert()
        }

        AppLogger.error(error: error)
        return LendingDepositEntryAlertBuilder.readFailedAlert { [weak self] in
            self?.openWithdraw(position: position, available: available)
        }
    }

    func reloadPosition() {
        Task { @MainActor [weak self] in
            self?.positionViewModel?.reloadPosition()
        }
    }
}
