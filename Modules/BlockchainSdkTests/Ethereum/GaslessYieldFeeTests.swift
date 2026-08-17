//
//  GaslessYieldFeeTests.swift
//  BlockchainSdkTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BigInt
import Combine
import Foundation
import Testing
@testable import BlockchainSdk

@Suite("Gasless Yield Fee")
struct GaslessYieldFeeTests {
    @Test("Plain gasless fee keeps ERC-20 transfer estimation reverts")
    func plainGaslessFeeFailsOnTransferRevert() async {
        let sut = makeSUT(gasLimitResults: [
            .failure(JSONRPC.APIError(code: 3, message: "ERC20: transfer amount exceeds balance")),
        ])

        await #expect(throws: JSONRPC.APIError.self) {
            _ = try await sut.getEstimatedGaslessTransactionFee(
                feeToken: Self.feeToken,
                estimatedGasLimit: 21_000,
                otherNativeFee: nil,
                feeRecipientAddress: Self.feeRecipientAddress,
                nativeToFeeTokenRate: 1
            )
        }
    }

    @Test("Yield gasless fee falls back to deterministic transfer gas")
    func yieldGaslessFeeFallsBackToTransferGas() async throws {
        let sut = makeSUT(gasLimitResults: [
            .failure(JSONRPC.APIError(code: 3, message: "ERC20: transfer amount exceeds balance")),
            .success(50_000),
        ])

        let fee = try await sut.getEstimatedGaslessYieldTransactionFee(
            feeToken: Self.feeToken,
            estimatedGasLimit: 21_000,
            otherNativeFee: nil,
            feeRecipientAddress: Self.feeRecipientAddress,
            nativeToFeeTokenRate: 1,
            yieldFeeOptions: Self.yieldFeeOptions
        )

        let parameters = try #require(fee.parameters as? EthereumGaslessTransactionFeeParameters)
        let yieldWithdraw = try #require(parameters.yieldWithdraw)

        #expect(parameters.feeTokenTransferGasLimit == 110_000)
        #expect(parameters.callGasLimit == 21_000)
        #expect(yieldWithdraw.withdrawGasLimit == 70_000)
        #expect(parameters.gasLimit == 21_000 + 110_000 + 70_000 + EthereumFeeParametersConstants.gaslessBaseGasBuffer)
    }

    @Test("Yield transaction fee re-estimates upgrade wrapped user transaction")
    func yieldTransactionFeeReestimatesUpgradeWrappedUserTransaction() async throws {
        let sut = makeSUT(gasLimitResults: [
            .success(21_000),
            .success(32_000),
            .success(50_000),
            .success(60_000),
        ])

        let fee = try await sut.getGaslessYieldTransactionFee(
            feeToken: Self.feeToken,
            destination: Self.upgradeYieldFeeOptions.yieldContractAddress,
            value: "0x0",
            data: Data([0x12, 0x34]),
            otherNativeFee: nil,
            feeRecipientAddress: Self.feeRecipientAddress,
            nativeToFeeTokenRate: 1,
            yieldFeeOptions: Self.upgradeYieldFeeOptions
        )

        let parameters = try #require(fee.parameters as? EthereumGaslessTransactionFeeParameters)
        let yieldWithdraw = try #require(parameters.yieldWithdraw)

        #expect(parameters.callGasLimit == 32_000)
        #expect(parameters.feeTokenTransferGasLimit == 55_000)
        #expect(yieldWithdraw.withdrawGasLimit == 84_000)
        #expect(parameters.gasLimit == 32_000 + 55_000 + 84_000 + EthereumFeeParametersConstants.gaslessBaseGasBuffer)
    }

    /// The gasless flow builds its amount from the token item, which carries no yield supply metadata. Without
    /// it the payload moves the token straight out of the account, where a supplied balance no longer sits, and
    /// the transfer reverts.
    @Test("Transaction payload sends a supplied token through the yield module")
    func transactionPayloadSendsSuppliedTokenThroughYieldModule() async throws {
        let sut = makeSUT(gasLimitResults: [])
        sut.wallet.add(amount: Self.suppliedTokenAmount)

        let payload = try await sut.buildTransactionPayload(transaction: Self.transferTransaction)

        let expected = try YieldSendMethod(
            tokenContractAddress: Self.feeToken.contractAddress,
            destination: Self.destinationAddress,
            amount: Self.transferAmountInTokenUnits
        )

        #expect(payload.destinationAddress == Self.yieldFeeOptions.yieldContractAddress)
        #expect(payload.data == expected.data)
        #expect(payload.coinAmount.isZero)
    }

    /// The supplied token's own call is the batch leg the upgrade wrapper lands on, so the gas it is capped at
    /// has to be estimated wrapped — the bare `send()` estimate misses both the upgrade and whatever the new
    /// implementation costs.
    @Test("Yield fee re-estimates the upgrade wrapped send of a supplied token")
    func yieldFeeReestimatesUpgradeWrappedSuppliedTokenSend() async throws {
        let sut = makeSUT(gasLimitResults: [
            .success(100_000),
            .success(120_000),
            .success(50_000),
            .success(60_000),
        ])
        sut.wallet.add(amount: Self.suppliedTokenAmount)

        let fee = try await sut.getGaslessYieldFee(
            feeToken: Self.feeToken,
            amount: Self.transferAmountFromSendScreen,
            destination: Self.destinationAddress,
            feeRecipientAddress: Self.feeRecipientAddress,
            nativeToFeeTokenRate: 1,
            yieldFeeOptions: Self.upgradeYieldFeeOptions
        )

        let parameters = try #require(fee.parameters as? EthereumGaslessTransactionFeeParameters)
        let yieldWithdraw = try #require(parameters.yieldWithdraw)

        #expect(parameters.callGasLimit == 168_000)
        #expect(parameters.feeTokenTransferGasLimit == 55_000)
        #expect(yieldWithdraw.withdrawGasLimit == 84_000)
        #expect(parameters.gasLimit == 168_000 + 55_000 + 84_000 + EthereumFeeParametersConstants.gaslessBaseGasBuffer)

        #expect(sut.gasLimitRequests.count == 4)

        let wrappedRequest = sut.gasLimitRequests[1]
        let sendMethod = try YieldSendMethod(
            tokenContractAddress: Self.feeToken.contractAddress,
            destination: Self.destinationAddress,
            amount: Self.transferAmountInTokenUnits
        )
        let expectedData = UpgradeToAndCallMethod(
            newImplementation: Self.upgradeImplementation,
            callData: sendMethod.data
        ).encodedData

        #expect(wrappedRequest.to == Self.upgradeYieldFeeOptions.yieldContractAddress)
        #expect(wrappedRequest.data == expectedData)
    }

    @Test("Yield fee keeps the buffered send estimate when the module is up to date")
    func yieldFeeKeepsBufferedSendEstimateWithoutUpgrade() async throws {
        let sut = makeSUT(gasLimitResults: [
            .success(100_000),
            .success(50_000),
            .success(60_000),
        ])
        sut.wallet.add(amount: Self.suppliedTokenAmount)

        let fee = try await sut.getGaslessYieldFee(
            feeToken: Self.feeToken,
            amount: Self.transferAmountFromSendScreen,
            destination: Self.destinationAddress,
            feeRecipientAddress: Self.feeRecipientAddress,
            nativeToFeeTokenRate: 1,
            yieldFeeOptions: Self.yieldFeeOptions
        )

        let parameters = try #require(fee.parameters as? EthereumGaslessTransactionFeeParameters)
        let yieldWithdraw = try #require(parameters.yieldWithdraw)

        #expect(parameters.callGasLimit == 140_000)
        #expect(parameters.feeTokenTransferGasLimit == 55_000)
        #expect(yieldWithdraw.withdrawGasLimit == 84_000)
        #expect(sut.gasLimitRequests.count == 3)
    }

    @Test("Transaction payload keeps a plain transfer for a token that is not supplied")
    func transactionPayloadKeepsPlainTransferForNotSuppliedToken() async throws {
        let sut = makeSUT(gasLimitResults: [])

        let payload = try await sut.buildTransactionPayload(transaction: Self.transferTransaction)

        let expected = try TransferERC20TokenMethod(
            destination: Self.destinationAddress,
            amount: Self.transferAmountInTokenUnits
        )

        #expect(payload.destinationAddress == Self.feeToken.contractAddress)
        #expect(payload.data == expected.data)
    }
}

