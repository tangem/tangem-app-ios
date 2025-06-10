//
//  DucatusAddressTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

@testable import BlockchainSdk
import TangemSdk
import Testing

struct DucatusAddressTests {
    @Test
    func ducatusAddressValidation() {
        let service = AddressServiceFactory(blockchain: .ducatus).makeAddressService()
        #expect(service.validate("LokyqymHydUE3ZC1hnZeZo6nuART3VcsSU"))
    }
}
