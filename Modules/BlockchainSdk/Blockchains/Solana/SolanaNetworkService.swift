//
//  SolanaNetworkService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SolanaSwift
import TangemFoundation
import TangemNetworkUtils
import TangemSdk

public final class SolanaNetworkService: MultiNetworkProvider {
    let providers: [RPCEndpoint]
    var currentProviderIndex: Int = 0
    var isSolanaScaledUIEnabled: Bool = false
    var blockchainName: String {
        blockchain.displayName
    }

    private let solanaSdk: Solana
    private let blockchain: Blockchain
    private let networkProvider: TangemProvider<SolanaScaledUiAmountTarget>

    init(
        providers: [RPCEndpoint],
        solanaSdk: Solana,
        blockchain: Blockchain,
        providerConfiguration: TangemProviderConfiguration
    ) {
        self.providers = providers
        self.solanaSdk = solanaSdk
        self.blockchain = blockchain
        networkProvider = .init(configuration: providerConfiguration)
    }

    func getInfo(accountId: String, tokens: [Token]) -> AnyPublisher<SolanaAccountInfoResponse, Error> {
        let mints = Set(tokens.map(\.contractAddress))

        return accountInfoWithTokenAccounts(accountId: accountId)
            .map { response in
                let filteredTokensByMint = response.tokensByMint.filter { mints.contains($0.key) }

                return SolanaAccountInfoResponse(
                    balance: response.balance,
                    accountExists: response.accountExists,
                    tokensByMint: filteredTokensByMint,
                    mainAccountRentExemption: response.mainAccountRentExemption
                )
            }
            .eraseToAnyPublisher()
    }

    func getInitialWalletInfo(accountId: String) -> AnyPublisher<SolanaInitialWalletInfoResponse, Error> {
        accountInfoWithTokenAccounts(accountId: accountId)
            .map { response in
                return SolanaInitialWalletInfoResponse(
                    mainBalance: response.balance,
                    tokenBalancesByMint: response.tokensByMint
                )
            }
            .eraseToAnyPublisher()
    }

    func getFee(amount: Amount, destination: String, publicKey: PublicKey) -> AnyPublisher<Fee, Error> {
        checkAccountExists(amount: amount, destination: destination)
            .withWeakCaptureOf(self)
            .flatMap { service, accountExists in
                let feeParameters = SolanaNetworkService.mapFeeParameters(accountExists: accountExists)
                let decimalValue: Decimal = pow(10, amount.decimals)
                let intAmount = (amount.value * decimalValue).rounded().uint64Value

                return service.getFeeForMessage(
                    amount: intAmount,
                    computeUnitLimit: feeParameters.computeUnitLimit,
                    computeUnitPrice: feeParameters.computeUnitPrice,
                    destinationAddress: destination,
                    fromPublicKey: publicKey
                )
                .map { feeValue in
                    let feeAmount = Amount(with: service.blockchain, type: .coin, value: feeValue)
                    return Fee(feeAmount, parameters: feeParameters)
                }
            }
            .eraseToAnyPublisher()
    }

    func checkAccountExists(amount: Amount, destination: String) -> AnyPublisher<Bool, Error> {
        switch amount.type {
        case .coin, .feeResource, .reserve:
            return solanaSdk.api.getAccountInfo(account: destination, decodedTo: AccountInfo.self)
                .map { _ in return true }
                .tryCatch { error -> AnyPublisher<Bool, Error> in
                    if let solanaError = error as? SolanaError {
                        switch solanaError {
                        case .nullValue:
                            return .justWithError(output: false)
                        default:
                            break
                        }
                    }

                    throw error
                }
                .eraseToAnyPublisher()
        case .token(let token):
            return Publishers.Zip(
                checkIfSolanaAccount(destinationAddress: destination),
                tokenProgramId(contractAddress: token.contractAddress)
            )
            .withWeakCaptureOf(self)
            .flatMap { service, params in
                service.solanaSdk.action.checkTokenAddressExists(
                    mintAddress: token.contractAddress,
                    tokenProgramId: params.1,
                    destinationAddress: destination,
                    allowUnfundedRecipient: params.0
                )
            }
            .eraseToAnyPublisher()
        }
    }

