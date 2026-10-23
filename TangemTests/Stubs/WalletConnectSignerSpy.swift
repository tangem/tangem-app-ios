//
//  WalletConnectSignerSpy.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
@testable import Tangem

final class WalletConnectSignerSpy: WalletConnectSigner {
    private let state = OSAllocatedUnfairLock(initialState: [Data]())

    var signedData: [Data] {
        state.withLock { $0 }
    }

    func sign(data: Data, using walletModel: any WalletModel) async throws -> Data {
        state.withLock { $0.append(data) }
        return Data(repeating: 0x01, count: 64)
    }

    func sign(hashes: [Data], using walletModel: any WalletModel) async throws -> [Data] {
        state.withLock { $0.append(contentsOf: hashes) }
        return hashes.map { _ in Data(repeating: 0x01, count: 64) }
    }
}
