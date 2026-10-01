//
//  HederaWalletManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemFoundation
import struct Hiero.AccountId

final class HederaWalletManager: BaseWalletManager {
    fileprivate typealias AssociatedTokens = Set<String>
    fileprivate typealias TokenMetadata = [String: HederaTokenMetadata]

    private let networkService: HederaNetworkService
    private let transactionBuilder: HederaTransactionBuilder
    private let dataStorage: BlockchainDataStorage
    private let accountCreator: AccountCreator

    /// HBARs per 1 USD
    private var tokenAssociationFeeExchangeRate: Decimal?
    private var associatedTokens: AssociatedTokens?
    private var tokenMetadata: TokenMetadata?
    private var tokenMetadataResolutionTask: Task<Void, Never>?
    private var tokenMetadataStorageTask: Task<Void, Never>?

    private var storageKeySuffix: String {
        return wallet
            .publicKey
            .blockchainKey
            .getSHA256()
            .hex()
    }

    /// Public key as a masked string (only the last four characters are revealed), suitable for use in logs
    private lazy var maskedPublicKey: String = {
        let length = 4
        let publicKey = wallet.publicKey.blockchainKey.hex()

        return publicKey
            .dropLast(length)
            .map { _ in "•" }
            .joined()
            + publicKey.suffix(length)
    }()

    // MARK: - Initialization/Deinitialization

    init(
        wallet: Wallet,
        networkService: HederaNetworkService,
        transactionBuilder: HederaTransactionBuilder,
        accountCreator: AccountCreator,
        dataStorage: BlockchainDataStorage
    ) {
        self.networkService = networkService
        self.transactionBuilder = transactionBuilder
        self.accountCreator = accountCreator
        self.dataStorage = dataStorage
        super.init(wallet: wallet)
    }

    @available(*, unavailable)
    override init(wallet: Wallet) {
        fatalError("\(#function) has not been implemented")
    }

    override func addToken(_ token: Token) {
        guard !cardTokens.contains(token) else {
            return
        }

        super.addToken(token)

        let previousResolutionTask = tokenMetadataResolutionTask
        tokenMetadataResolutionTask = Task { [weak self] in
            await previousResolutionTask?.value
            await self?.resolveTokenMetadata(for: token)
        }
    }

    // MARK: - Wallet update

    func updateWalletManager(address _: String) async throws {
        do {
            await loadCachedAssociatedTokensIfNeeded()
            await tokenMetadataResolutionTask?.value

            let accountId = try await getAccountId().async()

            async let accountBalance = try await networkService.getBalance(accountId: accountId).async()
            async let erc20TokenBalances = try await fetchERC20TokenBalances(accountId: accountId).async()
            async let transactionsInfo = try await makePendingTransactionsInfoPublisher().async()

            let resolvedAccountBalance = try await accountBalance
            let resolvedERC20TokenBalances = try await erc20TokenBalances
            let alreadyAssociatedTokens = resolvedAccountBalance.associatedTokensContractAddresses
            let exchangeRate = try await makeTokenAssociationFeeExchangeRatePublisher(alreadyAssociatedTokens: alreadyAssociatedTokens).async()

            try await updateWallet(accountBalance: resolvedAccountBalance, transactionsInfo: transactionsInfo)
            updateWalletTokens(
                accountBalance: resolvedAccountBalance,
                exchangeRate: exchangeRate,
                erc20TokenBalances: resolvedERC20TokenBalances
            )
        } catch {
            // We intentionally don't want to clear current token associations on failure
            wallet.clearAmounts()
            throw error
        }
    }

    private func updateWallet(accountBalance: HederaAccountBalance, transactionsInfo: [HederaTransactionInfo]) {
        let completedTransactionHashes = transactionsInfo
            .filter { !$0.isPending }
            .map { $0.transactionHash }

        wallet.removePendingTransaction(where: completedTransactionHashes.contains(_:))
        wallet.add(coinValue: Decimal(accountBalance.hbarBalance) / wallet.blockchain.decimalValue)
    }

