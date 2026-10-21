//
//  CommonJointAccountOperationsServiceTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import BlockchainSdk
import TangemSdk
@testable import Tangem

// MARK: - Tests

/// What a member is asked before an operation is signed, and what is handed on once it is.
@Suite("Tests for making, signing and declining a joint account's operations")
struct CommonJointAccountOperationsServiceTests {
    /// Kept by the suite because the account holds it weakly, and a new one is made per test the way every stored
    /// property of a suite is.
    private let delegate = JointAccountModelDelegateMock()

    // MARK: - Creating

    @Test("A transfer is signed as a Safe transaction and handed to the repository under the account it belongs to")
    func createdOperationIsHandedOn() async throws {
        let context = try makeContext(registeredOperation: Self.operation())

        _ = try await context.sut.createOperation(transaction: Self.transaction(), in: context.wallet)

        let created = try #require(context.repository.createdOperations.first)

        #expect(context.repository.createdOperations.count == 1)
        #expect(created.cryptoAccountId == context.cryptoAccountId)
        #expect(created.request.safeAddress == Constants.safeAddress)
        #expect(created.request.chainId == Constants.chainId)
        #expect(created.request.safeTransaction.to == Constants.recipient)
        #expect(created.request.safeTransaction.nonce == Constants.nonce)
        // `r ‖ s ‖ v`, the form the Safe checks
        #expect(created.request.signature.count == 65)
        #expect(context.signer.signedHashes.count == 1)
    }