private extension GaslessYieldFeeTests {
    static let walletAddress = "0x0000000000000000000000000000000000000001"
    static let feeRecipientAddress = "0x0000000000000000000000000000000000000002"

    static let feeToken = Token(
        name: "USDT",
        symbol: "USDT",
        contractAddress: "0x0000000000000000000000000000000000000003",
        decimalCount: 6,
        id: Blockchain.polygon(testnet: false).coinId
    )

    static let yieldFeeOptions = GaslessYieldFeeOptions(
        yieldContractAddress: "0x0000000000000000000000000000000000000004",
        upgrade: .none
    )

    static let upgradeImplementation = "0x0000000000000000000000000000000000000005"

    static let upgradeYieldFeeOptions = GaslessYieldFeeOptions(
        yieldContractAddress: yieldFeeOptions.yieldContractAddress,
        upgrade: .required(implementation: upgradeImplementation)
    )

    static let destinationAddress = "0x0000000000000000000000000000000000000006"
    static let transferAmount = Decimal(1)
    static let transferAmountInTokenUnits = BigUInt(1_000_000)

    /// The amount as the send screen builds it, from the token item and without any yield supply metadata.
    static let transferAmountFromSendScreen = Amount(
        with: .polygon(testnet: false),
        type: .token(value: feeToken),
        value: transferAmount
    )

    /// The same token as it comes back from the balance loader: enrolled into yield, so the balance lives on the
    /// module and not on the account.
    static let suppliedToken = Token(
        name: feeToken.name,
        symbol: feeToken.symbol,
        contractAddress: feeToken.contractAddress,
        decimalCount: feeToken.decimalCount,
        id: feeToken.id,
        metadata: TokenMetadata(
            kind: .fungible,
            yieldSupply: TokenYieldSupply(
                yieldContractAddress: yieldFeeOptions.yieldContractAddress,
                isActive: true,
                isInitialized: true,
                allowance: "0",
                protocolBalanceValue: 10
            )
        )
    )