    private func updateWalletTokens(
        accountBalance: HederaAccountBalance,
        exchangeRate: HederaExchangeRate?,
        erc20TokenBalances: [Token: Result<Decimal, Error>]
    ) {
        saveAssociatedTokensIfNeeded(newValue: accountBalance.associatedTokensContractAddresses)
        tokenAssociationFeeExchangeRate = exchangeRate?.maxHBARPerUSD

        let htsTokenBalances = accountBalance.tokenBalances.reduce(into: [:]) { result, element in
            result[element.contractAddress] = Decimal(element.balance) / pow(10, element.decimalCount)
        }

        cardTokens
            .filter { tokenType(for: $0) == .hts }
            .map { token in
                htsAmountTransform(token: token, tokenBalances: htsTokenBalances)
            }
            .forEach { token, amount in
                if let amount = amount {
                    wallet.add(amount: amount)
                } else {
                    wallet.clearAmount(for: token)
                }
            }

        updateERC20TokensBalances(erc20TokenBalances)
    }

    private func htsAmountTransform(token: Token, tokenBalances: [String: Decimal]) -> (Token, Amount?) {
        let contractAddress = normalizedHTSAddress(token.contractAddress)
        guard let balance = tokenBalances[contractAddress] else { return (token, nil) }
        return (token, Amount(with: token, value: balance))
    }

    private func updateERC20TokensBalances(_ tokensBalances: [Token: Result<Decimal, Error>]) {
        for (token, balanceResult) in tokensBalances {
            switch balanceResult {
            case .success(let value):
                wallet.add(tokenValue: value, for: token)
            case .failure:
                wallet.clearAmount(for: token)
            }
        }
    }

    private func fetchERC20TokenBalances(accountId: String) -> some Publisher<[Token: Result<Decimal, Error>], Error> {
        let erc20Tokens = cardTokens.filter { tokenType(for: $0) == .erc20 }
        let contractAddresses = erc20Tokens
            .map { (token: $0, contractAddress: erc20ContractAddress(for: $0)) }
            .keyedFirst(by: \.token)
            .mapValues(\.contractAddress)
        let networkService = networkService

        guard !erc20Tokens.isEmpty else {
            return Just.justWithError(output: [:])
        }

        return erc20Tokens
            .publisher
            .setFailureType(to: Error.self)
            .flatMap { token -> AnyPublisher<(Token, Result<Decimal, Error>), Error> in
                networkService
                    .getERC20Balance(
                        accountId: accountId,
                        tokenContractAddress: contractAddresses[token] ?? token.contractAddress,
                        tokenDecimals: token.decimalCount
                    )
                    .mapToResult()
                    .setFailureType(to: Error.self)
                    .map { (token, $0) }
                    .eraseToAnyPublisher()
            }
            .collect()
            .map { $0.reduce(into: [Token: Result<Decimal, Error>]()) { $0[$1.0] = $1.1 } }
            .eraseToAnyPublisher()
    }

    private func updateWalletWithPendingTransferTransaction(_ transaction: Transaction, sendResult: TransactionSendResult) {
        let mapper = AssetRequirementsPendingTransactionMapper(blockchain: wallet.blockchain)
        let pendingTransaction = mapper.mapToTransferRecord(transaction: transaction, hash: sendResult.hash)
        wallet.addPendingTransaction(pendingTransaction)
    }

    private func updateWalletWithPendingTokenAssociationTransaction(_ token: Token, sendResult: TransactionSendResult) {
        let mapper = AssetRequirementsPendingTransactionMapper(blockchain: wallet.blockchain)
        let pendingTransaction = mapper.mapToTokenAssociationRecord(token: token, hash: sendResult.hash, accountId: wallet.address)
        wallet.addPendingTransaction(pendingTransaction)
    }

    private func updateWalletAddress(accountId: String) {
        let address = PlainAddress(value: accountId, type: .default)
        wallet.set(address: address)
    }

