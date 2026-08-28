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

    @Published var path: [Step] = []

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

// MARK: - Private

private extension JointAccountJoinCoordinator {
    func openMemberName(userWalletModel: any UserWalletModel) {
        let viewModel = JointAccountMemberNameViewModel(
            helper: JointAccountJoinMemberNameHelper(userWalletModel: userWalletModel),
            coordinator: self
        )

        path.append(.memberName(viewModel: viewModel))
    }
}

// MARK: - Steps

extension JointAccountJoinCoordinator {
    enum Step {
        case memberName(viewModel: JointAccountMemberNameViewModel)
    }
}

extension JointAccountJoinCoordinator.Step: Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.memberName(let lhs), .memberName(let rhs)): lhs === rhs
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .memberName(let viewModel): hasher.combine(ObjectIdentifier(viewModel))
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
        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: JointAccountJoinConfirmationViewModel(coordinator: self))
        }
    }
}

// MARK: - JointAccountJoinConfirmationRoutable

extension JointAccountJoinCoordinator: JointAccountJoinConfirmationRoutable {
    func confirmJoin() {
        Task { @MainActor [weak self] in
            guard let self, let userWalletModel = rootViewModel?.selectedUserWalletModel else {
                return
            }

            floatingSheetPresenter.removeActiveSheet()
            openMemberName(userWalletModel: userWalletModel)
        }
    }

    /// Backing out leaves the picked wallet alone — the user stays on the invite screen with it still selected.
    func cancelJoin() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}

// MARK: - JointAccountMemberNameRoutable

extension JointAccountJoinCoordinator: JointAccountMemberNameRoutable {
    func closeMemberName() {
        dismiss()
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
