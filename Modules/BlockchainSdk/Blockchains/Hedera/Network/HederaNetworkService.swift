//
//  HederaNetworkService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BigInt

final class HederaNetworkService {
    var currentProviderIndex: Int
    let blockchainName: String = Blockchain.hedera(curve: .ed25519_slip0010, testnet: false).displayName

    private let consensusProvider: HederaConsensusNetworkProvider
    private let restProviders: [HederaRESTNetworkProvider]

    init(
        consensusProvider: HederaConsensusNetworkProvider,
        restProviders: [HederaRESTNetworkProvider]
    ) {
        self.consensusProvider = consensusProvider
        self.restProviders = restProviders
        currentProviderIndex = 0
    }

    func getAccountInfo(publicKey: Data) -> some Publisher<HederaAccountInfo, Error> {
        return providerPublisher { provider in
            return provider
                .getAccounts(publicKey: publicKey.hex())
                .eraseToAnyPublisher()
        }
        .tryMap { accounts in
            // `MultiNetworkProvider` must not switch on `HederaError.accountDoesNotExist`,
            // therefore we are performing DTO->Domain mapping outside the `providerPublisher`
            switch accounts.accounts.count {
            case 0:
                throw HederaError.accountDoesNotExist
            case 1:
                let account = accounts.accounts[0]

                // Account ID is the only essential piece of information for a particular account,
                // account alias and account EVM address may not exist at all
                guard let accountId = account.account else {
                    throw HederaError.accountDoesNotExist
                }

                return HederaAccountInfo(accountId: accountId, alias: account.alias, evmAddress: account.evmAddress)
            default:
                throw HederaError.multipleAccountsFound
            }
        }
    }

    func getAccountInfo(address: String) -> some Publisher<HederaAccountInfo, Error> {
        return providerPublisher { provider in
            provider.getAccount(idOrAliasOrEvmAddress: address)
                .eraseToAnyPublisher()
        }
        .tryMap { accountInfo in
            guard let accountId = accountInfo.account else {
                throw HederaError.accountDoesNotExist
            }

            return HederaAccountInfo(
                accountId: accountId,
                alias: accountInfo.alias,
                evmAddress: accountInfo.evmAddress
            )
        }
    }

    func getContractId(evmAddress: String) -> some Publisher<String, Error> {
        return providerPublisher { provider in
            provider.getContract(idOrAliasOrEvmAddress: evmAddress)
                .eraseToAnyPublisher()
        }
        .tryMap { contractInfo in
            guard let contractId = contractInfo.contractId else {
                throw HederaError.contractCallResultNotFound
            }

            return contractId
        }
    }

    /// - Note: For balances fetching, the Mirror Node acts as a primary node, and the Consensus Node is a backup one.
    func getBalance(accountId: String) -> some Publisher<HederaAccountBalance, Error> {
        let fallbackPublisher = makeFallbackBalancePublisher(accountId: accountId)
        let hbarBalancePublisher = makeHbarBalancePublisher(accountId: accountId)
        let tokenBalancesPublisher = makeTokenBalancesPublisher(accountId: accountId)

        return hbarBalancePublisher
            .zip(tokenBalancesPublisher)
            .map { hbarBalance, tokenBalances in
                return HederaAccountBalance(
                    hbarBalance: hbarBalance,
                    tokenBalances: Self.mapTokenBalances(tokenBalances.tokens)
                )
            }
            .catch { _ in
                return fallbackPublisher
            }
    }

    func getExchangeRate() -> some Publisher<HederaExchangeRate, Error> {
        return providerPublisher { provider in
            return provider
                .getExchangeRates()
                .map { exchangeRate in
                    let currentRate = Constants.centsPerDollar
                        * Decimal(exchangeRate.currentRate.hbarEquivalent)
                        / Decimal(exchangeRate.currentRate.centEquivalent)

                    let nextRate = Constants.centsPerDollar
                        * Decimal(exchangeRate.nextRate.hbarEquivalent)
                        / Decimal(exchangeRate.nextRate.centEquivalent)

                    return HederaExchangeRate(currentHBARPerUSD: currentRate, nextHBARPerUSD: nextRate)
                }
                .eraseToAnyPublisher()
        }
    }

    func send(transaction: HederaTransactionBuilder.CompiledTransaction) -> some Publisher<TransactionSendResult, Error> {
        return consensusProvider
            .send(transaction: transaction)
            .withWeakCaptureOf(self)
            .map { service, hash in
                TransactionSendResult(hash: hash, currentProviderHost: service.host)
            }
    }