    private func makeTokenAssociationFeeExchangeRatePublisher(
        alreadyAssociatedTokens: AssociatedTokens
    ) -> some Publisher<HederaExchangeRate?, Error> {
        let htsTokens = cardTokens.filter { tokenType(for: $0) == .hts }
        if htsTokens.allSatisfy({ alreadyAssociatedTokens.contains(normalizedHTSAddress($0.contractAddress)) }) {
            // All added tokens (from `cardTokens`) are already associated with the current account;
            // therefore there is no point in requesting an exchange rate to calculate the token association fee
            //
            // Performing an early exit
            return Just.justWithError(output: nil)
        }

        return networkService
            .getExchangeRate()
            .map { $0 as HederaExchangeRate? } // Combine can't implicitly bridge `Publisher<T, Error>` to `Publisher<T?, Error>`
            .replaceError(with: nil) // Token association fee request is auxiliary and shouldn't cause the entire reactive chain to fail
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    private func makePendingTransactionsInfoPublisher() -> some Publisher<[HederaTransactionInfo], Error> {
        return wallet
            .pendingTransactions
            .publisher
            .setFailureType(to: Error.self)
            .withWeakCaptureOf(self)
            .flatMap { walletManager, pendingTransaction in
                return walletManager.networkService.getTransactionInfo(transactionHash: pendingTransaction.hash)
            }
            .collect()
    }

    // MARK: - Account ID fetching, caching and creation

    /// Used to query the status of the `receiving` (`destination`) account.
    private func doesAccountExist(destination: String) -> some Publisher<Bool, Error> {
        return Deferred {
            return Future { promise in
                let result = Result { try Hiero.AccountId(parsing: destination) }
                promise(result)
            }
        }
        .withWeakCaptureOf(self)
        .flatMap { walletManager, accountId in
            // Accounts with an account ID and/or EVM address are considered existing accounts
            let accountHasValidAccountIdOrEVMAddress = accountId.num != 0 || accountId.evmAddress != nil

            if accountHasValidAccountIdOrEVMAddress {
                return Just(true)
                    .eraseToAnyPublisher()
            }

            guard let alias = accountId.alias else {
                // Perhaps an unreachable case: account doesn't have an account ID, EVM address, or account alias
                return Just(false)
                    .eraseToAnyPublisher()
            }

            // Any error returned from the API is treated as a non-existent account, just in case
            return walletManager
                .networkService
                .getAccountInfo(publicKey: alias.toBytesRaw()) // ECDSA key must be in a compressed form
                .map { _ in true }
                .replaceError(with: false)
                .eraseToAnyPublisher()
        }
    }

    /// - Note: Has a side-effect: updates local model (`wallet.address`) if needed.
    private func getAccountId() -> some Publisher<String, Error> {
        let maskedPublicKey = maskedPublicKey

        if let accountId = wallet.address.nilIfEmpty {
            BSDKLogger.error(error: "Hedera account ID for public key \(maskedPublicKey) obtained from the Wallet")
            return Just.justWithError(output: accountId)
        }

        return getCachedAccountId()
            .withWeakCaptureOf(self)
            .handleEvents(receiveOutput: { walletManager, accountId in
                walletManager.updateWalletAddress(accountId: accountId)
                BSDKLogger.info("Hedera account ID for public key \(maskedPublicKey) saved to the Wallet")
            })
            .map(\.1)
            .eraseToAnyPublisher()
    }

    /// Performs a reset of an already cached account id only if the 'reset version' is absent or lower
    /// than the current 'reset version' saved on disk (`Constants.accountIdResetVersion).
    private func resetCachedAccountIdIfNeeded() -> some Publisher<Void, Error> {
        let maskedPublicKey = maskedPublicKey
        let accountIdStorageKey = Constants.accountIdStorageKeyPrefix + storageKeySuffix
        let resetVersionStorageKey = Constants.accountIdResetVersionStorageKeyPrefix + storageKeySuffix

        return Just(resetVersionStorageKey)
            .setFailureType(to: Error.self)
            .withWeakCaptureOf(self)
            .asyncMap { walletManager, storageKey -> Int? in
                return await walletManager.dataStorage.get(key: storageKey)
            }
            .filter { cachedResetVersion in
                guard let cachedResetVersion else {
                    // Always perform a reset if no 'reset version' is currently saved on disk
                    return true
                }
                // Perform a reset if saved on disk 'reset version' is lower than actual
                return cachedResetVersion < Constants.accountIdResetVersion
            }
            .withWeakCaptureOf(self)
            .asyncMap { walletManager, _ in
                // Empty string is perfectly fine for using as an overriding value because account id
                // is always fetched using `nilIfEmpty` helper
                await walletManager.dataStorage.store(key: accountIdStorageKey, value: "")
                await walletManager.dataStorage.store(key: resetVersionStorageKey, value: Constants.accountIdResetVersion)
                BSDKLogger.info("Hedera account ID for public key \(maskedPublicKey) was reset")
            }
            .mapToVoid()
            .replaceEmpty(with: ()) // Continue the reactive stream normally even if the `.filter` statement above returns false
    }

    /// - Note: Has a side-effect: updates local cache (`dataStorage`) if needed.
    private func getCachedAccountId() -> some Publisher<String, Error> {
        let maskedPublicKey = maskedPublicKey
        let storageKey = Constants.accountIdStorageKeyPrefix + storageKeySuffix

        return resetCachedAccountIdIfNeeded()
            .withWeakCaptureOf(self)
            .asyncMap { walletManager, _ -> String? in
                await walletManager.dataStorage.get(key: storageKey)
            }
            .withWeakCaptureOf(self)
            .flatMap { walletManager, accountId in
                if let accountId = accountId?.nilIfEmpty {
                    BSDKLogger.error(error: "Hedera account ID for public key \(maskedPublicKey) obtained from the data storage")
                    return Just.justWithError(output: accountId)
                }

                return walletManager
                    .getRemoteAccountId()
                    .withWeakCaptureOf(walletManager)
                    .asyncMap { walletManager, accountId in
                        await walletManager.dataStorage.store(key: storageKey, value: accountId)
                        BSDKLogger.error(error: "Hedera account ID for public key \(maskedPublicKey) saved to the data storage")
                        return accountId
                    }
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
    }

    /// - Note: Fetches a single existing account using the `createOrFetchAccount` method if multiple accounts exist on the Hedera network.
    /// - Note: Has a side-effect: creates a new account on the Hedera network using the `createOrFetchAccount` method if needed.
    private func getRemoteAccountId() -> some Publisher<String, Error> {
        let maskedPublicKey = maskedPublicKey

        return networkService
            .getAccountInfo(publicKey: wallet.publicKey.blockchainKey)
            .map(\.accountId)
            .handleEvents(
                receiveOutput: { _ in
                    BSDKLogger.info("Hedera account ID for public key \(maskedPublicKey) obtained from the mirror node")
                },
                receiveFailure: { error in
                    BSDKLogger.error(error:
                        """
                        Failed to obtain Hedera account ID for public key \(maskedPublicKey) \
                        from the mirror node due to error: \(error.localizedDescription)
                        """
                    )
                }
            )
            .tryCatch { [weak self] error in
                guard let self else {
                    throw error
                }

                switch error {
                case HederaError.accountDoesNotExist, HederaError.multipleAccountsFound:
                    return createOrFetchAccount()
                default:
                    throw error
                }
            }
    }

    private func createOrFetchAccount() -> some Publisher<String, Error> {
        let maskedPublicKey = maskedPublicKey

        return accountCreator
            .createAccount(blockchain: wallet.blockchain, publicKey: wallet.publicKey)
            .eraseToAnyPublisher()
            .tryMap { createdAccount in
                guard let hederaCreatedAccount = createdAccount as? HederaCreatedAccount else {
                    assertionFailure("Expected entity of type '\(HederaCreatedAccount.self)', got '\(type(of: createdAccount))' instead")
                    throw HederaError.failedToCreateAccount
                }

                return hederaCreatedAccount.accountId
            }
            .handleEvents(
                receiveOutput: { _ in
                    BSDKLogger.info("Hedera account ID for public key \(maskedPublicKey) obtained by creating account")
                },
                receiveFailure: { error in
                    BSDKLogger.error(error:
                        """
                        Failed to obtain Hedera account ID for public key \(maskedPublicKey) \
                        by creating account due to error: \(error.localizedDescription)
                        """
                    )
                }
            )
            .mapError(BlockchainSdkError.blockchainUnavailable(underlyingError:))
    }

    // MARK: - Token associations management

    private func loadCachedAssociatedTokensIfNeeded() async {
        guard associatedTokens == nil else { return }

        let storageKey = Constants.associatedTokensStorageKeyPrefix + storageKeySuffix
        let cachedAssociatedTokens: AssociatedTokens = await dataStorage.get(key: storageKey) ?? []

        await MainActor.run {
            self.associatedTokens = cachedAssociatedTokens
        }
    }

    private func saveAssociatedTokensIfNeeded(newValue: AssociatedTokens) {
        guard associatedTokens != newValue else {
            return
        }

        associatedTokens = newValue

        Task.detached { [storageKeySuffix, dataStorage] in
            let storageKey = Constants.associatedTokensStorageKeyPrefix + storageKeySuffix
            await dataStorage.store(key: storageKey, value: newValue)
        }
    }

    private func loadCachedTokenMetadataIfNeeded() async {
        guard tokenMetadata == nil else { return }

        let storageKey = Constants.tokenMetadataStorageKeyPrefix + storageKeySuffix
        let tokenMetadata: TokenMetadata = await dataStorage.get(key: storageKey) ?? [:]

        await MainActor.run {
            self.tokenMetadata = tokenMetadata
        }
    }

    private func resolveTokenMetadata(for token: Token) async {
        await loadCachedTokenMetadataIfNeeded()

        guard tokenMetadata?[token.contractAddress] == nil else {
            return
        }

        let resolver = HederaTokenMetadataResolver(networkService: networkService)
        guard let metadata = try? await resolver.resolve(contractAddress: token.contractAddress) else {
            return
        }

        var updatedMetadata = tokenMetadata ?? [:]
        updatedMetadata[token.contractAddress] = metadata
        saveTokenMetadataIfNeeded(newValue: updatedMetadata)
    }

    private func saveTokenMetadataIfNeeded(newValue: TokenMetadata) {
        guard tokenMetadata != newValue else {
            return
        }

        tokenMetadata = newValue

        let previousStorageTask = tokenMetadataStorageTask
        previousStorageTask?.cancel()
        tokenMetadataStorageTask = Task.detached { [storageKeySuffix, dataStorage] in
            await previousStorageTask?.value
            guard !Task.isCancelled else { return }

            let storageKey = Constants.tokenMetadataStorageKeyPrefix + storageKeySuffix
            await dataStorage.store(key: storageKey, value: newValue)
        }
    }

    private func tokenType(for token: Token) -> HederaTokenType {
        if let cachedType = tokenMetadata?[token.contractAddress]?.type {
            return cachedType
        }

        return HederaTokenContractAddressConverter.isERC20TokenAddress(token.contractAddress) ? .erc20 : .hts
    }

    private func normalizedHTSAddress(_ address: String) -> String {
        return HederaTokenMetadataResolver(networkService: networkService).normalizeHTSAddress(address)
    }

    private func erc20ContractAddress(for token: Token) -> String {
        return tokenMetadata?[token.contractAddress]?.evmAddress ?? token.contractAddress
    }

    private func assetRequiresAssociation(_ asset: Asset) -> Bool {
        switch asset {
        case .coin, .reserve, .feeResource:
            return false
        case .token(let token):
            if tokenType(for: token) == .erc20 {
                return false
            }

            return !(associatedTokens ?? []).contains(normalizedHTSAddress(token.contractAddress))
        }
    }

    // MARK: - Transaction dependencies and building

    private func makeTransferContext(
        for transaction: Transaction
    ) -> AnyPublisher<HederaTransactionBuilder.TransferContext, Error> {
        guard case .token(let token) = transaction.amount.type, tokenType(for: token) == .erc20 else {
            return .justWithError(output: .regular)
        }

        let tokenContractAddress = erc20ContractAddress(for: token)

        return networkService
            .getAccountInfo(address: transaction.destinationAddress)
            .tryMap { accountInfo -> HederaTransactionBuilder.TransferContext in
                guard let recipientEVMAddress = accountInfo.evmAddress, !recipientEVMAddress.isEmpty else {
                    throw HederaError.accountEVMAddressNotFound
                }

                return .erc20(
                    tokenContractAddress: tokenContractAddress,
                    recipientEVMAddress: recipientEVMAddress
                )
            }
            .eraseToAnyPublisher()
    }

    private func getFee(amount: Amount, doesAccountExistPublisher: some Publisher<Bool, Error>) -> AnyPublisher<[Fee], Error> {
        let transferFeeBase: Decimal
        var tokenCustomFeesPublisher: AnyPublisher<HederaTokenCustomFeesInfo?, Error> = .justWithError(output: nil)
        switch amount.type {
        case .coin:
            transferFeeBase = Constants.cryptoTransferServiceCostInUSD
        case .token(let token):
            transferFeeBase = Constants.tokenTransferServiceCostInUSD
            if tokenType(for: token) == .hts {
                tokenCustomFeesPublisher = networkService.getTokensCustomFeesInfo(
                    tokenAddress: normalizedHTSAddress(token.contractAddress)
                )
                .mapToOptional()
                .eraseToAnyPublisher()
            }
        case .reserve, .feeResource:
            return .anyFail(error: BlockchainSdkError.failedToGetFee)
        }

        return Publishers.CombineLatest3(
            networkService.getExchangeRate(),
            doesAccountExistPublisher,
            tokenCustomFeesPublisher
        )
        .withWeakCaptureOf(self)
        .tryMap { walletManager, input in
            let (exchangeRate, doesAccountExist, tokenCustomFeesInfo) = input

            var feeBase = doesAccountExist ? transferFeeBase : Constants.cryptoCreateServiceCostInUSD

            if tokenCustomFeesInfo?.hasTokenCustomFees == true {
                feeBase += Constants.customFeeTokenTransferServiceCostInUSD
            }

            // this goes on UI only, will be deducted later, see transactionBuilder -> buildTransferTransactionForSign
            let additionalHBARFee = tokenCustomFeesInfo?.additionalHBARFee ?? .zero

            let feeValue = exchangeRate.maxHBARPerUSD * feeBase * Constants.maxFeeMultiplier + additionalHBARFee
            // Hedera fee calculation involves conversion from USD to HBar units, which ultimately results in a loss of precision.
            // Therefore, the fee value is always approximate and rounding of the fee value is mandatory.
            let feeRoundedValue = feeValue.rounded(blockchain: walletManager.wallet.blockchain, roundingMode: .up)
            let feeAmount = Amount(with: walletManager.wallet.blockchain, value: feeRoundedValue)
            let fee = Fee(feeAmount, parameters: HederaFeeParams(additionalHBARFee: additionalHBARFee, contractCallGasLimit: nil))

            return [fee]
        }
        .eraseToAnyPublisher()
    }

    private func getERC20TransferFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        guard case .token(let token) = amount.type else {
            return .anyFail(error: BlockchainSdkError.failedToGetFee)
        }

        let tokenContractAddress = erc20ContractAddress(for: token)

        return Publishers.CombineLatest(
            networkService.estimateERC20Transfer(
                sourceAccountId: wallet.address,
                destinationAddress: destination,
                tokenContractAddress: tokenContractAddress,
                amount: amount
            ),
            networkService.getERC20GasPrice()
        )
        .tryMap { [weak self] gasLimit, gasPrice in
            guard let self else {
                throw BlockchainSdkError.failedToGetFee
            }

            let totalGas = Decimal(gasLimit) * Decimal(gasPrice)
            let feeValue = totalGas / wallet.blockchain.decimalValue
            let feeRoundedValue = feeValue.rounded(blockchain: wallet.blockchain, roundingMode: .up)
            let feeAmount = Amount(with: wallet.blockchain, value: feeRoundedValue)
            let feeParams = HederaFeeParams(
                additionalHBARFee: .zero,
                contractCallGasLimit: gasLimit
            )

            return [Fee(feeAmount, parameters: feeParams)]
        }
        .eraseToAnyPublisher()
    }

    private static func makeTransactionValidStartDate() -> UnixTimestamp? {
        // Subtracting `validStartDateDiff` from the `Date.now` to make sure that the tx valid start date has already passed
        // The logic is the same as in the `Hiero.TransactionId.generateFrom(_:)` factory method
        let validStartDateDiff = Int.random(in: 5_000_000_000 ..< 8_000_000_000)
        let validStartDate = Calendar.current.date(byAdding: .nanosecond, value: -validStartDateDiff, to: Date())

        return validStartDate.flatMap(UnixTimestamp.init(date:))
    }

    private func sendCompiledTransaction(
        signedUsing signer: TransactionSigner,
        transactionFactory: @escaping (_ validStartDate: UnixTimestamp) throws -> HederaTransactionBuilder.CompiledTransaction
    ) -> some Publisher<TransactionSendResult, Error> {
        return Deferred {
            return Future { (promise: Future<HederaTransactionBuilder.CompiledTransaction, Error>.Promise) in
                guard let validStartDate = Self.makeTransactionValidStartDate() else {
                    return promise(.failure(BlockchainSdkError.failedToBuildTx))
                }

                let compiledTransaction = Result { try transactionFactory(validStartDate) }
                promise(compiledTransaction)
            }
        }
        .tryMap { compiledTransaction in
            let hashesToSign = try compiledTransaction.hashesToSign()
            return (hashesToSign, compiledTransaction)
        }
        .withWeakCaptureOf(self)
        .flatMap { walletManager, input in
            let (hashesToSign, compiledTransaction) = input
            return signer
                .sign(hashes: hashesToSign, walletPublicKey: walletManager.wallet.publicKey)
                .map { ($0, compiledTransaction) }
        }
        .withWeakCaptureOf(self)
        .tryMap { walletManager, input in
            let (signatures, compiledTransaction) = input
            return try walletManager
                .transactionBuilder
                .buildForSend(transaction: compiledTransaction, signatures: signatures.map(\.signature))
        }
        .withWeakCaptureOf(self)
        .flatMap { walletManager, compiledTransaction in
            let transactionRawData = try? compiledTransaction.toBytes()

            return walletManager
                .networkService
                .send(transaction: compiledTransaction)
                .mapAndEraseSendTxError(tx: transactionRawData?.hex(), currentHost: walletManager.currentHost)
                .eraseToAnyPublisher()
        }
    }
}

// MARK: - WalletManager protocol conformance

extension HederaWalletManager: WalletManager {
    var currentHost: String { networkService.host }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        if case .token(let token) = amount.type,
           tokenType(for: token) == .erc20 {
            return getERC20TransferFee(amount: amount, destination: destination)
        }