    @Test("A fee quoted as anything but a Safe operation carries no gas terms to sign")
    func createWithoutSafeFeeParametersIsRefused() async throws {
        let context = try makeContext()
        let transaction = Self.transaction(feeParameters: EthereumLegacyFeeParameters(gasLimit: 21000, gasPrice: 1))

        await #expect(throws: JointOperationError.missingFeeParameters) {
            try await context.sut.createOperation(transaction: transaction, in: context.wallet)
        }
        #expect(context.repository.createdOperations.isEmpty)
        #expect(context.signer.signedHashes.isEmpty)
    }

    @Test("An account still waiting on its members has no address to sign for")
    func createOnAnAccountThatIsNotActiveIsRefused() async throws {
        let context = try makeContext(accountStatus: .pending)

        await #expect(throws: JointOperationError.accountNotActive) {
            try await context.sut.createOperation(transaction: Self.transaction(), in: context.wallet)
        }
        #expect(context.repository.createdOperations.isEmpty)
    }

    @Test("A network already carrying an unfinished operation takes no second one")
    func createWhileTheNetworkIsBusyIsRefused() async throws {
        let context = try makeContext(pendingOperations: [Self.operation(status: .awaitingSignatures)])

        await #expect(throws: JointOperationError.networkBusy) {
            try await context.sut.createOperation(transaction: Self.transaction(), in: context.wallet)
        }
        #expect(context.repository.createdOperations.isEmpty)
        #expect(context.signer.signedHashes.isEmpty)
    }

    /// The listing goes on reporting an operation after the relayer has executed it, and such a record holds nothing.
    @Test("An operation the network has finished with leaves it free", arguments: [
        JointAccountOperationStatus.executed,
        .failed,
        .cancelled,
    ])
    func createAfterTheOperationBeforeItFinishedIsAllowed(status: JointAccountOperationStatus) async throws {
        let context = try makeContext(
            pendingOperations: [Self.operation(status: status)],
            registeredOperation: Self.operation()
        )

        _ = try await context.sut.createOperation(transaction: Self.transaction(), in: context.wallet)

        #expect(context.repository.createdOperations.count == 1)
    }

    @Test("An unfinished operation in another network says nothing about this one")
    func createWhileAnotherNetworkIsBusyIsAllowed() async throws {
        let context = try makeContext(
            pendingOperations: [Self.operation(chainId: 137)],
            registeredOperation: Self.operation()
        )

        _ = try await context.sut.createOperation(transaction: Self.transaction(), in: context.wallet)

        #expect(context.repository.createdOperations.count == 1)
    }

    /// A deployment that happened since the quote changes `baseGas`, so the fee has to be quoted again.
    @Test("A Safe deployed since the fee was quoted makes the quote stale")
    func createQuotedAgainstAnotherDeploymentIsRefused() async throws {
        let context = try makeContext(state: .notDeployed)

        await #expect(throws: JointOperationError.safeStateChanged) {
            try await context.sut.createOperation(transaction: Self.transaction(), in: context.wallet)
        }
        #expect(context.repository.createdOperations.isEmpty)
    }

    @Test("A Safe whose owners are not the account's members is not the account it claims to be")
    func createForAnotherCompositionIsRefused() async throws {
        let context = try makeContext(
            state: .deployed(nonce: Constants.nonce, owners: [Constants.members[0], Constants.outsider], threshold: 2)
        )

        await #expect(throws: JointOperationError.compositionMismatch) {
            try await context.sut.createOperation(transaction: Self.transaction(), in: context.wallet)
        }
        #expect(context.repository.createdOperations.isEmpty)
        #expect(context.signer.signedHashes.isEmpty)
    }

    @Test("A threshold the Safe does not hold to is refused as well")
    func createAgainstAnotherThresholdIsRefused() async throws {
        let context = try makeContext(
            state: .deployed(nonce: Constants.nonce, owners: Constants.members, threshold: 1)
        )

        await #expect(throws: JointOperationError.compositionMismatch) {
            try await context.sut.createOperation(transaction: Self.transaction(), in: context.wallet)
        }
        #expect(context.repository.createdOperations.isEmpty)
    }

    /// The transfer built for the Safe would drop it, so the operation is refused rather than misrepresented.
    @Test("A transfer carrying calldata of its own is refused")
    func createWithCustomCalldataIsRefused() async throws {
        let context = try makeContext()
        let transaction = Self.transaction(params: EthereumTransactionParams(data: Data([0xA9, 0x05, 0x9C, 0xBB])))

        await #expect(throws: JointOperationError.unsupportedOperationForm) {
            try await context.sut.createOperation(transaction: transaction, in: context.wallet)
        }
        #expect(context.repository.createdOperations.isEmpty)
    }

    @Test("A call aimed at the Safe itself is not a transfer the members agreed to")
    func createAimedAtTheSafeItselfIsRefused() async throws {
        let context = try makeContext(innerCall: SafeInnerCall(to: Constants.safeAddress, value: 1, data: Data()))

        await #expect(throws: JointOperationError.unsupportedOperationForm) {
            try await context.sut.createOperation(transaction: Self.transaction(), in: context.wallet)
        }
        #expect(context.repository.createdOperations.isEmpty)
    }

    // MARK: - Signing

    @Test("A co-signer's signature goes to the repository against the operation it answers")
    func signedOperationIsHandedOn() async throws {
        let context = try makeContext()
        let operation = Self.operation(id: "op_01HZX")

        try await context.sut.signOperation(operation, in: context.wallet)

        let signed = try #require(context.repository.signedOperations.first)

        #expect(context.repository.signedOperations.count == 1)
        #expect(signed.id == "op_01HZX")
        #expect(signed.cryptoAccountId == context.cryptoAccountId)
        #expect(signed.safeTransaction.nonce == Constants.nonce)
        #expect(signed.signature.count == 65)
    }

    /// The nonce the operation was created with is the one the Safe is still waiting to use.
    @Test("An operation the Safe has moved past is not worth a signature")
    func signOperationTheSafeHasMovedPastIsRefused() async throws {
        let context = try makeContext(state: .deployed(nonce: Constants.nonce + 1, owners: Constants.members, threshold: 2))

        await #expect(throws: JointOperationError.operationSuperseded) {
            try await context.sut.signOperation(Self.operation(), in: context.wallet)
        }
        #expect(context.repository.signedOperations.isEmpty)
        #expect(context.signer.signedHashes.isEmpty)
    }

    /// Nothing binds the Safe on chain to what it was when the operation was created, so it is checked anew.
    @Test("A Safe whose composition has changed since the operation was created is refused on signing too")
    func signAgainstAnotherCompositionIsRefused() async throws {
        let context = try makeContext(
            state: .deployed(nonce: Constants.nonce, owners: [Constants.members[0], Constants.outsider], threshold: 2)
        )

        await #expect(throws: JointOperationError.compositionMismatch) {
            try await context.sut.signOperation(Self.operation(), in: context.wallet)
        }
        #expect(context.repository.signedOperations.isEmpty)
    }

    @Test("An operation Blockaid flags as malicious is not signed")
    func maliciousOperationIsNotSigned() async throws {
        let context = try makeContext(blockaidVerdict: .malicious)

        await #expect(throws: JointOperationError.maliciousOperation) {
            try await context.sut.signOperation(Self.operation(), in: context.wallet)
        }
        #expect(context.signer.signedHashes.isEmpty)
        #expect(context.repository.signedOperations.isEmpty)
    }

    @Test("An operation Blockaid could not check is not signed", .timeLimit(.minutes(1)))
    func uncheckedOperationIsNotSigned() async throws {
        let context = try makeContext(blockaidVerdict: .unavailable)

        await #expect(throws: JointOperationError.securityCheckUnavailable) {
            try await context.sut.signOperation(Self.operation(), in: context.wallet)
        }
        #expect(context.signer.signedHashes.isEmpty)
        #expect(context.repository.signedOperations.isEmpty)
    }

    @Test("Only a Safe Blockaid can't read yet is signed without a verdict", arguments: [
        (JointOperationBlockaidVerdict.safe, true, nil),
        (.safe, false, nil),
        (.unknown, false, nil),
        (.unknown, true, JointOperationError.securityCheckUnavailable),
        (.unavailable, false, .securityCheckUnavailable),
        (.unavailable, true, .securityCheckUnavailable),
        (.malicious, false, .maliciousOperation),
        (.malicious, true, .maliciousOperation),
    ])
    func verdictDecidesTheSigning(verdict: JointOperationBlockaidVerdict, isDeployed: Bool, expected: JointOperationError?) {
        do {
            try CommonJointAccountOperationsService.ensureSigningIsAllowed(by: verdict, isDeployed: isDeployed)
            #expect(expected == nil)
        } catch {
            #expect(error as? JointOperationError == expected)
        }
    }

    // MARK: - Declining

    @Test("A decline names the operation and the account it belongs to, and carries nothing else")
    func rejectedOperationIsHandedOn() async throws {
        let context = try makeContext()
        let operation = Self.operation(id: "op_01HZX")

        try await context.sut.rejectOperation(operation, in: context.wallet)

        let rejected = try #require(context.repository.rejectedOperations.first)

        #expect(context.repository.rejectedOperations.count == 1)
        #expect(rejected.id == "op_01HZX")
        #expect(rejected.cryptoAccountId == context.cryptoAccountId)
        // The card is not asked for anything: the contract has nothing for a refusal to sign
        #expect(context.signer.signedHashes.isEmpty)
    }

    /// Declining asks the chain for nothing and signs nothing: the answer is about the operation, not about the
    /// Safe's state, and which of the two refusals it is follows from the wallet it is made for.
    @Test("A decline is sent without reading the Safe")
    func rejectDoesNotReadTheSafe() async throws {
        let context = try makeContext(state: nil)

        try await context.sut.rejectOperation(Self.operation(), in: context.wallet)

        #expect(context.repository.rejectedOperations.count == 1)
    }
}

