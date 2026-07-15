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
        #expect(yieldWithdraw.originalGasLimit == 21_000)
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

        #expect(yieldWithdraw.originalGasLimit == 32_000)
        #expect(parameters.feeTokenTransferGasLimit == 55_000)
        #expect(yieldWithdraw.withdrawGasLimit == 84_000)
        #expect(parameters.gasLimit == 32_000 + 55_000 + 84_000 + EthereumFeeParametersConstants.gaslessBaseGasBuffer)
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

    static let upgradeYieldFeeOptions = GaslessYieldFeeOptions(
        yieldContractAddress: yieldFeeOptions.yieldContractAddress,
        upgrade: .required(implementation: "0x0000000000000000000000000000000000000005")
    )

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