        let doesAccountExistPublisher = doesAccountExist(destination: destination)

        return getFee(amount: amount, doesAccountExistPublisher: doesAccountExistPublisher)
    }

    func estimatedFee(amount: Amount) -> AnyPublisher<[Fee], Error> {
        // For a rough fee estimation (calculated in this method), all destinations are considered non-existent just in case
        let doesAccountExistPublisher = Just.justWithError(output: false)

        return getFee(amount: amount, doesAccountExistPublisher: doesAccountExistPublisher)
    }

    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        return makeTransferContext(for: transaction)
            .withWeakCaptureOf(self)
            .flatMap { walletManager, transferContext in
                walletManager.sendCompiledTransaction(signedUsing: signer) { validStartDate in
                    return try walletManager.transactionBuilder
                        .buildTransferTransactionForSign(
                            transaction: transaction,
                            transferContext: transferContext,
                            validStartDate: validStartDate,
                            nodeAccountIds: nil
                        )
                }
            }
            .withWeakCaptureOf(self)
            .handleEvents(receiveOutput: { walletManager, sendResult in
                walletManager.updateWalletWithPendingTransferTransaction(transaction, sendResult: sendResult)
            })
            .mapSendTxError(currentHost: currentHost)
            .map(\.1)
            .eraseToAnyPublisher()
    }
}