    static let suppliedTokenAmount = Amount(
        with: .polygon(testnet: false),
        type: .token(value: suppliedToken),
        value: 10
    )

    static var transferTransaction: Transaction {
        Transaction(
            amount: transferAmountFromSendScreen,
            fee: Fee(
                Amount(with: .polygon(testnet: false), value: 0),
                parameters: EthereumEIP1559FeeParameters(gasLimit: 21_000, baseFee: 1, priorityFee: 1)
            ),
            sourceAddress: walletAddress,
            destinationAddress: destinationAddress,
            changeAddress: walletAddress,
            params: EthereumTransactionParams(nonce: 0)
        )
    }

    func makeSUT(gasLimitResults: [Result<BigUInt, Error>]) -> StubEthereumWalletManager {
        let wallet = Wallet(
            blockchain: .polygon(testnet: false),
            publicKey: .empty,
            addressesProvider: CommonAddressesProvider(
                defaultAddress: PlainAddress(value: Self.walletAddress, type: .default)
            )
        )

        let networkService = StubEthereumNetworkService()
        return StubEthereumWalletManager(
            wallet: wallet,
            addressConverter: IdentityEthereumAddressConverter(),
            txBuilder: CommonEthereumTransactionBuilder(chainId: 137, sourceAddress: wallet.defaultAddress),
            networkService: networkService,
            pendingTransactionsManager: StubEthereumPendingTransactionsManager(),
            gasLimitResults: gasLimitResults
        )
    }
}

private final class StubEthereumWalletManager: EthereumWalletManager {
    struct GasLimitRequest {
        let to: String
        let data: String?
    }

    private(set) var gasLimitRequests: [GasLimitRequest] = []
    private var gasLimitResults: [Result<BigUInt, Error>]

    init(
        wallet: Wallet,
        addressConverter: EthereumAddressConverter,
        txBuilder: EthereumTransactionBuilder,
        networkService: EthereumNetworkService,
        pendingTransactionsManager: EthereumPendingTransactionsManager,
        gasLimitResults: [Result<BigUInt, Error>]
    ) {
        self.gasLimitResults = gasLimitResults

        super.init(
            wallet: wallet,
            addressConverter: addressConverter,
            txBuilder: txBuilder,
            networkService: networkService,
            pendingTransactionsManager: pendingTransactionsManager,
            isGaslessYieldEnabled: true
        )
    }

    override func getGasLimit(to: String, from: String, value: String?, data: String?) -> AnyPublisher<BigUInt, Error> {
        gasLimitRequests.append(GasLimitRequest(to: to, data: data))

        guard !gasLimitResults.isEmpty else {
            return Fail(error: BlockchainSdkError.failedToGetFee).eraseToAnyPublisher()
        }

        return gasLimitResults.removeFirst().publisher.eraseToAnyPublisher()
    }

    override func getFee(
        destination: String,
        value: String?,
        data: Data?,
        stateOverride: EthereumStateOverride? = nil
    ) -> AnyPublisher<[Fee], Error> {
        getGasLimit(
            to: destination,
            from: wallet.defaultAddress.value,
            value: value,
            data: data?.hex().addHexPrefix()
        )
        .map { [wallet] gasLimit in
            [
                Self.makeFee(gasLimit: gasLimit, wallet: wallet),
                Self.makeFee(gasLimit: gasLimit, wallet: wallet),
                Self.makeFee(gasLimit: gasLimit, wallet: wallet),
            ]
        }
        .eraseToAnyPublisher()
    }

    private static func makeFee(gasLimit: BigUInt, wallet: Wallet) -> Fee {
        let parameters = EthereumEIP1559FeeParameters(gasLimit: gasLimit, baseFee: 1, priorityFee: 1)
        return Fee(
            Amount(with: wallet.blockchain, value: parameters.calculateFee(decimalValue: wallet.blockchain.decimalValue)),
            parameters: parameters
        )
    }
}

private final class StubEthereumNetworkService: EthereumNetworkService {
    init() {
        super.init(
            decimals: 18,
            providers: [],
            abiEncoder: WalletCoreABIEncoder(),
            blockchainName: "Polygon"
        )
    }

    override func getFeeHistory() -> AnyPublisher<EthereumFeeHistory, Error> {
        Just(EthereumFeeHistory(
            baseFee: 1,
            lowBaseFee: 1,
            marketBaseFee: 1,
            fastBaseFee: 1,
            lowPriorityFee: 1,
            marketPriorityFee: 1,
            fastPriorityFee: 1
        ))
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    }
}

private final class StubEthereumPendingTransactionsManager: EthereumPendingTransactionsManager {
    var pendingTransactionsPublisher: AnyPublisher<[PendingTransactionRecord], Never> {
        Just([]).eraseToAnyPublisher()
    }

    func syncPendingTransactions() async throws {}
    func addTransactions(_ transactions: [Transaction], hashes: [String]) {}
}