    func sendSol(
        amount: UInt64,
        computeUnitLimit: UInt32?,
        computeUnitPrice: UInt64?,
        destinationAddress: String,
        signer: SolanaTransactionSigner
    ) -> AnyPublisher<TransactionID, Error> {
        solanaSdk.action.sendSOL(
            to: destinationAddress,
            amount: amount,
            computeUnitLimit: computeUnitLimit,
            computeUnitPrice: computeUnitPrice,
            allowUnfundedRecipient: true,
            signer: signer
        )
        .mapError(Self.mapRPCErrorIfPossible)
        .eraseToAnyPublisher()
    }

    func sendRaw(
        base64serializedTransaction: String,
        startSendingTimestamp: Date
    ) -> AnyPublisher<TransactionID, Error> {
        solanaSdk.api.sendTransaction(
            serializedTransaction: base64serializedTransaction,
            startSendingTimestamp: startSendingTimestamp
        )
        .mapError(Self.mapRPCErrorIfPossible)
        .eraseToAnyPublisher()
    }

    func sendSplToken(amount: UInt64, computeUnitLimit: UInt32?, computeUnitPrice: UInt64?, sourceTokenAddress: String, destinationAddress: String, token: Token, tokenProgramId: PublicKey, signer: SolanaTransactionSigner) -> AnyPublisher<TransactionID, Error> {
        checkIfSolanaAccount(destinationAddress: destinationAddress)
            .withWeakCaptureOf(self)
            .flatMap { service, isSolanaAccount in
                service.solanaSdk.action.sendSPLTokens(
                    mintAddress: token.contractAddress,
                    tokenProgramId: tokenProgramId,
                    decimals: Decimals(token.decimalCount),
                    from: sourceTokenAddress,
                    to: destinationAddress,
                    amount: amount,
                    computeUnitLimit: computeUnitLimit,
                    computeUnitPrice: computeUnitPrice,
                    allowUnfundedRecipient: isSolanaAccount,
                    signer: signer
                )
            }
            .mapError(Self.mapRPCErrorIfPossible)
            .eraseToAnyPublisher()
    }

    func transactionFee(numberOfSignatures: Int) -> AnyPublisher<Decimal, Error> {
        solanaSdk.api.getFees(commitment: nil)
            .tryMap { [weak self] fee in
                guard let self = self else {
                    throw BlockchainSdkError.empty
                }

                guard let lamportsPerSignature = fee.feeCalculator?.lamportsPerSignature else {
                    throw BlockchainSdkError.failedToLoadFee
                }

                return Decimal(lamportsPerSignature) * Decimal(numberOfSignatures) / blockchain.decimalValue
            }
            .eraseToAnyPublisher()
    }

