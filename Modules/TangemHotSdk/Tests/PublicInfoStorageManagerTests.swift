//
//  PublicInfoStorageManagerTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemHotSdk
@testable import TangemFoundation

struct PublicInfoStorageManagerTests {
    private let walletID = UserWalletId(value: Data(hexString: "test"))

    private func makeStorage() -> PublicInfoStorageManager {
        let mockedSecureStorage = MockedSecureStorage()
        let mockedSecureEnclaveService = MockedSecureEnclaveService()

        return PublicInfoStorageManager(
            encryptedSecureStorage: EncryptedSecureStorage(
                secureStorage: mockedSecureStorage,
                secureEnclaveService: mockedSecureEnclaveService
            )
        )
    }

    @Test
    func testDataMatch() throws {
        let storage = makeStorage()

        let hex = "2bcc5b06b2d68c79726b856104e0fc828222dcd940d3157fa7a79def3cbb8db4"

        try storage.storeData(
            Data(
                hexString: hex
            ),
            walletID: walletID,
            accessCode: nil
        )

        let data = try storage.data(for: walletID, accessCode: nil)

        #expect(data.hexString == hex.uppercased(), "Stored data should match the original data")
    }
}
