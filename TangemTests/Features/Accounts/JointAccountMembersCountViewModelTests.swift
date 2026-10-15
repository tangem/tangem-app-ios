//
//  JointAccountMembersCountViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

// MARK: - Tests

@Suite("Tests for the composition chosen on the members step of the joint account creation")
struct JointAccountMembersCountViewModelTests {
    @Test("The step opens on the smallest composition, every member signing")
    func firstOpenStartsFromTheSmallestComposition() {
        let viewModel = JointAccountMembersCountViewModel(creationHelper: makeHelper(), coordinator: nil)

        #expect(viewModel.membersCount == viewModel.membersCountRange.lowerBound)
        #expect(viewModel.signersCount == viewModel.membersCountRange.lowerBound)
    }

    @Test("Fewer members lower the signatures required, and the lowered pair is what the flow keeps")
    func fewerMembersLowerTheThreshold() {
        let helper = makeHelper()
        let viewModel = JointAccountMembersCountViewModel(creationHelper: helper, coordinator: nil)
        viewModel.membersCount = 4
        viewModel.signersCount = 4

        viewModel.membersCount = 3

        #expect(viewModel.signersCount == 3)
        #expect(helper.membersCount == 3)
        #expect(helper.signersCount == 3)
    }

    @Test("A new visit to the step opens the composition chosen before Back")
    func returningKeepsTheChosenComposition() {
        let helper = makeHelper()
        let firstVisit = JointAccountMembersCountViewModel(creationHelper: helper, coordinator: nil)
        firstVisit.membersCount = 3
        firstVisit.signersCount = 1

        let secondVisit = JointAccountMembersCountViewModel(creationHelper: helper, coordinator: nil)

        #expect(secondVisit.membersCount == 3)
        #expect(secondVisit.signersCount == 1)
    }
}

// MARK: - Helpers

private extension JointAccountMembersCountViewModelTests {
    func makeHelper() -> JointAccountCreationHelper {
        JointAccountCreationHelper(userWalletModel: UserWalletModelMock())
    }
}