    /// Expects `transactionHash` in a format suitable for Hedera Consensus node (like `0.0.3573746@1714034073.123382080`).
    /// - Note: Hedera Mirror node uses a slightly different format of TX ids, so the conversion between
    /// Consensus and Mirror formats is performed using `HederaTransactionIdConverter`.
    func getTransactionInfo(transactionHash: String) -> some Publisher<HederaTransactionInfo, Error> {
        let fallbackTransactionInfoPublisher = makeFallbackTransactionInfoPublisher(transactionHash: transactionHash)
        let converter = HederaTransactionIdConverter()

        return Deferred {
            return Future { promise in
                let result = Result { try converter.convertFromConsensusToMirror(transactionHash) }
                promise(result)
            }
        }
        .withWeakCaptureOf(self)
        .flatMap { networkService, mirrorNodeTransactionHash in
            return networkService.providerPublisher { provider in
                return provider
                    .getTransactionInfo(transactionHash: mirrorNodeTransactionHash)
                    .eraseToAnyPublisher()
            }
            .map { ($0, mirrorNodeTransactionHash) }
        }
        .tryMap { transactionInfos, mirrorNodeTransactionHash in
            guard let transactionInfo = transactionInfos
                .transactions
                .first(where: { $0.transactionId == mirrorNodeTransactionHash })
            else {
                throw HederaError.transactionNotFound
            }

            return transactionInfo
        }
        .tryMap { transactionInfo in
            let consensusNodeTransactionHash = try converter.convertFromMirrorToConsensus(transactionInfo.transactionId)
            let isPending: Bool

            // API schema doesn't list all possible values for the `transactionInfo.result` field,
            // so raw string matching is used instead
            switch transactionInfo.result {
            case "OK":
                // Precheck validations (`Status.ok`) performed locally
                isPending = true
            default:
                // All other transaction statuses mean either success of failure
                isPending = false
            }

            return HederaTransactionInfo(isPending: isPending, transactionHash: consensusNodeTransactionHash)
        }
        .catch { _ in
            return fallbackTransactionInfoPublisher
        }
    }

    func getTokensCustomFeesInfo(tokenAddress: String) -> some Publisher<HederaTokenCustomFeesInfo, Error> {
        providerPublisher { provider in
            provider.getTokensDetails(tokenAddress: tokenAddress)
                .tryMap { tokenDetails in
                    let customFees = tokenDetails.customFees

                    guard !customFees.fixedFees.contains(where: { customFee in
                        customFee.denominatingTokenId != nil && customFee.denominatingTokenId != tokenAddress
                    }) else {
                        throw HederaError.fixedFeeInAnotherToken
                    }

                    let hasTokenCustomFees = !customFees.fixedFees.isEmpty || !customFees.fractionalFees.isEmpty

                    let additionalHBARFee = customFees.fixedFees.reduce(into: Decimal.zero) { result, customFee in
                        if customFee.denominatingTokenId == nil {
                            result += customFee.amount ?? .zero
                        }
                    }

                    return HederaTokenCustomFeesInfo(
                        hasTokenCustomFees: hasTokenCustomFees,
                        additionalHBARFee: additionalHBARFee
                    )
                }
                .eraseToAnyPublisher()
        }
    }

