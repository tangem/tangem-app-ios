//
//  WalletConnectV2SignTypedDataHandlerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import Commons
import BlockchainSdk
@testable import Tangem

@Suite("Tests for `WalletConnectV2SignTypedDataHandler` typed data policy")
struct WalletConnectV2SignTypedDataHandlerTests {
    private typealias Fixture = WCEthTypedDataFixture

    @Test("Rejects forbidden typed data before the sign screen", arguments: [
        Fixture.reportedBatchPayload,
        Fixture.permitPayload(domain: Fixture.permitDomain(verifyingContract: Fixture.signer.uppercased())),
        Fixture.permitPayload(domain: Fixture.permitDomain(name: "Tangem7702GaslessExecutor")),
    ])
    func rejectsForbiddenTypedData(typedData: String) {
        let signer = WalletConnectSignerSpy()

        let error = #expect(throws: WalletConnectTransactionRequestProcessingError.self) {
            _ = try makeHandler(typedData: typedData, signer: signer)
        }

        guard case .forbiddenTypedData? = error else {
            Issue.record("Expected forbiddenTypedData, got \(String(describing: error))")
            return
        }

        #expect(signer.signedData.isEmpty)
    }

    @Test("Signs a regular Permit over its EIP-712 hash")
    func signsPermit() async throws {
        let signer = WalletConnectSignerSpy()
        let json = Fixture.permitPayload()
        let expectedHash = try Fixture.decode(json).signHash

        let handler = try makeHandler(typedData: json, signer: signer)

        #expect(try await handler.validate() == .empty)
        _ = try await handler.handle()
        #expect(signer.signedData == [expectedHash])
    }

    private func makeHandler(typedData: String, signer: WalletConnectSignerSpy) throws -> WalletConnectV2SignTypedDataHandler {
        try WalletConnectV2SignTypedDataHandler(
            requestParams: AnyCodable([Fixture.signer, typedData]),
            blockchainId: Fixture.blockchain.networkId,
            signer: signer,
            wcAccountsWalletModelProvider: WalletConnectAccountsWalletModelProviderStub(
                walletModel: WalletModelTestsMock(
                    tokenItem: .blockchain(.init(Fixture.blockchain, derivationPath: nil)),
                    isEmpty: false,
                    addresses: [PlainAddress(value: Fixture.signer, type: .default)]
                )
            ),
            accountId: "account"
        )
    }
}
