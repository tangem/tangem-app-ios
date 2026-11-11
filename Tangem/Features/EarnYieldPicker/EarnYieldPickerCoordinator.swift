//
//  EarnYieldPickerCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemUI
import struct TangemUIUtils.AlertBinder

final class EarnYieldPickerCoordinator: CoordinatorObject {
    let dismissAction: Action<DismissOptions?>
    let popToRootAction: Action<PopToRootOptions>

    @Injected(\.safariManager) private var safariManager: SafariManager

    @Published private(set) var pickerViewModel: EarnYieldPickerViewModel?
    @Published var lendingDepositCoordinator: LendingDepositCoordinator?
    @Published var getTokenSheet: EarnGetTokenSheetViewModel?
    @Published var alert: AlertBinder?

    private var options: Options?
    private var depositEntryTask: Task<Void, Never>?

    required init(
        dismissAction: @escaping Action<DismissOptions?>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        self.options = options

        MainActor.assumeIsolated {
            pickerViewModel = EarnYieldPickerViewModel(
                products: options.products,
                selectedProductID: options.selectedProductID,
                balanceProvider: options.balanceProvider,
                currencyCode: options.currencyCode,
                coordinator: self
            )
        }
    }
}

// MARK: - Options

extension EarnYieldPickerCoordinator {
    struct Options {
        let products: [EarnYieldPickerProduct]
        let selectedProductID: EarnYieldPickerProduct.ID
        let balanceProvider: TokenBalanceProvider
        let currencyCode: String
        let lendingToken: SendTransferableToken
        let lendingEntryLoader: LendingDepositEntryLoader
        let addFundsOptions: () -> [TokenDetailsActionsViewModel.AddFundsOption]
    }
}

// MARK: - DismissOptions

extension EarnYieldPickerCoordinator {
    enum DismissOptions {
        case openStaking
        case addFunds(TokenActionType)
        case openLendingPosition
    }
}

// MARK: - EarnYieldPickerRoutable

extension EarnYieldPickerCoordinator: EarnYieldPickerRoutable {
    func openStartEarning(for product: EarnYieldPickerProduct) {
        switch product.id {
        case .pooledStaking:
            dismissAction(.openStaking)
        case .lendingOnAave:
            openLendingDeposit(product: product)
        }
    }

    func openAddFunds() {
        guard let options else {
            return
        }

        let addFundsOptions = options.addFundsOptions()

        guard addFundsOptions.isNotEmpty else {
            return
        }

        getTokenSheet = EarnGetTokenSheetViewModel.make(
            tokenSymbol: options.lendingToken.tokenItem.currencySymbol,
            options: addFundsOptions,
            onSelect: { [weak self] type in
                self?.getTokenSheet = nil
                self?.dismissAction(.addFunds(type))
            }
        )
    }

    func openIncentiveInfo(for product: EarnYieldPickerProduct) {
        // [REDACTED_TODO_COMMENT]
    }

    func openURL(_ url: URL) {
        safariManager.openURL(url)
    }

    func dismissYieldPicker() {
        dismissAction(nil)
    }
}

// MARK: - Lending deposit

private extension EarnYieldPickerCoordinator {
    func openLendingDeposit(product: EarnYieldPickerProduct) {
        guard let options, depositEntryTask == nil else {
            return
        }

        depositEntryTask = Task { @MainActor [weak self] in
            self?.pickerViewModel?.isPrimaryActionLoading = true
            let entry = await options.lendingEntryLoader.load()
            self?.pickerViewModel?.isPrimaryActionLoading = false
            self?.depositEntryTask = nil
            self?.handle(entry, product: product, options: options)
        }
    }

    @MainActor
    func handle(_ entry: LendingDepositEntry, product: EarnYieldPickerProduct, options: Options) {
        switch entry {
        case .deposit(let yieldModule, let upgradeImplementation):
            let coordinator = LendingDepositCoordinator(
                dismissAction: { [weak self] output in
                    self?.handleDepositOutput(output)
                },
                popToRootAction: popToRootAction
            )

            coordinator.start(with: LendingDepositCoordinator.Options(
                token: options.lendingToken,
                yieldModule: yieldModule,
                upgradeImplementation: upgradeImplementation,
                currentApy: product.apy,
                performanceFee: product.performanceFee,
                source: .yieldPicker
            ))

            lendingDepositCoordinator = coordinator
        case .blocked(.failedToLoad):
            alert = LendingDepositEntryAlertBuilder.readFailedAlert { [weak self] in
                self?.openLendingDeposit(product: product)
            }
        case .blocked(.unsupportedModule):
            alert = LendingDepositEntryAlertBuilder.updateRequiredAlert()
        case .blocked:
            // [REDACTED_TODO_COMMENT]
            break
        }
    }

    func handleDepositOutput(_ output: LendingDepositCoordinator.OutputOptions) {
        lendingDepositCoordinator = nil

        switch output {
        case .close:
            break
        case .token:
            dismissAction(nil)
        case .yield:
            dismissAction(.openLendingPosition)
        }
    }
}
