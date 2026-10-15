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
import TangemUI

final class AccountRowButtonViewModel: Identifiable, ObservableObject {
    // MARK: - View State

    let id: AnyHashable

    @Published private(set) var name: String
    @Published private(set) var iconData: AccountIconView.ViewData
    @Published private(set) var subtitleState: SubtitleState = .none
    @Published private(set) var trailingBalanceState: LoadableBalanceView.State?
    @Published private(set) var isBalanceUnavailable = false

    let isDisabled: Bool
    let nameBadge: String?

    // MARK: - Private Properties

    private let availability: AccountAvailability
    private let accountModel: any BaseAccountModel
    private let onTap: () -> Void

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(
        accountModel: any BaseAccountModel,
        availability: AccountAvailability = .available,
        nameBadge: String? = nil,
        onTap: @escaping () -> Void
    ) {
        self.accountModel = accountModel
        self.availability = availability
        self.nameBadge = nameBadge
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

    private func updateSubtitleState(description: String, balanceState: LoadableBalanceView.State) {
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
        case descriptionWithBalance(String, LoadableBalanceView.State)
        case balanceOnly(LoadableBalanceView.State)
        case unavailableWithReason(String)
        case none
    }
}

// MARK: - BindingResolver

private extension AccountRowButtonViewModel {
    struct BindingResolver: AccountModelResolving {
        let viewModel: AccountRowButtonViewModel

        func resolve(accountModel: any CryptoAccountModel) {
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

        /// TangemPay accounts don't have token count or fiat balance data for subtitle
        func resolve(accountModel: any TangemPayAccountModel) {}

        func resolve(accountModel: any PolymarketAccountModel) {
            Publishers.CombineLatest(
                accountModel.statePublisher,
                accountModel.fiatTotalTokenBalanceProvider.formattedBalanceTypePublisher
            )
            .receiveOnMain()
            .withWeakCaptureOf(viewModel)
            .sink { vm, tuple in
                let (accountState, balanceType) = tuple
                let needsReconnect = accountState == .syncNeeded

                vm.isBalanceUnavailable = needsReconnect
                vm.trailingBalanceState = Self.polymarketBalanceState(type: balanceType, needsReconnect: needsReconnect)
                vm.updateSubtitleState(
                    // [REDACTED_TODO_COMMENT]
                    description: needsReconnect ? "Reconnect required" : Localization.predictionAccountOpenDetailedView,
                    balanceState: .empty
                )
            }
            .store(in: &viewModel.bag)
        }

        func resolve(accountModel: any CollectiblesAccountModel) {
            accountModel
                .fiatTotalTokenBalanceProvider
                .formattedBalanceTypePublisher
                .map { LoadableBalanceViewStateBuilder().build(type: $0) }
                .receiveOnMain()
                .withWeakCaptureOf(viewModel)
                .sink { vm, balanceState in
                    vm.trailingBalanceState = balanceState
                }
                .store(in: &viewModel.bag)
        }

        private static func polymarketBalanceState(
            type: FormattedTokenBalanceType,
            needsReconnect: Bool
        ) -> LoadableBalanceView.State? {
            guard !needsReconnect else { return nil }

            let state = LoadableBalanceViewStateBuilder().build(type: type, icon: .leading)

            guard case .failed(let text, _) = state else { return state }

            return .failed(cached: text, icon: .leading)
        }
    }
}
