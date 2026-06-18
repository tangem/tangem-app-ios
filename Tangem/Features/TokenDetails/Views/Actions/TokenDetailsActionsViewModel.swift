//
//  TokenDetailsActionsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemFoundation
import TangemLocalization
import TangemUI

final class TokenDetailsActionsViewModel: ObservableObject {
    @Published private(set) var mode: Mode = .hidden

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    private let walletModel: any WalletModel
    private let availabilityProvider: TokenActionAvailabilityProvider
    private weak var actionsRoutable: (any TokenDetailsActionsRoutable)?

    private var bag = Set<AnyCancellable>()

    init(
        walletModel: any WalletModel,
        userWalletInfo: UserWalletInfo
    ) {
        self.walletModel = walletModel
        availabilityProvider = TokenActionAvailabilityProvider(
            userWalletConfig: userWalletInfo.config,
            walletModel: walletModel
        )
    }

    func setRoutable(_ routable: any TokenDetailsActionsRoutable) {
        actionsRoutable = routable
        bind()
    }
}

// MARK: - Bindings

private extension TokenDetailsActionsViewModel {
    func bind() {
        Publishers.CombineLatest(
            walletModel.totalTokenBalanceProvider.balanceTypePublisher.removeDuplicates(),
            walletModel.actionsUpdatePublisher.prepend(())
        )
        .map { balanceType, _ in balanceType }
        .receiveOnMain()
        .withWeakCaptureOf(self)
        .sink { viewModel, balanceType in
            MainActor.assumeIsolated {
                viewModel.rebuildMode(for: balanceType)
            }
        }
        .store(in: &bag)
    }

    func rebuildMode(for balanceType: TokenBalanceType) {
        if isBalanceNonZero(balanceType) {
            let buttons = makeButtonsRow()
            mode = buttons.isNotEmpty ? .buttonsRow(buttons: buttons) : .hidden
        } else {
            let items = incomingOptions().map { type in
                makeRowItem(
                    for: type,
                    isAvailable: isRowItemAvailable(for: type),
                    onTap: { [weak self] in
                        self?.perform(type, kind: .addFunds)
                    }
                )
            }
            mode = items.isNotEmpty ? .inlineList(items: items) : .hidden
        }
    }
}

// MARK: - Mode building

private extension TokenDetailsActionsViewModel {
    func makeButtonsRow() -> [TokenDetailsActionsButton] {
        var buttons: [TokenDetailsActionsButton] = []

        if let addFunds = makeAddFundsButton() {
            buttons.append(addFunds)
        }

        if let swap = makeSwapButton() {
            buttons.append(swap)
        }

        buttons.append(makeTransferButton())

        return buttons
    }

    func makeAddFundsButton() -> TokenDetailsActionsButton? {
        let options = incomingOptions()
        guard options.isNotEmpty else { return nil }

        let longPressAction: (() -> Void)? = availabilityProvider.isReceiveAvailable
            ? { [weak self] in
                Task { @MainActor in
                    self?.actionsRoutable?.copyDefaultAddress()
                }
            }
            : nil

        return TokenDetailsActionsButton(
            id: .addFunds,
            title: Localization.commonAddFunds,
            icon: Assets.arrowDownMini,
            accessibilityIdentifier: ActionButtonsAccessibilityIdentifiers.addFundsButton,
            isAvailable: true,
            action: { [weak self] in
                self?.handleGroupTap(kind: .addFunds, options: options)
            },
            longPressAction: longPressAction
        )
    }

    func makeSwapButton() -> TokenDetailsActionsButton? {
        guard isSwapButtonVisible else { return nil }

        return TokenDetailsActionsButton(
            id: .swap,
            title: Localization.commonSwap,
            icon: Assets.exchangeMini,
            accessibilityIdentifier: TokenActionType.exchange.accessibilityIdentifier,
            isAvailable: availabilityProvider.isSwapAvailable,
            action: { [weak self] in
                self?.perform(.exchange, kind: .swap)
            },
            longPressAction: nil
        )
    }

    func makeTransferButton() -> TokenDetailsActionsButton {
        let options = outgoingOptions()
        return TokenDetailsActionsButton(
            id: .transfer,
            title: Localization.commonTransfer,
            icon: Assets.arrowUpMini,
            accessibilityIdentifier: ActionButtonsAccessibilityIdentifiers.transferButton,
            isAvailable: true,
            action: { [weak self] in
                self?.handleGroupTap(kind: .transfer, options: options)
            },
            longPressAction: nil
        )
    }

