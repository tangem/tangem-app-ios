//
//  AccountModelUtilsTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemAccounts
import TangemFoundation
import TangemSdk
@testable import Tangem

/// https://github.com/tangem-developments/tangem-app-android/blob/develop/domain/models/src/test/kotlin/com/tangem/domain/models/account/CryptoPortfolioIconTest.kt
struct AccountModelUtilsTests {
    @Test(
        "Icon generation for main account based on UserWalletId",
        arguments: [
            ("1234567890abcdef", AccountModel.Icon.Color.pattypan),
            ("27163F47405CE73110837F24DF82607FF11C7AF9D78C93F409E4FEAFF3400C8F", AccountModel.Icon.Color.candyGrapeFizz),
            ("64A3791C180584C700EBECD6EAB36CBC34643BB449BC87761104C09F41DBCF3D", AccountModel.Icon.Color.palatinateBlue),
            ("01C061A99FCCEDA87933267EBAB3513592F83AD2E27BDA6EE5546BA96009D21F", AccountModel.Icon.Color.pelati),
            ("6D387A8FA5D2AF95F601EBCA8736D73D2ED53159835D8C407FBD4BBB10290C8B", AccountModel.Icon.Color.caribbeanBlue),
            ("33FCD9B9982C31648C235AE55A29212D567ECD3BA24BE4227D1A01897ADBC959", AccountModel.Icon.Color.sweetDesire),
            ("197C8C5AA59270F3E9E1F30799A007D193DA596E6DC24C37D002C2EC203C2A0B", AccountModel.Icon.Color.vitalGreen),
            ("ACF90C18393828958B5E795771F0692A00D3D7ADC092F726AB4A7E3116DD6E6E", AccountModel.Icon.Color.pattypan),
        ]
    )
    func testMainAccountIconGeneration(hexString: String, expectedColor: AccountModel.Icon.Color) {
        let expectedName: AccountModel.Icon.Name = .star
        let rawUserWalletId = Data(hexString: hexString)
        let userWalletId = UserWalletId(value: rawUserWalletId)
        let persistentConfig = AccountModelUtils.mainAccountPersistentConfig(forUserWalletWithId: userWalletId)

        #expect(persistentConfig.iconColor == expectedColor.rawValue)
        #expect(persistentConfig.iconName == expectedName.rawValue)
    }

    @Test("Icon generation for new accounts")
    func testNewAccountIconGeneration() {
        // Many iterations to ensure random distribution without some blacklisted icon names (letter, star and so on)
        for _ in 0 ..< 500 {
            let newAccountIcon = AccountModelUtils.UI.newAccountIcon()
            #expect(newAccountIcon.name != .letter)
            #expect(newAccountIcon.name != .star)
        }
    }
}
