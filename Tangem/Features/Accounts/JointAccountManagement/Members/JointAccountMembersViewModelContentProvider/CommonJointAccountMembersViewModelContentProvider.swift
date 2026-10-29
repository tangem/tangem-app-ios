//
//  CommonJointAccountMembersViewModelContentProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemLocalization

final class CommonJointAccountMembersViewModelContentProvider {
    private let jointAccount: any JointAccountModel
    private weak var routable: JointAccountMembersViewSlotRoutable?

    private let contentSubject = CurrentValueSubject<Content?, Never>(nil)
    private var slotViewModels: [JointAccountMembersViewSlotViewModel.ID: JointAccountMembersViewSlotViewModel] = [:]
    private var bag = Set<AnyCancellable>()

    init(jointAccount: any JointAccountModel, routable: JointAccountMembersViewSlotRoutable) {
        self.jointAccount = jointAccount
        self.routable = routable

        contentSubject.send(makeContent(slots: jointAccount.jointAccountMembersService.slots))
        bind()
    }
}

// MARK: - JointAccountMembersViewModelContentProvider

extension CommonJointAccountMembersViewModelContentProvider: JointAccountMembersViewModelContentProvider {
    var titlePublisher: AnyPublisher<JointAccountMembersViewModel.Title, Never> {
        contentSubject
            .compactMap { $0?.title }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var slotsPublisher: AnyPublisher<[JointAccountMembersViewSlotViewModel], Never> {
        contentSubject
            .compactMap { $0?.slots }
            .eraseToAnyPublisher()
    }

    var footerPublisher: AnyPublisher<String?, Never> {
        contentSubject
            .compactMap { $0 }
            .map(\.footer)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var actionsPublisher: AnyPublisher<[JointAccountMembersViewModel.Action], Never> {
        contentSubject
            .compactMap { $0?.actions }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension CommonJointAccountMembersViewModelContentProvider {
    func bind() {
        Publishers
            .CombineLatest(
                jointAccount.didChangePublisher.prepend(()),
                jointAccount.jointAccountMembersService.slotsPublisher
            )
            .map { _, slots in slots }
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { provider, slots in
                provider.contentSubject.send(provider.makeContent(slots: slots))
            }
            .store(in: &bag)
    }

    func makeContent(slots: [JointAccountSlot]) -> Content {
        let phase = Phase(status: jointAccount.status)
        let userRole = jointAccount.jointAccountMembersService.userRole

        return Content(
            title: title(phase: phase, isCreator: userRole.isCreator),
            slots: slotViewModels(of: slots, phase: phase, userRole: userRole),
            footer: footer(phase: phase, isCreator: userRole.isCreator, slots: slots),
            actions: actions(phase: phase)
        )
    }

    func title(phase: Phase, isCreator: Bool) -> JointAccountMembersViewModel.Title {
        switch phase {
        case .collecting where isCreator:
            .header(text: Localization.jointAccountInviteMembersTitle, subtitle: nil)
        case .collecting:
            .header(text: Localization.jointAccountInviteMembersWaitingTitle, subtitle: nil)
        case .confirming:
            .header(text: Localization.jointAccountConfirmAccountTitle, subtitle: Localization.jointAccountConfirmAccountSubtitle)
        case .completed:
            .navigationBar(text: Localization.jointAccountMembersTitle)
        }
    }

    func footer(phase: Phase, isCreator: Bool, slots: [JointAccountSlot]) -> String? {
        guard phase == .collecting else {
            return nil
        }

        let freeSlotsCount = slots.filter { $0.member == nil }.count

        guard freeSlotsCount > 0 else {
            return Localization.jointAccountInviteMembersEveryoneJoined
        }

        guard isCreator else {
            return Localization.jointAccountInviteMembersAwaitingToJoin(freeSlotsCount)
        }

        guard slots.members.count > 1 else {
            return Localization.jointAccountInviteMembersInviteCount(freeSlotsCount)
        }

        return Localization.jointAccountInviteMembersInviteMore(freeSlotsCount)
    }

    func actions(phase: Phase) -> [JointAccountMembersViewModel.Action] {
        switch phase {
        case .collecting:
            [.confirmSharedAddress(isEnabled: false)]
        case .confirming where jointAccount.canActivate:
            [.confirmSharedAddress(isEnabled: true)]
        case .confirming, .completed:
            []
        }
    }
}

// MARK: - Slots

private extension CommonJointAccountMembersViewModelContentProvider {
    func slotViewModels(
        of slots: [JointAccountSlot],
        phase: Phase,
        userRole: JointAccountUserRole
    ) -> [JointAccountMembersViewSlotViewModel] {
        let viewModels = slots.enumerated().map { index, slot in
            slotViewModel(
                id: slotId(of: slot, at: index),
                content: slotContent(of: slot, at: index, phase: phase, userRole: userRole)
            )
        }

        slotViewModels = Dictionary(viewModels.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        return viewModels
    }

    func slotViewModel(
        id: JointAccountMembersViewSlotViewModel.ID,
        content: JointAccountMembersViewSlotViewModel.Content
    ) -> JointAccountMembersViewSlotViewModel {
        if let viewModel = slotViewModels[id] {
            viewModel.update(content: content)
            return viewModel
        }

        return JointAccountMembersViewSlotViewModel(
            id: id,
            content: content,
            accountName: jointAccount.name,
            routable: routable
        )
    }

    func slotId(of slot: JointAccountSlot, at index: Int) -> JointAccountMembersViewSlotViewModel.ID {
        switch slot {
        case .member(let member):
            .member(address: member.address.lowercased())
        case .empty:
            .freeSlot(index: index)
        }
    }

    func slotContent(
        of slot: JointAccountSlot,
        at index: Int,
        phase: Phase,
        userRole: JointAccountUserRole
    ) -> JointAccountMembersViewSlotViewModel.Content {
        switch slot {
        case .member(let member):
            // [REDACTED_TODO_COMMENT]
            let icon = AddressBookContactNameIconViewData(
                letter: member.name.prefix(1).uppercased(),
                color: CompositeIconColorPalette.color(for: .jointAccountMember(at: index))
            )
            let isOwn = userRole.member?.address.caseInsensitiveEquals(to: member.address) ?? false

            return JointAccountMembersViewSlotViewModel.Content(
                avatar: .member(icon),
                title: member.name,
                subtitle: role(of: member, isOwn: isOwn),
                status: memberStatus(phase: phase),
                accessory: .empty,
                tapAction: .memberDetails(name: member.name, address: member.address, accentColor: icon.color)
            )

        case .empty(let invite):
            return JointAccountMembersViewSlotViewModel.Content(
                avatar: .vacant,
                title: Localization.jointAccountInviteMembersMember,
                subtitle: userRole.isCreator
                    ? Localization.jointAccountInviteMembersNotInvited
                    : Localization.jointAccountInviteMembersWaitingToJoin,
                status: nil,
                accessory: freeSlotAccessory(invite: invite, isCreator: userRole.isCreator),
                tapAction: nil
            )
        }
    }

    func role(of member: JointAccountMember, isOwn: Bool) -> String {
        let role = switch member.role {
        case .creator: Localization.jointAccountInviteMembersCreator
        case .member: Localization.jointAccountInviteMembersMember
        }

        guard isOwn else {
            return role
        }

        return "\(role) \(AppConstants.dotSign) \(Localization.jointAccountMembersRoleYou)"
    }

    func memberStatus(phase: Phase) -> JointAccountMembersViewSlotViewModel.Status? {
        switch phase {
        case .collecting: .joined
        case .confirming: .notConfirmed
        case .completed: nil
        }
    }

    func freeSlotAccessory(invite: JointAccountInvite?, isCreator: Bool) -> JointAccountMembersViewSlotViewModel.Accessory {
        guard isCreator, let invite else {
            return .empty
        }

        return .invite(url: invite.url)
    }
}

// MARK: - Auxiliary types

private extension CommonJointAccountMembersViewModelContentProvider {
    enum Phase {
        case collecting
        case confirming
        case completed

        init(status: JointAccountStatus) {
            switch status {
            case .pending: self = .collecting
            case .confirming: self = .confirming
            case .active, .cancelled, .unknown: self = .completed
            }
        }
    }

    struct Content {
        let title: JointAccountMembersViewModel.Title
        let slots: [JointAccountMembersViewSlotViewModel]
        let footer: String?
        let actions: [JointAccountMembersViewModel.Action]
    }
}
