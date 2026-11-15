//
//  PendingJointAccountItemViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemAccounts
import TangemFoundation
import TangemLocalization
import TangemUI

final class PendingJointAccountItemViewModel: Identifiable, ObservableObject {
    /// Keyed by the account rather than by the object, so that a plate rebuilt from a fresh model reads as the same
    /// row to SwiftUI instead of one row replacing another.
    var id: CryptoAccountModelId { jointAccount.id }

    // MARK: - View State

    @Published private(set) var name: String
    @Published private(set) var iconData: AccountIconView.ViewData
    @Published private(set) var balance: String

    @Published private(set) var phase: JointAccountMembersPhase?

    var action: Action? { makeAction() }

    let status: String
    let priceChange: PriceChangeView.State

    // MARK: - Private properties

    private let jointAccount: any JointAccountModel
    private let onTap: () -> Void
    private let dateProvider: DateProvider

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(
        jointAccount: any JointAccountModel,
        onTap: @escaping () -> Void,
        dateProvider: DateProvider = SystemDateProvider()
    ) {
        self.jointAccount = jointAccount
        self.onTap = onTap
        self.dateProvider = dateProvider

        name = jointAccount.name
        iconData = AccountModelUtils.UI.iconViewData(accountModel: jointAccount)
        status = Localization.jointAccountMembersCount(jointAccount.policy.membersCount)
        balance = BalanceFormatter().formatFiatBalance(.zero, currencyCode: AppSettings.shared.selectedCurrencyCode)
        priceChange = PriceChangeUtility().convertToPriceChangeState(changePercent: .zero)

        bind()
    }

    // MARK: - Public

    func onSelect() {
        onTap()
    }

    // MARK: - Private methods

    private func bind() {
        // The composition is followed apart from the account, whose own changes say nothing of who joined, and the
        // rows are counted off what it hands out rather than read back off the service
        Publishers.CombineLatest(
            // Prepended because the account reports changes rather than state: without a value of its own the
            // combination would wait for one, and the plate would not be counted until the account moved
            jointAccount.didChangePublisher.prepend(()),
            jointAccount.jointAccountMembersService.slotsPublisher
        )
        .map { $1 }
        .receiveOnMain()
        .withWeakCaptureOf(self)
        .sink { viewModel, slots in
            viewModel.onAccountModelDidChange(slots: slots)
        }
        .store(in: &bag)

        AppSettings.shared.$selectedCurrencyCode
            .removeDuplicates()
            .receiveOnMain()
            .map { BalanceFormatter().formatFiatBalance(.zero, currencyCode: $0) }
            .assign(to: &$balance)
    }

    private func onAccountModelDidChange(slots: [JointAccountSlot]) {
        name = jointAccount.name
        iconData = AccountModelUtils.UI.iconViewData(accountModel: jointAccount)
        phase = makePhase(slots: slots)
    }

    private func makePhase(slots: [JointAccountSlot]) -> JointAccountMembersPhase {
        JointAccountMembersPhase(
            status: jointAccount.jointAccountStatusProvider.status,
            slots: slots,
            isCreator: jointAccount.isCreator,
            now: dateProvider.now
        )
    }

    private func makeAction() -> Action? {
        switch phase {
        case .collecting(.notInvited, _), .collecting(.moreNotInvited, _):
            .invite
        case .collecting(.awaitingMembers(let count), _):
            .waitingForMembers(count: count)
        case .confirming(canConfirm: true, _):
            .confirm
        case .confirming(canConfirm: false, let unconfirmedCount) where unconfirmedCount > 0:
            .waitingForConfirmations(count: unconfirmedCount)
        case .collecting(.everyoneJoined, _), .confirming, .completed, .none:
            nil
        }
    }
}

// MARK: - Auxiliary types

private extension JointAccountModel {
    var isCreator: Bool { jointAccountUserRoleService.isCreator ?? false }
}

// MARK: - Auxiliary types

extension PendingJointAccountItemViewModel {
    enum Action: Equatable {
        case invite
        case confirm
        case waitingForMembers(count: Int)
        case waitingForConfirmations(count: Int)
    }
}