// MARK: - Helpers

private extension CommonJointAccountOperationsServiceTests {
    func makeContext(
        accountStatus: JointAccountStatus = .active(safeAddress: Constants.safeAddress),
        state: SafeContractState? = .deployed(nonce: Constants.nonce, owners: Constants.members, threshold: 2),
        innerCall: SafeInnerCall = Constants.innerCall,
        pendingOperations: [JointAccountOperation] = [],
        registeredOperation: JointAccountOperation? = nil,
        blockaidVerdict: JointOperationBlockaidVerdict = .safe
    ) throws -> Context {
        let account = makeAccount(status: accountStatus)
        let walletModel = WalletModelTestsMock(
            tokenItem: .blockchain(Constants.ethereum),
            isEmpty: false,
            account: account,
            safeWalletManagerOperationsService: SafeWalletManagerOperationsServiceTestsMock(state: state, innerCall: innerCall)
        )
        let wallet = try JointAccountWalletBuilder().build(walletModel: walletModel)

        let cryptoAccountId = account.id.rawValue.hexString
        let records = pendingOperations.isEmpty
            ? []
            : [StoredJointAccountPendingOperations(cryptoAccountId: cryptoAccountId, operations: pendingOperations)]
        let repository = JointAccountsRepositoryStub(pendingOperations: records, registeredOperation: registeredOperation)

        let signer = try TangemSignerDouble()
        let userWalletModel = UserWalletModelDouble(signer: signer)
        let sut = CommonJointAccountOperationsService(
            jointAccountsRepository: repository,
            signerFactory: TangemSignerFactory(userWalletModel: userWalletModel),
            blockaidGate: JointOperationBlockaidGateStub(verdict: blockaidVerdict)
        )

        return Context(
            sut: sut,
            repository: repository,
            signer: signer,
            wallet: wallet,
            cryptoAccountId: cryptoAccountId,
            account: account,
            walletModel: walletModel,
            userWalletModel: userWalletModel
        )
    }

    func makeAccount(status: JointAccountStatus) -> CommonJointAccountModel {
        let slots = Constants.members.map { address in
            JointAccountSlot.member(JointAccountMember(name: "Member", address: address, role: .member(inviteId: nil)))
        }

        return CommonJointAccountModel(
            cryptoAccount: CryptoAccountModelMock(isMainAccount: false, onArchive: { _ in }),
            derivationIdentity: CryptoAccountDerivationIdentity(derivationIndex: 1, type: .joint),
            accountPolicy: JointAccountPolicy(membersCount: Constants.members.count, signersCount: 2),
            accountStatus: status,
            operationsService: JointAccountOperationsServiceMock(),
            pendingOperationsProvider: JointAccountPendingOperationsProviderMock(),
            membersService: JointAccountMembersServiceMock(slots: slots),
            delegate: delegate
        )
    }

