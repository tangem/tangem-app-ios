//
//  JointAccountModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("Tests for what a joint account model says about itself")
struct JointAccountModelTests {
    /// Kept by the suite because the models hold it weakly, and a new one is made per test the way every stored
    /// property of a suite is.
    private let delegate = JointAccountModelDelegateMock()

    @Test("Activating is offered to the creator of a full composition and to no one else")
    func activatingTakesTheStageAndTheCreator() {
        let creator = makeSUT(status: .confirming(safeAddress: Self.safeAddress), userRole: .member(Self.creatorMember))
        // The slot this wallet holds is what tells a member apart from the creator
        let member = makeSUT(status: .confirming(safeAddress: Self.safeAddress), userRole: .member(Self.memberMember))
        let stillFilling = makeSUT(status: .pending, userRole: .member(Self.creatorMember))

        #expect(creator.canActivate)
        #expect(!member.canActivate)
        #expect(!stillFilling.canActivate)
    }

    /// The button stays: the address is the backend's to name, and hiding the only action the screen has would leave
    /// the creator with nothing and no reason why.
    @Test("An announced address the answer left out does not take the activate button with it")
    func activatingIsOfferedWithoutAnAnnouncedAddress() {
        let sut = makeSUT(status: .confirming(safeAddress: nil), userRole: .member(Self.creatorMember))

        #expect(sut.canActivate)
    }

    @Test("A wallet that still needs the derivation to tell which slot it holds is offered nothing")
    func activatingIsNotOfferedWhileDerivationIsNeeded() {
        let sut = makeSUT(status: .confirming(safeAddress: Self.safeAddress), userRole: .derivationNeeded)

        #expect(!sut.canActivate)
    }

    @Test("A wallet that holds no slot of the account is not offered it")
    func activatingIsNotOfferedToAnOutsider() {
        let sut = makeSUT(status: .confirming(safeAddress: Self.safeAddress), userRole: .outsider)

        #expect(!sut.canActivate)
    }
}

// MARK: - Helpers

private extension JointAccountModelTests {
    static let safeAddress = "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"
    static let creatorMember = JointAccountMember(name: "Isaac", address: "0xcreator", role: .creator)
    static let memberMember = JointAccountMember(name: "Bob", address: "0xmember", role: .member(inviteId: nil))

    func makeSUT(status: JointAccountStatus, userRole: JointAccountUserRole) -> CommonJointAccountModel {
        CommonJointAccountModel(
            cryptoAccount: CryptoAccountModelMock(isMainAccount: false, onArchive: { _ in }),
            derivationIdentity: CryptoAccountDerivationIdentity(derivationIndex: 1, type: .joint),
            accountPolicy: JointAccountPolicy(membersCount: 3, signersCount: 2),
            accountStatus: status,
            operationsService: JointAccountOperationsServiceMock(),
            pendingOperationsProvider: JointAccountPendingOperationsProviderMock(),
            membersService: JointAccountMembersServiceMock(userRole: userRole),
            delegate: delegate
        )
    }
}
