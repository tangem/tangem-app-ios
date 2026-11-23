//
//  JointAccountMembersViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import CombineExt
import Foundation
import SwiftUI
import TangemAccounts
import TangemAssets
import TangemFoundation
import TangemLocalization
import TangemUI

final class JointAccountMembersViewModel: ObservableObject {
    @Published private(set) var phase: JointAccountMembersPhase?
    @Published private(set) var slots: [JointAccountMembersViewSlotViewModel] = []

    var title: Title? { makeTitle() }
    var summary: Summary? { makeSummary() }
    var footer: Footer? { makeFooter() }
    var actions: [Action] { makeActions() }

    private let userWalletConfig: UserWalletConfig
    private let jointAccount: any JointAccountModel
    private let dateProvider: DateProvider
    private let expiryFormatter: JointAccountInviteExpiryFormatter
    private weak var coordinator: JointAccountMembersRoutable?

    private var frequentUpdatesSubscription: AnyCancellable?
    private var bag = Set<AnyCancellable>()

    init(
        userWalletConfig: UserWalletConfig,
        jointAccount: any JointAccountModel,
        dateProvider: DateProvider = SystemDateProvider(),
        expiryFormatter: JointAccountInviteExpiryFormatter = JointAccountInviteExpiryFormatter(),
        coordinator: JointAccountMembersRoutable,
    ) {
        self.userWalletConfig = userWalletConfig
        self.jointAccount = jointAccount
        self.dateProvider = dateProvider
        self.expiryFormatter = expiryFormatter
        self.coordinator = coordinator

        bind()
    }

    func onWillAppear() {
        frequentUpdatesSubscription = jointAccount.jointAccountMembersService.requestFrequentUpdates()
    }

    func onWillDisappear() {
        frequentUpdatesSubscription = nil
    }

    func onApprovalsInfoTap() {
        coordinator?.openAboutSignatures(policy: jointAccount.policy)
    }

    @MainActor
    func onActionTap(_ action: Action) {
        switch action {
        case .confirmSharedAddress:
            coordinator?.openConfirmSharedAddress(jointAccount: jointAccount, userWalletConfig: userWalletConfig)
        }
    }

    func onCloseTap() {
        coordinator?.closeMembers()
    }
}

// MARK: - JointAccountMembersViewSlotViewModelDelegate

extension JointAccountMembersViewModel: JointAccountMembersViewSlotViewModelDelegate {
    func jointAccountMembersViewSlotViewModelDidTap(_ viewModel: JointAccountMembersViewSlotViewModel) {
        guard case .member(let member, _) = viewModel.slot, case .member(let icon) = viewModel.icon else {
            return
        }

        coordinator?.openMemberDetails(name: member.name, address: member.address, accentColor: icon.color)
    }

    func jointAccountMembersViewSlotViewModelDidTapInvite(_ viewModel: JointAccountMembersViewSlotViewModel) async {
        guard case .empty(let slot, _) = viewModel.slot else {
            return
        }

        await issue(slot: slot)
    }
}

// MARK: - Private

private extension JointAccountMembersViewModel {
    func bind() {
        let slotsPublisher = jointAccount.jointAccountMembersService.slotsPublisher
            .removeDuplicates()
            .share(replay: 1)

        Publishers
            .CombineLatest(
                jointAccount.didChangePublisher.prepend(()),
                slotsPublisher
            )
            .map { $1 }
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { $0.updatePhase(slots: $1) }
            .store(in: &bag)

        slotsPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { $0.updateSlots($1) }
            .store(in: &bag)
    }

    func updatePhase(slots: [JointAccountSlot]) {
        let phase = makePhase(slots: slots)

        switch (self.phase, phase) {
        case (.none, _):
            self.phase = phase
        case (.some(let current), _) where current == phase:
            break
        case (.some, .completed) where jointAccount.jointAccountStatusProvider.status.isActive:
            closeActivatedAccount()
        case (.some(let current), _) where current.rawCaseValue == phase.rawCaseValue:
            withAnimation(JointAccountMembersMotion.member) { self.phase = phase }
        case (.some, _):
            withAnimation(JointAccountMembersMotion.phase) { self.phase = phase }
        }
    }

    func updateSlots(_ accountSlots: [JointAccountSlot]) {
        let slotViewModels = makeSlots(accountSlots)

        guard slots.isNotEmpty else {
            slots = slotViewModels
            return
        }

        withAnimation(JointAccountMembersMotion.member) {
            self.slots = slotViewModels
        }
    }

    func closeActivatedAccount() {
        bag.removeAll()

        let snackbar = TangemSnackbar(title: Localization.jointAccountActivatedSnackbar)
            .icon(DesignSystem.Icons.Success.regular20)
            .iconColor(DesignSystem.Color.iconAccentBlue)
        LegacyToast(view: snackbar).present(layout: .top(padding: Constants.toastTopPadding), type: .temporary())

        coordinator?.closedActivatedAccount()
    }

