//
//  JointAccountMembersViewSlotViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

final class JointAccountMembersViewSlotViewModel: ObservableObject, Identifiable {
    let id: ID

    @Published private(set) var content: Content

    private let accountName: String
    private weak var routable: JointAccountMembersViewSlotRoutable?

    init(id: ID, content: Content, accountName: String, routable: JointAccountMembersViewSlotRoutable?) {
        self.id = id
        self.content = content
        self.accountName = accountName
        self.routable = routable
    }

    var isTappable: Bool {
        content.tapAction != nil
    }

    func update(content: Content) {
        guard self.content != content else {
            return
        }

        self.content = content
    }

    func onTap() {
        switch content.tapAction {
        case .memberDetails(let name, let address, let accentColor):
            routable?.openMemberDetails(name: name, address: address, accentColor: accentColor)
        case nil:
            break
        }
    }

    func onInviteTap() {
        switch content.accessory {
        case .invite(let url):
            routable?.shareInvite(url: url, accountName: accountName)
        case .empty:
            break
        }
    }
}

// MARK: - Auxiliary types

extension JointAccountMembersViewSlotViewModel {
    enum ID: Hashable {
        case member(address: String)
        case freeSlot(index: Int)
    }

    struct Content: Equatable {
        let avatar: Avatar
        let title: String
        let subtitle: String
        let status: Status?
        let accessory: Accessory
        let tapAction: TapAction?
    }

    enum Avatar: Equatable {
        case member(AddressBookContactNameIconViewData)
        case vacant
    }

    enum Status: Equatable {
        case joined
        case notConfirmed
    }

    enum Accessory: Equatable {
        case empty
        case invite(url: URL)
    }

    enum TapAction: Equatable {
        case memberDetails(name: String, address: String, accentColor: Color)
    }
}
