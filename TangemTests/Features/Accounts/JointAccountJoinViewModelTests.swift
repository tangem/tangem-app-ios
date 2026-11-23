//
//  JointAccountJoinViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Testing
import TangemLocalization
@testable import Tangem

// MARK: - Tests

@MainActor
@Suite("Join screen of a joint account invite", .timeLimit(.minutes(1)))
struct JointAccountJoinViewModelTests {
    @Test(
        "The invite's composition fills the Members and Required approvals rows",
        arguments: [(membersCount: 2, threshold: 1), (membersCount: 5, threshold: 2), (membersCount: 3, threshold: 3)]
    )
    func compositionFillsRows(membersCount: Int, threshold: Int) async throws {
        let content = try await withLoadedContent(of: makePreview(membersCount: membersCount, threshold: threshold)) { _, content in
            content
        }

        #expect(content.membersCount == Localization.accountDetailsJointMembersCount(membersCount))
        #expect(content.requiredApprovals == Localization.jointAccountInviteMembersApprovalsValue(threshold, membersCount))
    }

    @Test("Tapping Required approvals explains the signatures of the invite's composition")
    func requiredApprovalsTapOpensAboutSignatures() async throws {
        let routable = JointAccountJoinRoutableSpy()

        try await withLoadedContent(of: makePreview(membersCount: 5, threshold: 2), routable: routable) { viewModel, content in
            viewModel.onRequiredApprovalsTap(content)
        }

        #expect(routable.openedAboutSignaturesPolicies == [JointAccountPolicy(membersCount: 5, signersCount: 2)])
    }
}

// MARK: - Helpers

private extension JointAccountJoinViewModelTests {
    func makePreview(membersCount: Int, threshold: Int) -> JointAccountInvitePreview {
        JointAccountInvitePreview(
            config: JointAccountSignedConfig(
                name: "Family savings",
                icon: AccountModel.CompositeIcon.Name.safe.rawValue,
                iconColor: CompositeIconColor.candyGrapeFizz.rawValue,
                membersCount: membersCount,
                threshold: threshold
            ),
            creator: JointAccountInvitePreview.Creator(
                name: "Isaac",
                address: "0xBef7B36845000000000000ac4e6752A9cE000000"
            )
        )
    }

    @discardableResult
    func withLoadedContent<T>(
        of preview: JointAccountInvitePreview,
        routable: JointAccountJoinRoutable? = nil,
        _ body: (JointAccountJoinViewModel, JointAccountJoinViewModel.Content) throws -> T
    ) async throws -> T {
        let userWalletModels = [ConfiguredUserWalletModelStub.card()]

        return try await InjectedDependenciesIsolation.shared.run {
            let previousRepository = InjectedValues[\.userWalletRepository]
            InjectedValues[\.userWalletRepository] = FakeUserWalletRepository(models: userWalletModels)
            defer { InjectedValues[\.userWalletRepository] = previousRepository }

            let viewModel = JointAccountJoinViewModel(
                inviteId: "invite-id",
                networkService: JointAccountsNetworkServiceStub(invitePreview: preview),
                userWalletModels: userWalletModels,
                coordinator: routable
            )

            for await state in viewModel.$state.values {
                if case .loaded(let content) = state {
                    return try body(viewModel, content)
                }
            }

            throw "The invite never loaded"
        }
    }
}

// MARK: - Stubs

private final class JointAccountJoinRoutableSpy: JointAccountJoinRoutable {
    private(set) var openedAboutSignaturesPolicies: [JointAccountPolicy] = []

    func openAboutSignatures(policy: JointAccountPolicy) {
        openedAboutSignaturesPolicies.append(policy)
    }

    func closeJoin() {}

    func openCreatorDetails(name: String, address: String, accentColor: Color) {}

    func openWalletSelection(accountSelectorViewModel: AccountSelectorViewModel) {}

    func closeWalletSelection() {}

    func continueJoin(userWalletModel: any UserWalletModel, preview: JointAccountInvitePreview) {}
}