    func makePhase(slots: [JointAccountSlot]) -> JointAccountMembersPhase {
        JointAccountMembersPhase(
            status: jointAccount.jointAccountStatusProvider.status,
            slots: slots,
            isCreator: jointAccount.jointAccountUserRoleService.isCreator ?? false,
            now: dateProvider.now
        )
    }

    func makeSlots(_ slots: [JointAccountSlot]) -> [JointAccountMembersViewSlotViewModel] {
        slots.enumerated().map { index, slot in
            JointAccountMembersViewSlotViewModel(
                slot: slot,
                index: index,
                expiryFormatter: expiryFormatter,
                delegate: self
            )
        }
    }

    func makeTitle() -> Title? {
        switch phase {
        case .collecting(_, isCreator: true):
            .header(text: Localization.jointAccountInviteMembersTitle, subtitle: nil)
        case .collecting(_, isCreator: false):
            .header(text: Localization.jointAccountInviteMembersWaitingTitle, subtitle: nil)
        case .confirming:
            .header(
                text: Localization.jointAccountConfirmAccountTitle,
                subtitle: Localization.jointAccountConfirmAccountSubtitle
            )
        case .completed:
            .navigationBar(text: Localization.jointAccountMembersTitle)
        case .none:
            nil
        }
    }

    func makeSummary() -> Summary? {
        switch phase {
        case .collecting, .confirming: Summary(jointAccount: jointAccount)
        case .completed, .none: nil
        }
    }

    func makeFooter() -> Footer? {
        switch phase {
        case .collecting(.everyoneJoined, _): .everyoneJoined
        case .collecting(.awaitingMembers(let count), _): .awaitingMembers(count: count)
        case .collecting(.notInvited(let count), _): .notInvited(count: count)
        case .collecting(.moreNotInvited(let count), _): .moreNotInvited(count: count)
        case .confirming, .completed, .none: nil
        }
    }

    func makeActions() -> [Action] {
        switch phase {
        case .collecting: [.confirmSharedAddress(isEnabled: false)]
        case .confirming(let canConfirm, _): canConfirm ? [.confirmSharedAddress(isEnabled: true)] : []
        case .completed, .none: []
        }
    }
}

// MARK: - Actions

private extension JointAccountMembersViewModel {
    @MainActor
    func issue(slot: JointAccountMemberSlotID) async {
        do throws(JointAccountInviteIssueError) {
            let invite = try await jointAccount.jointAccountMembersService.issueInvite(slot: slot)
            coordinator?.openShareInviteMember(url: invite.url, accountName: jointAccount.name)
        } catch .slotUnavailable {
            JointAccountsLogger.warning("The slot \(slot.rawValue) of the joint account no longer takes an invite")
        } catch {
            JointAccountsLogger.error("Failed to issue an invite of the joint account", error: error)
            coordinator?.showInviteIssueError(error)
        }
    }
}

// MARK: - Auxiliary types

extension JointAccountMembersViewModel {
    enum Title: Hashable {
        case header(text: String, subtitle: String?)
        case navigationBar(text: String)
    }

    enum Footer: Equatable {
        case everyoneJoined
        case awaitingMembers(count: Int)
        case notInvited(count: Int)
        case moreNotInvited(count: Int)

        var text: String {
            switch self {
            case .everyoneJoined: Localization.jointAccountInviteMembersEveryoneJoined
            case .awaitingMembers(let count): Localization.jointAccountInviteMembersAwaitingToJoin(count)
            case .notInvited(let count): Localization.jointAccountInviteMembersInviteCount(count)
            case .moreNotInvited(let count): Localization.jointAccountInviteMembersInviteMore(count)
            }
        }

        var sentence: Sentence {
            switch self {
            case .everyoneJoined: .everyoneJoined
            case .awaitingMembers: .awaitingMembers
            case .notInvited: .notInvited
            case .moreNotInvited: .moreNotInvited
            }
        }

        enum Sentence {
            case everyoneJoined
            case awaitingMembers
            case notInvited
            case moreNotInvited
        }
    }

    enum Action: Hashable {
        case confirmSharedAddress(isEnabled: Bool)
    }

    struct Summary {
        let iconViewData: AccountIconView.ViewData
        let name: String
        let membersCount: String
        let requiredApprovals: String
    }
}

// MARK: - Constants

private extension JointAccountMembersViewModel {
    enum Constants {
        static let toastTopPadding: CGFloat = 14
    }
}

private extension JointAccountMembersViewModel.Summary {
    init(jointAccount: any JointAccountModel) {
        let policy = jointAccount.policy
        let iconViewData = AccountModelUtils.UI.iconViewData(accountModel: jointAccount)
        let membersCount = Localization.jointAccountMembersCount(policy.membersCount)
        let requiredApprovals = Localization.jointAccountInviteMembersApprovalsValue(policy.signersCount, policy.membersCount)

        self.init(iconViewData: iconViewData, name: jointAccount.name, membersCount: membersCount, requiredApprovals: requiredApprovals)
    }
}
