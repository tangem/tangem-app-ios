//
//  AccountRowButtonViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemAccounts
import TangemFoundation
import TangemLocalization

final class AccountRowButtonViewModel: Identifiable, ObservableObject {
    // MARK: - View State

    let id: AnyHashable

    @Published private(set) var name: String
    @Published private(set) var iconData: AccountIconView.ViewData
    @Published private(set) var subtitleState: SubtitleState = .none

    let isDisabled: Bool

    // MARK: - Private Properties

    private let availability: AccountAvailability
    private let accountModel: any BaseAccountModel
    private let onTap: () -> Void

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(
        accountModel: any BaseAccountModel,
        availability: AccountAvailability = .available,
        onTap: @escaping () -> Void
    ) {
        self.accountModel = accountModel
        self.availability = availability
        self.onTap = onTap

        id = accountModel.id.toAnyHashable()
        name = accountModel.name
        iconData = AccountModelUtils.UI.iconViewData(accountModel: accountModel)
        isDisabled = availability != .available

        bind()
    }

    // MARK: - Public

    func onSelect() {
        onTap()
    }

    // MARK: - Private Methods

    private func bind() {
        accountModel
            .didChangePublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.onAccountModelDidChange()
            }
            .store(in: &bag)

        accountModel.resolve(using: BindingResolver(viewModel: self))
    }

    private func onAccountModelDidChange() {
        name = accountModel.name
        iconData = AccountModelUtils.UI.iconViewData(accountModel: accountModel)
    }

    private func updateSubtitleState(description: String, balanceState: LoadableTokenBalanceView.State) {
        if case .unavailable(let reason) = availability, let reason {
            subtitleState = .unavailableWithReason(reason)
            return
        }

        let hasDescription = description.isNotEmpty
        let hasBalance = balanceState != .empty

        if hasDescription, hasBalance {
            subtitleState = .descriptionWithBalance(description, balanceState)
        } else if hasDescription {
            subtitleState = .descriptionOnly(description)
        } else if hasBalance {
            subtitleState = .balanceOnly(balanceState)
        } else {
            subtitleState = .none
        }
    }
}

// MARK: - SubtitleState

extension AccountRowButtonViewModel {
    enum SubtitleState: Equatable {
        case descriptionOnly(String)
        case descriptionWithBalance(String, LoadableTokenBalanceView.State)
        case balanceOnly(LoadableTokenBalanceView.State)
        case unavailableWithReason(String)
        case none
    }
}

// MARK: - BindingResolver

extension AccountRowButtonViewModel {
    private struct BindingResolver: AccountModelResolving {
        let viewModel: AccountRowButtonViewModel
        
        func resolve(accountModel: any CryptoAccountModel) -> Void {
            Publishers.CombineLatest(
                accountModel.userTokensManager.userTokensPublisher
                    .map { Localization.commonTokensCount($0.count) },
                accountModel.fiatTotalBalanceProvider.totalFiatBalancePublisher
            )
            .receiveOnMain()
            .withWeakCaptureOf(viewModel)
            .sink { vm, tuple in
                let (description, balanceState) = tuple
                vm.updateSubtitleState(description: description, balanceState: balanceState)
            }
            .store(in: &viewModel.bag)
        }
        
        func resolve(accountModel: any SmartAccountModel) -> Void {
            // No binding needed for SmartAccountModel
        }
        
        func resolve(accountModel: any VisaAccountModel) -> Void {
            // No binding needed for VisaAccountModel
        }
    }
}