// MARK: - AssetRequirementsManager protocol conformance

extension HederaWalletManager: AssetRequirementsManager {
    func feeStatusForRequirement(asset: Asset) -> AnyPublisher<AssetRequirementFeeStatus, Never> {
        let status: AssetRequirementFeeStatus = wallet.hasFeeCurrency(amountType: asset) ? .sufficient : .insufficient(missingAmount: "")
        return Just(status).eraseToAnyPublisher()
    }

    func requirementsCondition(for asset: Asset) -> AssetRequirementsCondition? {
        guard assetRequiresAssociation(asset) else {
            return nil
        }

        switch asset {
        case .coin, .reserve, .feeResource:
            return nil
        case .token:
            guard let tokenAssociationFeeExchangeRate else {
                return .paidTransactionWithFee(blockchain: wallet.blockchain, transactionAmount: nil, feeAmount: nil)
            }

            let feeValue = tokenAssociationFeeExchangeRate * Constants.tokenAssociateServiceCostInUSD
            // Hedera fee calculation involves conversion from USD to HBar units, which ultimately results in a loss of precision.
            // Therefore, the fee value is always approximate and rounding of the fee value is mandatory.
            let feeRoundedValue = feeValue.rounded(blockchain: wallet.blockchain, roundingMode: .up)
            let feeAmount = Amount(with: wallet.blockchain, value: feeRoundedValue)

            return .paidTransactionWithFee(blockchain: wallet.blockchain, transactionAmount: nil, feeAmount: feeAmount)
        }
    }

