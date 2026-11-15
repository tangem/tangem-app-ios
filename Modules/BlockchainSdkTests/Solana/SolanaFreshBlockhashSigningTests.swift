//
//  SolanaFreshBlockhashSigningTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import TangemFoundation
import class SolanaSwift.Solana
import class SolanaSwift.NetworkingRouter
import enum SolanaSwift.HTTPMethod
import enum SolanaSwift.SolanaError
import struct SolanaSwift.PublicKey
import struct TangemSdk.SignData
@testable import BlockchainSdk

struct SolanaFreshBlockhashSigningTests {
    @Test
    func compiledTransactionIsSignedWithBlockhashFetchedAfterAuthorization() async throws {
        let fixture = SigningFixture()
        let compiledTransaction = try fixture.compiledTransaction()

        _ = try? await fixture.manager.send(compiledTransaction: compiledTransaction, signer: fixture.signer)

        #expect(fixture.events.entries == [.authorized, .blockhashFetched])
        let signedMessage = try #require(fixture.signer.signedHashes.first)
        let fresh = try #require(PublicKey(string: SigningFixture.freshBlockhash)).data
        let stale = try #require(PublicKey(string: SigningFixture.staleBlockhash)).data
        #expect(signedMessage.range(of: fresh) != nil)
        #expect(signedMessage.range(of: stale) == nil)
    }

    @Test
    func durableNonceTransactionIsSignedWithoutFetchingBlockhash() async throws {
        let fixture = SigningFixture()
        let compiledTransaction = try fixture.compiledTransaction(instructionData: Data([4, 0, 0, 0]))

        _ = try? await fixture.manager.send(compiledTransaction: compiledTransaction, signer: fixture.signer)

        #expect(fixture.events.entries == [.authorized])
        let signedMessage = try #require(fixture.signer.signedHashes.first)
        let stale = try #require(PublicKey(string: SigningFixture.staleBlockhash)).data
        #expect(signedMessage.range(of: stale) != nil)
    }

    @Test
    func coinTransferIsSignedWithBlockhashFetchedAfterAuthorization() async throws {
        let fixture = SigningFixture()

        _ = try? await fixture.manager.send(fixture.coinTransaction(), signer: fixture.signer).async()

        #expect(fixture.events.entries == [.authorized, .blockhashFetched])
        let signedMessage = try #require(fixture.signer.signedHashes.first)
        let fresh = try #require(PublicKey(string: SigningFixture.freshBlockhash)).data
        #expect(signedMessage.range(of: fresh) != nil)
    }
}

private struct SigningFixture {
    static let blockchain = Blockchain.solana(curve: .ed25519, testnet: false)
    static let walletPublicKey = Data(hex: "B148CC30B144E8F214AE5754C753C40A9BF2A3359DB4246E03C6A2F61A82C282")
    static let destination = "BmAzxn8WLYU3gEw79ATUdSUkMT53MeS5LjapBQB8gTPJ"
    static let staleBlockhash = "SysvarRent111111111111111111111111111111111"
    static let freshBlockhash = "ComputeBudget111111111111111111111111111111"

    let events = EventLog()
    let router: BlockhashNetworkRouter
    let manager: SolanaWalletManager
    let signer: AuthorizingSigner

    init() {
        router = BlockhashNetworkRouter(endpoints: [.devnetSolana], apiLogger: nil)
        router.blockhash = Self.freshBlockhash
        router.events = events

        let publicKey = Wallet.PublicKey(seedKey: Self.walletPublicKey, derivationType: .none)
        let address = try! AddressServiceFactory(blockchain: Self.blockchain).makeAddressService().makeAddress(from: Self.walletPublicKey)
        let wallet = Wallet(blockchain: Self.blockchain, publicKey: publicKey, addressesProvider: CommonAddressesProvider(defaultAddress: address))

        manager = SolanaWalletManager(wallet: wallet)
        manager.networkService = SolanaNetworkService(
            providers: [],
            solanaSdk: Solana(router: router, accountStorage: SolanaDummyAccountStorage()),
            blockchain: Self.blockchain,
            providerConfiguration: .init(logOptions: nil)
        )

        signer = AuthorizingSigner(events: events)
    }

