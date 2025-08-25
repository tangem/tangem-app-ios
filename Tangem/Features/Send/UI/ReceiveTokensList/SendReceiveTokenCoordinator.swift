//
//  SendReceiveTokenCoordinator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class SendReceiveTokenCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Dependencies

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    // MARK: - Root view model

    @Published private(set) var rootViewModel: SendReceiveTokensListViewModel?

    // MARK: - Child view models

    @Published var receiveTokenNetworkSelectorViewModel: SendReceiveTokenNetworkSelectorViewModel?

    // MARK: - Dependencies

    private let receiveTokensListBuilder: SendReceiveTokensListBuilder

    required init(
        receiveTokensListBuilder: SendReceiveTokensListBuilder,
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.receiveTokensListBuilder = receiveTokensListBuilder
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = receiveTokensListBuilder.makeReceiveTokensListViewModel(router: self)
    }
}

// MARK: - Options

extension SendReceiveTokenCoordinator {
    enum Options {
        case `default`
    }
}

// MARK: - SendReceiveTokensListViewRoutable

extension SendReceiveTokenCoordinator: SendReceiveTokensListViewRoutable {
    func openNetworkSelector(networks: [TokenItem]) {
        let selectorViewModel = receiveTokensListBuilder
            .makeReceiveTokenNetworkSelectorViewModel(networks: networks, router: self)

        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: selectorViewModel)
        }
    }

    func closeTokensList() {
        dismiss()
    }
}

// MARK: - SendReceiveTokenNetworkSelectorViewRoutable

extension SendReceiveTokenCoordinator: SendReceiveTokenNetworkSelectorViewRoutable {
    func dismissNetworkSelector(isSelected: Bool) {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()

            if isSelected {
                dismiss()
            }
        }
    }
}
