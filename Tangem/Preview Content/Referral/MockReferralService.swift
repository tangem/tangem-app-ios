//
//  MockReferralService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class MockReferralService: ReferralService {
    let decoder = JSONDecoder()

    private let isAlreadyReferralResourceName = "referralMock"
    private let isNotReferralResourceName = "notReferralMock"

    private let isReferral: Bool

    init(isReferral: Bool) {
        self.isReferral = isReferral
    }

    func loadReferralProgramInfo() async throws -> ReferralProgramInfo {
        try await Task.sleep(seconds: 3)
        guard let url = Bundle.main.url(forResource: isReferral ? isAlreadyReferralResourceName : isNotReferralResourceName, withExtension: "json") else {
            throw "Everything is corrupted!!!!!"
        }
        let data = try Data(contentsOf: url)
        return try decoder.decode(ReferralProgramInfo.self, from: data)
    }

    func participateInReferralProgram(using token: ReferralProgramInfo.Conditions.Token, with address: String) async throws -> ReferralProgramInfo {
        try await Task.sleep(seconds: 5)
        guard let url = Bundle.main.url(forResource: isAlreadyReferralResourceName, withExtension: "json") else {
            throw "Everything is corrupted!!!!!"
        }
        let data = try Data(contentsOf: url)
        return try decoder.decode(ReferralProgramInfo.self, from: data)
    }
}