    func getERC20Balance(
        accountId: String,
        tokenContractAddress: String,
        tokenDecimals: Int
    ) -> some Publisher<Decimal, Error> {
        let converter = HederaTokenContractAddressConverter()

        return Deferred {
            Future { promise in
                do {
                    let sourceEVMAddress = try converter.convertFromHederaToEVM(accountId)
                    let method = TokenBalanceERC20TokenMethod(owner: sourceEVMAddress.removeHexPrefix())
                    promise(.success(method.encodedData))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .withWeakCaptureOf(self)
        .flatMap { service, encodedData in
            service.providerPublisher { provider in
                provider.invokeContract(
                    from: nil,
                    to: tokenContractAddress,
                    data: encodedData,
                    estimate: nil
                )
                .eraseToAnyPublisher()
            }
        }
        .tryMap { contractCallResult in
            guard let result = contractCallResult.result else {
                throw HederaError.contractCallResultNotFound
            }

            guard let balance = EthereumUtils.parseEthereumDecimal(result, decimalsCount: tokenDecimals) else {
                throw HederaError.contractCallResultIsInvalid
            }

            return balance
        }
    }

    func estimateERC20Transfer(
        sourceAccountId: String,
        destinationAddress: String,
        tokenContractAddress: String,
        amount: Amount
    ) -> some Publisher<(gasLimit: UInt64, recipientEVMAddress: String), Error> {
        let converter = HederaTokenContractAddressConverter()

        return getAccountInfo(address: destinationAddress)
            .tryMap { accountInfo -> String in
                guard let recipientEVMAddress = accountInfo.evmAddress, !recipientEVMAddress.isEmpty else {
                    throw HederaError.accountEVMAddressNotFound
                }

                return recipientEVMAddress
            }
            .tryMap { recipientEVMAddress -> (encodedData: String, sourceEVMAddress: String, recipientEVMAddress: String) in
                guard let amountValue = amount.bigUIntValue else {
                    throw HederaError.contractCallResultIsInvalid
                }

                let sourceEVMAddress = try converter.convertFromHederaToEVM(sourceAccountId)
                let method = TransferERC20TokenMethod(
                    destination: recipientEVMAddress.removeHexPrefix(),
                    amount: amountValue
                )
                return (method.encodedData, sourceEVMAddress, recipientEVMAddress)
            }
            .withWeakCaptureOf(self)
            .flatMap { service, payload in
                let (encodedData, sourceEVMAddress, recipientEVMAddress) = payload
                return service.providerPublisher { provider in
                    provider.invokeContract(
                        from: sourceEVMAddress,
                        to: tokenContractAddress,
                        data: encodedData,
                        estimate: true
                    )
                    .eraseToAnyPublisher()
                }
                .map { ($0, recipientEVMAddress) }
            }
            .tryMap { contractCallResult, recipientEVMAddress in
                guard let result = contractCallResult.result else {
                    throw HederaError.contractCallResultNotFound
                }

                let gasLimit = try Self.parseHexUInt64(result)
                return (gasLimit: gasLimit, recipientEVMAddress: recipientEVMAddress)
            }
    }

    func getERC20GasPrice() -> some Publisher<UInt64, Error> {
        providerPublisher { provider in
            provider.getNetworkFees()
                .eraseToAnyPublisher()
        }
        .tryMap { networkFees in
            guard
                let contractCallFee = networkFees.fees.first(where: {
                    $0.transactionType.caseInsensitiveCompare(Constants.contractCallTransactionType) == .orderedSame
                }),
                let gas = contractCallFee.gas,
                gas >= 0
            else {
                throw HederaError.contractCallGasPriceNotFound
            }

            return UInt64(gas)
        }
    }

    /// - Note: For Hbar tx status fetching, the Mirror Node acts as a primary node, and the Consensus Node is a backup one.
    private func makeFallbackTransactionInfoPublisher(transactionHash: String) -> some Publisher<HederaTransactionInfo, Error> {
        return consensusProvider
            .getTransactionInfo(transactionHash: transactionHash)
            .map { transactionInfo in
                let isPending: Bool

                switch transactionInfo.status {
                case .ok:
                    // Precheck validations (`Status.ok`) performed locally
                    isPending = true
                default:
                    // All other transaction statuses mean either success of failure
                    isPending = false
                }

                return HederaTransactionInfo(isPending: isPending, transactionHash: transactionInfo.hash)
            }
    }

    private func makeHbarBalancePublisher(accountId: String) -> some Publisher<Int, Error> {
        return providerPublisher { provider in
            return provider
                .getBalance(accountId: accountId)
                .eraseToAnyPublisher()
        }
        .tryMap { accountBalance in
            guard let balance = accountBalance.balances.first(where: { $0.account == accountId }) else {
                throw HederaError.accountBalanceNotFound
            }

            return balance.balance
        }
    }

    private func makeTokenBalancesPublisher(accountId: String) -> some Publisher<HederaNetworkResult.AccountTokensBalance, Error> {
        return providerPublisher { provider in
            return provider
                .getTokens(accountId: accountId, entitiesLimit: Constants.tokenEntitiesLimit)
                .eraseToAnyPublisher()
        }
    }

    private func makeFallbackBalancePublisher(accountId: String) -> some Publisher<HederaAccountBalance, Error> {
        return consensusProvider
            .getBalance(accountId: accountId)
            .tryMap { balanceInfo in
                guard let hbarBalance = balanceInfo.hbarBalance.balances.first(where: { $0.account == accountId }) else {
                    throw HederaError.accountBalanceNotFound
                }

                return HederaAccountBalance(
                    hbarBalance: hbarBalance.balance,
                    tokenBalances: Self.mapTokenBalances(balanceInfo.tokensBalance.tokens)
                )
            }
    }

    private static func mapTokenBalances(
        _ tokenBalances: [HederaNetworkResult.AccountTokensBalance.Token]
    ) -> [HederaAccountBalance.TokenBalance] {
        return tokenBalances.map { tokenBalance in
            return HederaAccountBalance.TokenBalance(
                contractAddress: tokenBalance.tokenId,
                balance: tokenBalance.balance,
                decimalCount: tokenBalance.decimals
            )
        }
    }

    private static func parseHexUInt64(_ value: String) throws -> UInt64 {
        let hexString = value.removeHexPrefix()

        guard let parsed = BigUInt(hexString, radix: 16), parsed <= BigUInt(UInt64.max) else {
            throw HederaError.contractCallResultIsInvalid
        }

        return UInt64(parsed)
    }
}

// MARK: - MultiNetworkProvider protocol conformance

extension HederaNetworkService: MultiNetworkProvider {
    var providers: [HederaRESTNetworkProvider] { restProviders }
}

// MARK: - Constants

private extension HederaNetworkService {
    enum Constants {
        static let centsPerDollar = Decimal(100)
        static let hederaNetworkId = "hedera"
        /// Arkhia.io's free plan currently has a limit of 200 entities per single request (value found by trial and error,
        /// as there is no mention of such a limit in their docs), so this constant is limited to that limit.
        /// Still well enough for our needs, 200 unique tokens per unique Hedera account.
        static let tokenEntitiesLimit = 200
        static let contractCallTransactionType = "CONTRACTCALL"
    }
}
