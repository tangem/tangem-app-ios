//
//  SendFeeCurrencyNavigating.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - SendFeeCurrencyNavigating

protocol SendFeeCurrencyNavigating: FeeCurrencyNavigating {
    var sendCoordinator: SendCoordinator? { get set }
}

// MARK: - Default implementation

extension SendFeeCurrencyNavigating {
    func makeSendCoordinator() -> SendCoordinator {
        return SendCoordinator(
            dismissAction: makeSendCoordinatorDismissAction(),
            popToRootAction: makeSendCoordinatorPopToRootAction()
        )
    }

    func makeSendCoordinatorDismissAction() -> Action<SendCoordinator.DismissOptions?> {
        return { [weak self] dismissOptions in
            self?.sendCoordinator = nil

            switch dismissOptions {
            case .openFeeCurrency(let feeCurrency):
                self?.proceedFeeCurrencyNavigatingDismissOption(option: feeCurrency)
            case .openSwap(let option):
                self?.proceedSwapNavigatingDismissOption(option: option)
            case .closeButtonTap, .none:
                break
            }
        }
    }

    func proceedSwapNavigatingDismissOption(option: SwapNavigatingDismissOption) {
        guard let options = option.makeSwapFlowOptions(source: .main) else {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Self.feeCurrencyNavigationDelay) { [weak self] in
            guard let self else { return }

            let coordinator = makeSendCoordinator()
            coordinator.start(with: options)
            sendCoordinator = coordinator
        }
    }

    func makeSendCoordinatorPopToRootAction() -> Action<PopToRootOptions> {
        return { [weak self] options in
            self?.sendCoordinator = nil
            self?.popToRoot(with: options)
        }
    }
}
