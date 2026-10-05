//
//  JointAccountMemberNameViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import Tangem

@Suite("Tests for the member name step of the joint account flows")
struct JointAccountMemberNameViewModelTests {
    @Test("A name typed on the creation step is there again when the step is returned to")
    func creationStepKeepsTheTypedName() {
        let creationHelper = JointAccountCreationHelper(userWalletModel: UserWalletModelMock())
        let helper = JointAccountCreationMemberNameHelper(creationHelper: creationHelper, routable: nil)

        let firstVisit = JointAccountMemberNameViewModel(helper: helper, coordinator: nil)
        firstVisit.name = "Bob"

        let secondVisit = JointAccountMemberNameViewModel(helper: helper, coordinator: nil)

        #expect(secondVisit.name == "Bob")
        #expect(!secondVisit.submitButtonDisabled)
    }
}