    func handleGroupTap(kind: TokenDetailsActionsKind, options: [TokenActionType]) {
        if let single = options.singleElement {
            perform(single, kind: kind)
        } else {
            presentSheet(kind: kind, options: options)
        }
    }

    func perform(_ type: TokenActionType, kind: TokenDetailsActionsKind) {
        Task { @MainActor in
            if type == .exchange {
                actionsRoutable?.performSwapAction(position: kind.swapPosition)
            } else {
                actionsRoutable?.performTokenAction(type)
            }
        }
    }

    func presentSheet(kind: TokenDetailsActionsKind, options: [TokenActionType]) {
        let items = options.map { type in
            makeRowItem(
                for: type,
                isAvailable: isRowItemAvailable(for: type),
                onTap: { [weak self] in
                    self?.dismissSheet()
                    self?.perform(type, kind: kind)
                }
            )
        }
        let sheetViewModel = TokenDetailsActionsBottomSheetViewModel(
            title: title(for: kind),
            items: items,
            onClose: { [weak self] in
                self?.dismissSheet()
            }
        )

        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: sheetViewModel)
        }
    }

    func isRowItemAvailable(for actionType: TokenActionType) -> Bool {
        switch actionType {
        case .buy: availabilityProvider.isBuyAvailable
        case .send: true
        case .exchange: availabilityProvider.isSwapAvailable
        case .sell: availabilityProvider.isSellAvailable
        case .receive: availabilityProvider.isReceiveAvailable
        default: false
        }
    }

    func makeRowItem(
        for type: TokenActionType,
        isAvailable: Bool,
        onTap: @escaping () -> Void
    ) -> TokenDetailsActionRowItem {
        TokenDetailsActionRowItem(
            id: type,
            title: type.title,
            subtitle: subtitle(for: type),
            icon: type.icon,
            accessibilityIdentifier: type.accessibilityIdentifier,
            isAvailable: isAvailable,
            action: onTap
        )
    }

    func dismissSheet() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}

// MARK: - Availability

private extension TokenDetailsActionsViewModel {
    var isSwapButtonVisible: Bool {
        availabilityProvider.buildAvailableButtonsList().contains(.exchange)
    }

    func incomingOptions() -> [TokenActionType] {
        var options: [TokenActionType] = []
        if availabilityProvider.isBuyAvailable { options.append(.buy) }
        if isSwapButtonVisible { options.append(.exchange) }
        if availabilityProvider.isReceiveAvailable { options.append(.receive) }
        return options
    }

    func outgoingOptions() -> [TokenActionType] {
        [.send, .exchange, .sell]
    }
}

// MARK: - Balance helpers

private extension TokenDetailsActionsViewModel {
    func isBalanceNonZero(_ balanceType: TokenBalanceType) -> Bool {
        switch balanceType {
        case .empty:
            return false
        case .loaded(let amount):
            return amount != .zero
        case .failure(let cached):
            return cached != nil && cached?.balance != .zero
        case .loading(let cached):
            // While loading without cache, assume non-zero so the standard buttons row
            // stays in place instead of flashing the zero-balance inline list.
            return cached == nil || cached?.balance != .zero
        }
    }
}

// MARK: - Localization

private extension TokenDetailsActionsViewModel {
    func title(for kind: TokenDetailsActionsKind) -> String {
        switch kind {
        case .addFunds: return Localization.commonGetToken
        case .swap: return Localization.commonSwap
        case .transfer: return Localization.commonTransfer
        }
    }

    func subtitle(for type: TokenActionType) -> String? {
        switch type {
        case .buy: return Localization.quickActionBuyDescription
        case .exchange: return Localization.quickActionSwapDescription
        case .receive: return Localization.quickActionReceiveDescription
        case .send: return Localization.quickActionSendDescription
        case .sell: return Localization.quickActionSellDescription
        case .copyAddress, .hide, .stake, .marketsDetails, .yield: return nil
        }
    }
}

// MARK: - Mode

extension TokenDetailsActionsViewModel {
    enum Mode {
        case hidden
        case buttonsRow(buttons: [TokenDetailsActionsButton])
        case inlineList(items: [TokenDetailsActionRowItem])
    }
}
