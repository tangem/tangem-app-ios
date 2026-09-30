//
//  PolymarketSupportChatInputFactoryTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
import TangemPolymarket
import TangemSdk
@testable import Tangem

@Suite("Polymarket support chat input", .serialized)
@MainActor
struct PolymarketSupportChatInputFactoryTests {
    @Test("The chat is opened as the wallet Polymarket runs on, not the selected one")
    func identifiesThePolymarketWallet() async {
        let environment = InjectedEnvironment()

        await environment.run {
            let input = PolymarketSupportChatInputFactory().makeInput(for: environment.otherWallet)

            #expect(input.userIdentifier == InjectedEnvironment.otherWalletId.lowercased())
        }
    }

    @Test("The chat says it came from Polymarket to analytics and to Usedesk")
    func marksTheSourceAndTopic() async {
        let environment = InjectedEnvironment()

        await environment.run {
            let input = PolymarketSupportChatInputFactory().makeInput(for: environment.selectedWallet)

            #expect(input.source.analyticsParameterValue == .predictions)
            #expect(input.topic == .polymarket)
        }
    }

    @Test("The logs carry the Polymarket account and the deposit wallet of the wallet the chat is opened for")
    func logsCarryThePolymarketWallet() async throws {
        let environment = InjectedEnvironment()
        let wallet = PolymarketUserWalletModelStub()
        var logs: String?

        await environment.run {
            let input = PolymarketSupportChatInputFactory().makeInput(for: wallet)
            logs = input.logsComposer.getInfoData().flatMap { String(data: $0, encoding: .utf8) }
        }

        let infoLogs = try #require(logs)
        let depositWalletAddress = try PolymarketDepositWalletDeriver.derive(ownerAddress: PolymarketUserWalletModelStub.ownerAddress)

        #expect(infoLogs.contains("Polymarket account state: active\n"))
        #expect(infoLogs.contains("Polymarket deposit wallet address: \(depositWalletAddress)\n"))
    }
}

// MARK: - Stubs

private final class PolymarketUserWalletModelStub: UserWalletModelMock {
    static let ownerAddress = "0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d"

    private static let walletPublicKey = Data(hexString: "0279BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798")
    private static let ownerPublicKey = Data(hexString: "0241DCD64B5F4A039FC339A16300A833A883B218909F2EBCAF3906651C76842C45")
    private static let chainCode = Data(repeating: 0x11, count: 32)

    override var userWalletId: UserWalletId { UserWalletId(value: Data("polymarket-wallet".utf8)) }
    override var config: UserWalletConfig { UserWalletConfigStub() }

    override var keysRepository: KeysRepository {
        KeysRepositoryTestsMock(keys: [
            KeyInfo(
                publicKey: Self.walletPublicKey,
                chainCode: Self.chainCode,
                curve: .secp256k1,
                isImported: false,
                derivedKeys: [PolymarketUtilities.derivationPath: ExtendedPublicKey(publicKey: Self.ownerPublicKey, chainCode: Self.chainCode)]
            ),
        ])
    }

    override var accountModelsManager: AccountModelsManager {
        AccountModelsManagerStub(accounts: [.polymarket(PolymarketAccountModelStub(state: .active))])
    }
}
