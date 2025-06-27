//
//  PrivateInfoContainer.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

actor PrivateInfoContainer {
    private let getPrivateInfo: () throws -> Data

    init(getPrivateInfo: @escaping () throws -> Data) {
        self.getPrivateInfo = getPrivateInfo
    }

    func call<T>(_ call: @Sendable (PrivateInfo) throws -> T) throws -> T {
        let privateInfoData = try getPrivateInfo()
        return try privateInfoData.execute(call: call)
    }
}

private extension Data {
    func execute<T>(call: @Sendable (PrivateInfo) throws -> T) throws -> T {
        guard var privateInfo = PrivateInfo(data: self) else {
            throw PrivateInfoError.invalidData
        }
        defer { privateInfo.clear() }
        return try call(privateInfo)
    }
}