    static func transaction(
        feeParameters: any FeeParameters = Constants.feeParameters,
        params: TransactionParams? = nil
    ) -> BSDKTransaction {
        let amount = Amount(with: Constants.ethereum.blockchain, value: 0.001)

        return BSDKTransaction(
            amount: amount,
            fee: Fee(amount, parameters: feeParameters),
            sourceAddress: Constants.safeAddress,
            destinationAddress: Constants.recipient,
            changeAddress: Constants.safeAddress,
            params: params
        )
    }

    static func operation(
        id: String = "op",
        chainId: Int = Constants.chainId,
        nonce: Int = Constants.nonce,
        status: JointAccountOperationStatus = .awaitingSignatures
    ) -> JointAccountOperation {
        JointAccountOperation(
            id: id,
            chainId: chainId,
            safeTransaction: SafeTransaction(innerCall: Constants.innerCall, feeParameters: Constants.feeParameters, nonce: nonce),
            status: status,
            initiator: Constants.members[0],
            signatures: []
        )
    }
}

// MARK: - Auxiliary types

private extension CommonJointAccountOperationsServiceTests {
    /// Holds what the service is built out of, since the signer factory keeps the wallet model weakly and a wallet
    /// keeps its model no more strongly than the test does.
    struct Context {
        let sut: CommonJointAccountOperationsService
        let repository: JointAccountsRepositoryStub
        let signer: TangemSignerDouble
        let wallet: JointAccountWallet
        let cryptoAccountId: String

        let account: CommonJointAccountModel
        let walletModel: WalletModelTestsMock
        let userWalletModel: UserWalletModelDouble
    }
}

// MARK: - Constants

private extension CommonJointAccountOperationsServiceTests {
    enum Constants {
        static let ethereum = BlockchainNetwork(.ethereum(testnet: false), derivationPath: nil)
        static let chainId = 1
        static let nonce = 7

        static let safeAddress = "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"
        static let recipient = "0x2b5ad9c1e7f40638b2c1a9d3e5f70241c6b8a91c"
        static let refundReceiver = "0x7e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf"
        static let members = ["0x7e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf", "0x2b5ad9c1e7f40638b2c1a9d3e5f70241c6b8a91c"]
        /// Belongs to nobody the account knows, so a Safe owned by it is a Safe of another composition.
        static let outsider = "0x1f4c7a3e9b5d2086c4e6a8b0d2f4c6e8a0b2d4f6"

        static let innerCall = SafeInnerCall(to: recipient, value: 1_000_000_000_000_000, data: Data())

        static let feeParameters = SafeTransactionFeeParameters(
            safeTxGas: 23520,
            baseGas: 100_000,
            gasPrice: 1_575_000_000,
            gasToken: .coin(ethereum.blockchain),
            refundReceiver: refundReceiver,
            isDeployed: true
        )
    }
}

// MARK: - Doubles

/// Signs with a key of its own, so that what the service unmarshals is a signature that really recovers.
private final class TangemSignerDouble: TangemSigner {
    let latestSignerType: TangemSignerType? = nil

    private(set) var signedHashes: [Data] = []

    private let privateKey: Data
    private let publicKey: Data

    init() throws {
        let keyPair = try Secp256k1Utils().generateKeyPair()

        privateKey = keyPair.privateKey
        publicKey = keyPair.publicKey
    }

    func sign(hash: Data, walletPublicKey: Wallet.PublicKey) -> AnyPublisher<SignatureInfo, Error> {
        sign(hashes: [hash], walletPublicKey: walletPublicKey)
            .compactMap(\.first)
            .eraseToAnyPublisher()
    }

    func sign(hashes: [Data], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[SignatureInfo], Error> {
        signedHashes.append(contentsOf: hashes)

        do {
            let signatures = try hashes.map { hash in
                // What the utils actually sign is the hash of what they are handed, and that is what recovery reads
                SignatureInfo(
                    signature: try Secp256k1Utils().sign(hash, with: privateKey),
                    publicKey: publicKey,
                    hash: hash.getSHA256()
                )
            }

            return Just(signatures).setFailureType(to: Error.self).eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    func sign(dataToSign: [SignData], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[SignatureInfo], Error> {
        sign(hashes: dataToSign.flatMap(\.hashes), walletPublicKey: walletPublicKey)
    }
}

private struct JointOperationBlockaidGateStub: JointOperationBlockaidGate {
    let verdict: JointOperationBlockaidVerdict

    func verdict(on operation: JointAccountOperation, safeAddress: String, ownerAddress: String?, blockchain: Blockchain) async -> JointOperationBlockaidVerdict {
        verdict
    }
}

/// The only thing the signer factory asks a wallet model for.
private final class UserWalletModelDouble: UserWalletModelMock {
    override var signer: TangemSigner { _signer }

    private let _signer: TangemSigner

    init(signer: TangemSigner) {
        _signer = signer

        super.init()
    }
}
