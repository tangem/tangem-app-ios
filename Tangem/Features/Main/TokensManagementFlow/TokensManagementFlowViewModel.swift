//
//  TokensManagementFlowViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemLocalization
import TangemMacro
import TangemUI

final class TokensManagementFlowViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Published private(set) var state: ViewState = .chooser

    private let userWalletModel: UserWalletModel
    private weak var coordinator: TokensManagementFlowRoutable?

    init(userWalletModel: UserWalletModel, coordinator: TokensManagementFlowRoutable) {
        self.userWalletModel = userWalletModel
        self.coordinator = coordinator
    }
}

// MARK: - Navigation

extension TokensManagementFlowViewModel {
    func openOrganize() {
        let organizeViewModel = OrganizeTokensViewModel(userWalletModel: userWalletModel, coordinator: self)
        state = .organize(organizeViewModel)
    }

    func openAddTokens() {
        state = .chooseAccount
    }

    func proceedToManage() {
        state = .manage
    }

    func openAddCustomToken() {
        state = .addCustomToken
    }

    func close() {
        Task { @MainActor in
            coordinator?.closeTokensManagementFlow()
        }
    }
}

// MARK: - OrganizeTokensRoutable

extension TokensManagementFlowViewModel: OrganizeTokensRoutable {
    func didTapCancelButton() {
        close()
    }

    func didTapSaveButton() {
        close()
    }
}

// MARK: - ViewState

extension TokensManagementFlowViewModel {
    @RawCaseName
    enum ViewState {
        case chooser
        case chooseAccount
        case organize(OrganizeTokensViewModel)
        case manage
        case addCustomToken

        var title: String {
            switch self {
            case .chooser: return Localization.mainAddAndManageTokens
            case .chooseAccount: return Localization.commonChooseAccount
            case .organize: return Localization.organizeTokensTitle
            case .manage: return Localization.addTokensTitle
            case .addCustomToken: return Localization.addCustomTokenTitle
            }
        }

        var fillsAvailableHeight: Bool {
            switch self {
            case .chooser, .chooseAccount: return false
            case .organize, .manage, .addCustomToken: return true
            }
        }

        var hidesContainerHeader: Bool {
            switch self {
            case .organize: return true
            case .chooser, .chooseAccount, .manage, .addCustomToken: return false
            }
        }
    }
}
