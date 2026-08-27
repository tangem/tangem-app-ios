//
//  JointAccountJoinCoordinator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemUI

final class JointAccountJoinCoordinator: CoordinatorObject {
    // MARK: - Injected

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    // MARK: - Navigation actions

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: JointAccountJoinViewModel?

    // MARK: - Dependencies

    private var options: Options?

    init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        self.options = options

        Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            guard
                let preview = try? await options.networkService.getInvitePreview(inviteId: options.inviteId),
                let viewModel = JointAccountJoinViewModel(
                    preview: preview,
                    userWalletModels: options.userWalletModels,
                    coordinator: self
                )
            else {
                dismiss()
                return
            }

            rootViewModel = viewModel
        }
    }
}

// MARK: - Options

extension JointAccountJoinCoordinator {
    struct Options {
        let inviteId: String
        let networkService: JointAccountsNetworkService
        let userWalletModels: [any UserWalletModel]
    }
}

// MARK: - JointAccountJoinRoutable

extension JointAccountJoinCoordinator: JointAccountJoinRoutable {
    func closeJoin() {
        dismiss()
    }

    func openCreatorDetails(name: String, address: String, accentColor: Color) {
        let viewModel = JointAccountMemberDetailsViewModel(
            name: name,
            address: address,
            accentColor: accentColor,
            coordinator: self
        )

        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openWalletSelection(accountSelectorViewModel: AccountSelectorViewModel) {
        Task { @MainActor in
            floatingSheetPresenter.enqueue(
                sheet: JointAccountWalletSelectionViewModel(
                    accountSelectorViewModel: accountSelectorViewModel,
                    close: floatingSheetPresenter.removeActiveSheet
                )
            )
        }
    }

    func closeWalletSelection() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }

    func continueJoin(userWalletModel: any UserWalletModel) {
        // [REDACTED_TODO_COMMENT]
    }
}

// MARK: - JointAccountMemberDetailsRoutable

extension JointAccountJoinCoordinator: JointAccountMemberDetailsRoutable {
    func closeMemberDetails() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}