    func fulfillRequirements(for asset: Asset, signer: any TransactionSigner) -> AnyPublisher<Void, Error> {
        guard assetRequiresAssociation(asset) else {
            return .justWithError(output: ())
        }

        switch asset {
        case .coin, .reserve, .feeResource:
            return .justWithError(output: ())
        case .token(let token):
            return sendCompiledTransaction(signedUsing: signer) { [weak self] validStartDate in
                guard let self else {
                    throw BlockchainSdkError.empty
                }

                return try transactionBuilder.buildTokenAssociationForSign(
                    tokenAssociation: .init(
                        accountId: wallet.address,
                        contractAddress: normalizedHTSAddress(token.contractAddress)
                    ),
                    validStartDate: validStartDate,
                    nodeAccountIds: nil
                )
            }
            .withWeakCaptureOf(self)
            .handleEvents(receiveOutput: { walletManager, sendResult in
                walletManager.updateWalletWithPendingTokenAssociationTransaction(token, sendResult: sendResult)
            })
            .mapToVoid()
            .eraseToAnyPublisher()
        }
    }
}

// MARK: - Constants

private extension HederaWalletManager {
    private enum Constants {
        static let accountIdStorageKeyPrefix = "hedera_wallet_"
        static let accountIdResetVersionStorageKeyPrefix = "hedera_wallet_reset_version_"
        static let associatedTokensStorageKeyPrefix = "hedera_associated_tokens_"
        static let tokenMetadataStorageKeyPrefix = "hedera_token_metadata_"
        /// https://docs.hedera.com/hedera/networks/mainnet/fees
        static let cryptoTransferServiceCostInUSD = Decimal(stringValue: "0.0001")!
        static let tokenTransferServiceCostInUSD = Decimal(stringValue: "0.001")!
        static let customFeeTokenTransferServiceCostInUSD = Decimal(stringValue: "0.001")!
        static let cryptoCreateServiceCostInUSD = Decimal(stringValue: "0.05")!
        static let tokenAssociateServiceCostInUSD = Decimal(stringValue: "0.05")!
        /// Hedera fees are low, allow 10% safety margin to allow usage of not precise fee estimate.
        static let maxFeeMultiplier = Decimal(stringValue: "1.1")!
        /// Increment if you need to reset `dataStorage` in the next version of the app.
        static let accountIdResetVersion = 1
    }
}

// MARK: - Convenience extensions

private extension HederaAccountBalance {
    var associatedTokensContractAddresses: HederaWalletManager.AssociatedTokens {
        return tokenBalances
            .map(\.contractAddress)
            .toSet()
    }
}
