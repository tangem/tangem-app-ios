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
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

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

        // The invite is read on behalf of the wallet the app has selected, whichever one ends up joining
        guard let selectedUserWalletModel = userWalletRepository.selectedModel else {
            // The link is only ever routed with a wallet selected, so there is nothing to read the invite with here
            let message = "A joint account invite was opened with no wallet selected"
            AccountsLogger.error(error: message)
            assertionFailure(message)

            dismiss()
            return
        }

        let networkService = CommonJointAccountsNetworkService(userWalletId: selectedUserWalletModel.userWalletId)
        let userWalletModels = userWalletRepository.models

        Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            rootViewModel = JointAccountJoinViewModel(
                inviteId: options.inviteId,
                networkService: networkService,
                userWalletModels: userWalletModels,
                coordinator: self
            )
        }
    }
}

// MARK: - Private

private extension JointAccountJoinCoordinator {
    func openMemberName(userWalletModel: any UserWalletModel, preview: JointAccountInvitePreview) {
        guard let options else {
            return
        }

        let viewModel = JointAccountMemberNameViewModel(
            helper: JointAccountJoinMemberNameHelper(
                inviteId: options.inviteId,
                signedConfig: preview.config,
                userWalletModel: userWalletModel,
                routable: self
            ),
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

    func continueJoin(userWalletModel: any UserWalletModel, preview: JointAccountInvitePreview) {
        Task { @MainActor in
            floatingSheetPresenter.enqueue(
                sheet: JointAccountJoinConfirmationViewModel(
                    userWalletModel: userWalletModel,
                    preview: preview,
                    coordinator: self
                )
            )
        }
    }
}

// MARK: - JointAccountJoinConfirmationRoutable

extension JointAccountJoinCoordinator: JointAccountJoinConfirmationRoutable {
    func confirmJoin(userWalletModel: any UserWalletModel, preview: JointAccountInvitePreview) {
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            floatingSheetPresenter.removeActiveSheet()

            openMemberName(userWalletModel: userWalletModel, preview: preview)
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

// MARK: - JointAccountJoinMemberNameRoutable

extension JointAccountJoinCoordinator: JointAccountJoinMemberNameRoutable {
    func closeJoinedAccount() {
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