    func accountRentFeePerEpoch() -> AnyPublisher<Decimal, Error> {
        // https://docs.solana.com/developing/programming-model/accounts#calculation-of-rent
        let minimumAccountSizeInBytes = Decimal(128)
        let numberOfEpochs = Decimal(1)

        let rentInLamportPerByteEpoch: Decimal
        if blockchain.isTestnet {
            // Solana Testnet uses the same value as Mainnet.
            // The following value is for DEVNET. It is not mentioned in the docs and was obtained empirically.
            rentInLamportPerByteEpoch = Decimal(0.359375)
        } else {
            rentInLamportPerByteEpoch = Decimal(19.055441478439427)
        }
        let lamportsInSol = blockchain.decimalValue

        let rent = minimumAccountSizeInBytes * numberOfEpochs * rentInLamportPerByteEpoch / lamportsInSol

        return Just(rent).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func minimalBalanceForRentExemption(dataLength: UInt64 = 0) -> AnyPublisher<Decimal, Error> {
        // The accounts metadata size (128) is already factored in
        solanaSdk.api.getMinimumBalanceForRentExemption(dataLength: dataLength)
            .tryMap { [weak self] balanceInLamports in
                guard let self = self else {
                    throw BlockchainSdkError.empty
                }

                return Decimal(balanceInLamports) / blockchain.decimalValue
            }
            .eraseToAnyPublisher()
    }

    func tokenProgramId(contractAddress: String) -> AnyPublisher<PublicKey, Error> {
        solanaSdk.api.getAccountInfo(account: contractAddress, decodedTo: AccountInfo.self)
            .tryMap { accountInfo in
                let tokenProgramIds: [PublicKey] = [
                    .tokenProgramId,
                    .token2022ProgramId,
                ]

                for tokenProgramId in tokenProgramIds {
                    if tokenProgramId.base58EncodedString == accountInfo.owner {
                        return tokenProgramId
                    }
                }
                throw BlockchainSdkError.failedToConvertPublicKey
            }
            .eraseToAnyPublisher()
    }

    func getScaledUiAmountMultiplier(
        mintAddress: String,
        transactionDate: Date
    ) -> AnyPublisher<Decimal?, Error> {
        providerPublisher { [weak self] provider in
            guard let self else {
                return .anyFail(error: BlockchainSdkError.empty)
            }

            let target = SolanaScaledUiAmountTarget(
                endpoint: provider,
                request: .getAccountInfo(mintAddress: mintAddress)
            )

            return networkProvider.requestPublisher(target)
                .filterSuccessfulStatusAndRedirectCodes()
                .map(JSONRPC.Response<SolanaScaledUiAmountDTO.GetAccountInfoResult, JSONRPC.APIError>.self)
                .tryMap { response in
                    let accountInfo = try response.result.get()
                    return self.selectScaledUiAmountMultiplier(
                        from: accountInfo,
                        transactionDate: transactionDate
                    )
                }
                .eraseToAnyPublisher()
        }
    }

    func getAddressLookupTable(accountKey: PublicKey) async throws -> AddressLookupTableAccount {
        let maxAttempts = 15
        let delay: UInt64 = 1_500_000_000 // 1.5 second

        for attempt in 1 ... maxAttempts {
            do {
                let alt = try await solanaSdk.api.getAddressLookupTable(accountKey: accountKey)
                return alt
            } catch {
                if attempt == maxAttempts {
                    throw error
                }

                BSDKLogger.warning("ALT: getAddressLookupTable failed, attempt \(attempt)/\(maxAttempts), retrying...")
                try await Task.sleep(nanoseconds: delay)
            }
        }

        throw SolanaError.nullValue
    }

    func getLatestBlockhash() async throws -> String {
        try await solanaSdk.api.getLatestBlockhash()
    }

    func getSlot() async throws -> UInt64 {
        try await solanaSdk.api.getSlot()
    }

    func getFeeForCompiled(message: String) -> AnyPublisher<Decimal, Error> {
        solanaSdk.api
            .getFeeForMessage(message)
            .map { [blockchain] in
                Decimal($0.value) / blockchain.decimalValue
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Private Implementation

    private func getFeeForMessage(
        amount: UInt64,
        computeUnitLimit: UInt32?,
        computeUnitPrice: UInt64?,
        destinationAddress: String,
        fromPublicKey: PublicKey
    ) -> AnyPublisher<Decimal, Error> {
        solanaSdk.action.serializeMessage(
            to: destinationAddress,
            amount: amount,
            computeUnitLimit: computeUnitLimit,
            computeUnitPrice: computeUnitPrice,
            allowUnfundedRecipient: true,
            allowCompoundRecipient: true,
            fromPublicKey: fromPublicKey
        )
        .flatMap { [solanaSdk] message, _ -> AnyPublisher<FeeForMessageResult, Error> in
            solanaSdk.api.getFeeForMessage(message)
        }
        .map { [blockchain] in
            Decimal($0.value) / blockchain.decimalValue
        }
        .eraseToAnyPublisher()
    }

    private func mainAccountInfo(accountId: String) -> AnyPublisher<SolanaMainAccountInfoResponse, Error> {
        solanaSdk.api.getAccountInfo(account: accountId, decodedTo: AccountInfo.self)
            .withWeakCaptureOf(self)
            .flatMap { service, info in
                service.minimalBalanceForRentExemption(dataLength: info.space ?? 0)
                    .map { rentExemption in
                        let lamports = info.lamports
                        let accountInfo = SolanaMainAccountInfoResponse(
                            balance: lamports,
                            accountExists: true,
                            rentExemption: rentExemption
                        )
                        return accountInfo
                    }
            }
            .tryCatch { (error: Error) -> AnyPublisher<SolanaMainAccountInfoResponse, Error> in
                if let solanaError = error as? SolanaError {
                    switch solanaError {
                    case .nullValue:
                        let info = SolanaMainAccountInfoResponse(balance: 0, accountExists: false, rentExemption: 0)
                        return Just(info)
                            .setFailureType(to: Error.self)
                            .eraseToAnyPublisher()
                    default:
                        break
                    }
                }

                throw error
            }.eraseToAnyPublisher()
    }

    private func tokenAccountsInfo(accountId: String, programId: PublicKey) -> AnyPublisher<[TokenAccount<AccountInfoData>], Error> {
        let configs = RequestConfiguration(commitment: "recent", encoding: "jsonParsed")

        return solanaSdk.api.getTokenAccountsByOwner(pubkey: accountId, programId: programId.base58EncodedString, configs: configs)
            .eraseToAnyPublisher()
    }

    private func accountInfoWithTokenAccounts(accountId: String) -> AnyPublisher<SolanaAccountInfoResponse, Error> {
        Publishers.Zip3(
            mainAccountInfo(accountId: accountId),
            tokenAccountsInfo(accountId: accountId, programId: .tokenProgramId),
            tokenAccountsInfo(accountId: accountId, programId: .token2022ProgramId)
        )
        .tryMap { [weak self] mainAccount, splTokenAccounts, token2022Accounts in
            guard let self else {
                throw BlockchainSdkError.empty
            }

            return mapInfo(
                mainAccountInfo: mainAccount,
                tokenAccountsInfo: splTokenAccounts + token2022Accounts
            )
        }
        .eraseToAnyPublisher()
    }

    private func mapInfo(
        mainAccountInfo: SolanaMainAccountInfoResponse,
        tokenAccountsInfo: [TokenAccount<AccountInfoData>]
    ) -> SolanaAccountInfoResponse {
        let balance = (Decimal(mainAccountInfo.balance) / blockchain.decimalValue).rounded(blockchain: blockchain)
        let accountExists = mainAccountInfo.accountExists

        let tokenInfoResponses: [SolanaTokenAccountInfoResponse] = tokenAccountsInfo.compactMap {
            guard
                let info = $0.account.data.value?.parsed.info
            else {
                return nil
            }

            let address = $0.pubkey
            let mint = info.mint

            let isToken2022 = $0.account.owner == PublicKey.token2022ProgramId.base58EncodedString
            let shouldUseScaledUiAmount = isToken2022 && isSolanaScaledUIEnabled
            let decimalCount = Int(info.tokenAmount.decimals)
            guard let amount = tokenBalance(
                from: info.tokenAmount,
                decimalCount: decimalCount,
                useUiAmount: shouldUseScaledUiAmount
            ) else {
                return nil
            }

            return SolanaTokenAccountInfoResponse(address: address, mint: mint, balance: amount, space: $0.account.space)
        }

        let tokenPairs = tokenInfoResponses.map { ($0.mint, $0) }
        let tokensByMint = Dictionary(tokenPairs) { token1, _ in
            return token1
        }

        return SolanaAccountInfoResponse(
            balance: balance,
            accountExists: accountExists,
            tokensByMint: tokensByMint,
            mainAccountRentExemption: mainAccountInfo.rentExemption
        )
    }

    /// Destination account checker
    /// - Parameter destinationAddress: destinationAddress to check
    /// - Returns: true if this address is solana base account, false if it is derived token account.
    /// - throws error if the account is not registered yet
    private func checkIfSolanaAccount(destinationAddress: String) -> AnyPublisher<Bool, Error> {
        solanaSdk.api.getAccountInfo(account: destinationAddress, decodedTo: AccountInfo.self)
            .tryMap { accountInfo in
                if accountInfo.owner == PublicKey.programId.base58EncodedString {
                    return true
                } else {
                    return false
                }
            }
            .tryCatch { error -> AnyPublisher<Bool, Error> in
                if let solanaError = error as? SolanaError {
                    switch solanaError {
                    case .nullValue:
                        return .justWithError(output: true)
                    default:
                        break
                    }
                }

                return .anyFail(error: error)
            }
            .eraseToAnyPublisher()
    }

    private static func mapFeeParameters(accountExists: Bool) -> SolanaFeeParameters {
        let computeUnitLimit: UInt32?
        let computeUnitPrice: UInt64?

        if NFCUtils.isPoorNfcQualityDevice {
            computeUnitLimit = nil
            computeUnitPrice = nil
        } else {
            // https://www.helius.dev/blog/priority-fees-understanding-solanas-transaction-fee-mechanics
            computeUnitLimit = accountExists ? 200_000 : 400_000
            computeUnitPrice = accountExists ? 1_000_000 : 500_000
        }

        return SolanaFeeParameters(
            destinationAccountExists: accountExists,
            computeUnitLimit: computeUnitLimit,
            computeUnitPrice: computeUnitPrice,
        )
    }

    private static func mapRPCErrorIfPossible(_ error: Error) -> Error {
        switch error {
        case RPCError.invalidResponse(let responseError):
            return SolanaError.invalidResponse(responseError)

        case RPCError.httpErrorCode(let statusCode, let description):
            var message = "The operation couldn’t be completed."
                + " This may be due to a temporary network or RPC server issue."
                + " Please try again in a few moments."
                + "\nStatus code: \(statusCode)."

            if let description {
                message.append("Description: \(description)")
            }

            return SolanaError.other(message)

        default:
            return error
        }
    }

    private func tokenBalance(
        from tokenAmount: SolanaSwift.TokenAmount,
        decimalCount: Int,
        useUiAmount: Bool
    ) -> Decimal? {
        let safeDecimalCount = min(max(decimalCount, 0), 38)

        if useUiAmount {
            // For Token-2022 (e.g. scaled UI amount), use node-provided UI amount.
            if let uiAmount = Decimal(stringValue: tokenAmount.uiAmountString) {
                return uiAmount.rounded(scale: safeDecimalCount)
            }

            return Decimal(tokenAmount.uiAmount).rounded(scale: safeDecimalCount)
        } else {
            guard let integerAmount = Decimal(stringValue: tokenAmount.amount) else {
                return nil
            }

            let decimalValue: Decimal = pow(10, safeDecimalCount)
            return (integerAmount / decimalValue).rounded(scale: safeDecimalCount)
        }
    }

    private func selectScaledUiAmountMultiplier(
        from accountInfo: SolanaScaledUiAmountDTO.GetAccountInfoResult,
        transactionDate: Date
    ) -> Decimal? {
        let extensionConfig = accountInfo.value?
            .data?
            .parsed?
            .info?
            .extensions
            .first(where: { $0.extension == "scaledUiAmountConfig" })

        guard let state = extensionConfig?.state else {
            return nil
        }

        let transactionTimestamp = Int64(transactionDate.timeIntervalSince1970)
        let multiplierString: String?

        if let effectiveTimestamp = state.newMultiplierEffectiveTimestamp,
           transactionTimestamp >= effectiveTimestamp {
            multiplierString = state.newMultiplier
        } else {
            multiplierString = state.multiplier
        }

        return Decimal(stringValue: multiplierString)
    }
}