    func coinTransaction() -> Transaction {
        let feeParameters = SolanaFeeParameters(destinationAccountExists: true, computeUnitLimit: nil, computeUnitPrice: nil)

        return Transaction(
            amount: Amount(with: Self.blockchain, value: 1),
            fee: Fee(.zeroCoin(for: Self.blockchain), parameters: feeParameters),
            sourceAddress: manager.wallet.address,
            destinationAddress: Self.destination,
            changeAddress: manager.wallet.address,
            contractAddress: nil
        )
    }

    func compiledTransaction(instructionData: Data = Data([2, 0, 0, 0]) + Data(repeating: 1, count: 8)) throws -> Data {
        let owner = try #require(PublicKey(data: Self.walletPublicKey)).base58EncodedString
        let transfer = SolanaRawInstruction(
            programId: PublicKey.programId.base58EncodedString,
            accounts: [
                .init(address: owner, isSigner: true, isWritable: true),
                .init(address: Self.destination, isSigner: false, isWritable: true),
            ],
            data: instructionData
        )
        let transaction = try SolanaSelfPaidTransaction.make(
            instructions: [transfer],
            feePayer: Self.walletPublicKey,
            blockhash: SolanaBlockhash(value: Self.staleBlockhash, fetchedAt: Date())
        )
        return try transaction.serialized(signature: Data(repeating: 0, count: 64))
    }
}

// MARK: - Stubs

private enum Event: Equatable {
    case authorized
    case blockhashFetched
}

private final class EventLog: Sendable {
    private let state = OSAllocatedUnfairLock<[Event]>(initialState: [])

    func append(_ event: Event) {
        state.withLock { $0.append(event) }
    }

    var entries: [Event] {
        state.withLock { $0 }
    }
}

private final class BlockhashNetworkRouter: NetworkingRouter {
    var blockhash = ""
    var events: EventLog?

    override func request<T>(
        method: HTTPMethod = .post,
        bcMethod: String = #function,
        parameters: [(any Encodable)?] = [],
        enableContinuedRetry: Bool = true,
        onComplete: @escaping (Result<T, any Error>) -> Void
    ) where T: Decodable {
        guard bcMethod.hasPrefix("getLatestBlockhash") else {
            onComplete(.failure(SolanaError.nullValue))
            return
        }

        events?.append(.blockhashFetched)
        let json = #"{"context":{"slot":1},"value":{"blockhash":"\#(blockhash)","lastValidBlockHeight":100}}"#
        onComplete(Result { try JSONDecoder().decode(T.self, from: Data(json.utf8)) })
    }
}

private final class AuthorizingSigner: TransactionSigner {
    private let events: EventLog
    private let hashes = OSAllocatedUnfairLock<[Data]>(initialState: [])

    init(events: EventLog) {
        self.events = events
    }

    var signedHashes: [Data] {
        hashes.withLock { $0 }
    }

    func sign(walletPublicKey: Wallet.PublicKey, hashesProvider: @escaping () async throws -> [Data]) async throws -> [SignatureInfo] {
        events.append(.authorized)
        let provided = try await hashesProvider()
        hashes.withLock { $0 = provided }
        throw SolanaError.nullValue
    }

    func sign(hashes: [Data], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[SignatureInfo], Error> {
        Fail(error: SolanaError.nullValue).eraseToAnyPublisher()
    }

    func sign(hash: Data, walletPublicKey: Wallet.PublicKey) -> AnyPublisher<SignatureInfo, Error> {
        Fail(error: SolanaError.nullValue).eraseToAnyPublisher()
    }

    func sign(dataToSign: [SignData], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[SignatureInfo], Error> {
        Fail(error: SolanaError.nullValue).eraseToAnyPublisher()
    }
}
