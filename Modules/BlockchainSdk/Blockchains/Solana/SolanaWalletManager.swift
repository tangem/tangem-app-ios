//
//  SolanaWalletManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import SolanaSwift
import TangemFoundation

class SolanaWalletManager: BaseWalletManager, WalletManager {
    var networkService: SolanaNetworkService!

    var currentHost: String { networkService.host }

    /// Dictionary storing token account space requirements for each mint address.
    /// Used when sending tokens to accounts that don't exist yet to calculate minimum rent.
    /// Key is mint address, value is required space in bytes.
    var ownerTokenAccountSpacesByMint: [String: UInt64] = [:]

    /// It is taken into account in the calculation of the account rent commission for the sender
    private var mainAccountRentExemption: Decimal = 0

    private let transactionHelper = SolanaTransactionHelper()

    func updateWalletManager(address: String) async throws {
        do {
            let tokens = cardTokens
            let info = try await networkService.getInfo(accountId: address, tokens: tokens).async()
            updateWallet(info: info, tokens: tokens)
        } catch {
            wallet.clearAmounts()
            throw error
        }
    }

    private func updateWallet(info: SolanaAccountInfoResponse, tokens: [Token]) {
        mainAccountRentExemption = info.mainAccountRentExemption

        // Store token account sizes for define minimal rent when destination token account is not created
        ownerTokenAccountSpacesByMint = info.tokensByMint.reduce(into: [:]) { $0[$1.key] = $1.value.space }
        wallet.add(coinValue: info.balance)

        for cardToken in tokens {
            let mintAddress = cardToken.contractAddress
            let balance = info.tokensByMint[mintAddress]?.balance ?? Decimal(0)
            wallet.add(tokenValue: balance, for: cardToken)
        }

        wallet.clearPendingTransaction()
    }
}

extension SolanaWalletManager: TransactionSender {
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        let sendPublisher: AnyPublisher<TransactionID, Error>
        switch transaction.amount.type {
        case .coin:
            sendPublisher = sendSol(transaction, signer: signer)
        case .token(let token) where token.metadata.kind != .fungible:
            sendPublisher = sendNFT(transaction, token: token, signer: signer)
        case .token(let token):
            sendPublisher = sendSplToken(transaction, token: token, signer: signer)
        case .reserve, .feeResource:
            return .sendTxFail(error: BlockchainSdkError.empty, currentHost: currentHost)
        }

        return sendPublisher
            .withWeakCaptureOf(self)
            .tryMap { manager, hash in
                let mapper = PendingTransactionRecordMapper()
                let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: hash)
                manager.wallet.addPendingTransaction(record)

                return TransactionSendResult(hash: hash, currentProviderHost: manager.currentHost)
            }
            .mapSendTxError(currentHost: currentHost)
            .eraseToAnyPublisher()
    }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        if case .token(let token) = amount.type, token.metadata.kind != .fungible {
            return getNFTFee(amount: amount, token: token, destination: destination)
        }

        return getFungibleFee(amount: amount, destination: destination)
    }

    private func getFungibleFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        Result {
            guard let publicKey = PublicKey(data: wallet.publicKey.blockchainKey) else {
                throw SolanaError.invalidPublicKey
            }

            return publicKey
        }
        .publisher
        .withWeakCaptureOf(self)
        .flatMap { walletManager, publicKey in
            walletManager.networkService.getFee(
                amount: amount,
                destination: destination,
                publicKey: publicKey
            )
        }
        .withWeakCaptureOf(self)
        .flatMap { walletManager, fee -> AnyPublisher<Fee, Error> in
            guard let solanaFeeParameters = fee.parameters as? SolanaFeeParameters else {
                return .anyFail(error: SolanaError.other("Failed to get SolanaFeeParameters"))
            }

            // account is already created, so we don't need to add rent exemption
            if solanaFeeParameters.destinationAccountExists {
                return .justWithError(output: fee)
            }

            // we don't add fee for coins, handled by transaction validator
            guard case .token(let token) = amount.type else {
                return .justWithError(output: fee)
            }

            // impossible case
            guard let space = walletManager.ownerTokenAccountSpacesByMint[token.contractAddress] else {
                return .justWithError(output: fee)
            }

            return walletManager.networkService.minimalBalanceForRentExemption(dataLength: space)
                .map { accountCreationFee in
                    var increasedFee = fee
                    increasedFee.amount.value += accountCreationFee
                    return increasedFee
                }
                .eraseToAnyPublisher()
        }
        .map { [$0] }
        .eraseToAnyPublisher()
    }

    private func sendSol(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionID, Error> {
        guard let solanaFeeParameters = transaction.fee.parameters as? SolanaFeeParameters else {
            return .anyFail(error: BlockchainSdkError.failedToSendTx)
        }

        let decimalAmount = transaction.amount.value * wallet.blockchain.decimalValue
        let intAmount = (decimalAmount.rounded() as NSDecimalNumber).uint64Value

        return Future.async { [weak self] in
            guard let self else {
                throw BlockchainSdkError.empty
            }

            let owner = try walletSolanaPublicKey()
            guard owner.base58EncodedString != transaction.destinationAddress else {
                throw SolanaError.other("You can not send tokens to yourself")
            }

            guard let destination = PublicKey(string: transaction.destinationAddress) else {
                throw SolanaError.invalidPublicKey
            }

            let transfer = SolanaTransferInstruction.systemTransfer(from: owner, to: destination, lamports: intAmount)
            return try await signAndSendWithFreshBlockhash(
                instructions: computeBudgetInstructions(solanaFeeParameters) + [transfer],
                signer: signer
            )
        }
        .eraseToAnyPublisher()
    }

    private func sendSplToken(_ transaction: Transaction, token: Token, signer: TransactionSigner) -> AnyPublisher<TransactionID, Error> {
        guard let solanaFeeParameters = transaction.fee.parameters as? SolanaFeeParameters else {
            return .anyFail(error: BlockchainSdkError.failedToSendTx)
        }

        let tokenProgramIdPublisher = networkService.tokenProgramId(contractAddress: token.contractAddress)

        return tokenProgramIdPublisher
            .withWeakCaptureOf(self)
            .flatMap { manager, tokenProgramId -> AnyPublisher<(UInt64, PublicKey), Error> in
                manager.makeTokenTransferAmountPublisher(
                    tokenProgramId: tokenProgramId,
                    amount: transaction.amount.value,
                    token: token
                )
                .map { ($0, tokenProgramId) }
                .eraseToAnyPublisher()
            }
            .flatMap { [weak self] amountAndProgramId -> AnyPublisher<TransactionID, Error> in
                guard let self else {
                    return .anyFail(error: BlockchainSdkError.empty)
                }

                let (intAmount, tokenProgramId) = amountAndProgramId
                guard
                    let associatedSourceTokenAccountAddress = associatedTokenAddress(accountAddress: transaction.sourceAddress, mintAddress: token.contractAddress, tokenProgramId: tokenProgramId)
                else {
                    return .anyFail(error: BlockchainSdkError.failedToConvertPublicKey)
                }

                return Future.async { [weak self] in
                    guard let self else {
                        throw BlockchainSdkError.empty
                    }

                    let instructions = try await splTokenTransferInstructions(
                        amount: intAmount,
                        feeParameters: solanaFeeParameters,
                        sourceTokenAddress: associatedSourceTokenAccountAddress,
                        destinationAddress: transaction.destinationAddress,
                        token: token,
                        tokenProgramId: tokenProgramId
                    )

                    return try await signAndSendWithFreshBlockhash(instructions: instructions, signer: signer)
                }
                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    private func signAndSendWithFreshBlockhash(instructions: [SolanaRawInstruction], signer: TransactionSigner) async throws -> TransactionID {
        let feePayer = wallet.publicKey.blockchainKey

        let (transaction, signatures) = try await signer.sign(walletPublicKey: wallet.publicKey) { [networkService] in
            guard let networkService else {
                throw BlockchainSdkError.empty
            }

            let transaction = try SolanaSelfPaidTransaction.make(
                instructions: instructions,
                feePayer: feePayer,
                blockhash: try await networkService.latestBlockhash()
            )
            return (transaction, [transaction.message])
        }

        guard let signature = signatures.first?.signature else {
            throw BlockchainSdkError.failedToSendTx
        }

        return try await networkService.sendRaw(
            base64serializedTransaction: try transaction.serialized(signature: signature).base64EncodedString(),
            startSendingTimestamp: transaction.blockhashFetchedAt
        ).async()
    }

    private func splTokenTransferInstructions(
        amount: UInt64,
        feeParameters: SolanaFeeParameters,
        sourceTokenAddress: String,
        destinationAddress: String,
        token: Token,
        tokenProgramId: PublicKey
    ) async throws -> [SolanaRawInstruction] {
        let owner = try walletSolanaPublicKey()
        let destination = try await networkService.splTokenDestination(
            mintAddress: token.contractAddress,
            tokenProgramId: tokenProgramId,
            destinationAddress: destinationAddress
        )

        guard
            sourceTokenAddress != destination.destination.base58EncodedString,
            let source = PublicKey(string: sourceTokenAddress),
            let mint = PublicKey(string: token.contractAddress)
        else {
            throw SolanaError.invalidPublicKey
        }

        var instructions = computeBudgetInstructions(feeParameters)

        if destination.isUnregisteredAsocciatedToken {
            guard let destinationOwner = PublicKey(string: destinationAddress) else {
                throw SolanaError.invalidPublicKey
            }

            instructions.append(
                SolanaTransferInstruction.createAssociatedTokenAccount(
                    payer: owner,
                    associatedAccount: destination.destination,
                    owner: destinationOwner,
                    mint: mint,
                    tokenProgramId: tokenProgramId
                )
            )
        }

        instructions.append(
            SolanaTransferInstruction.transferChecked(
                source: source,
                mint: mint,
                destination: destination.destination,
                owner: owner,
                amount: amount,
                decimals: UInt8(token.decimalCount),
                tokenProgramId: tokenProgramId
            )
        )

        return instructions
    }

    private func computeBudgetInstructions(_ feeParameters: SolanaFeeParameters) -> [SolanaRawInstruction] {
        SolanaComputeBudgetInstruction.instructions(
            computeUnitLimit: feeParameters.computeUnitLimit,
            computeUnitPrice: feeParameters.computeUnitPrice
        )
    }

    private func walletSolanaPublicKey() throws -> PublicKey {
        guard let publicKey = PublicKey(data: wallet.publicKey.blockchainKey) else {
            throw SolanaError.invalidPublicKey
        }

        return publicKey
    }

    private func getNFTFee(amount: Amount, token: Token, destination: String) -> AnyPublisher<[Fee], Error> {
        Future.async { [weak self] in
            guard let self else {
                throw BlockchainSdkError.empty
            }

            let route = try await nftTransferBuilder.route(
                assetAddress: token.contractAddress,
                owner: wallet.address,
                destination: destination,
                payer: wallet.address
            )

            switch route {
            case .splToken:
                return try await getFungibleFee(amount: amount, destination: destination).async()
            case .program(let plan):
                return [try await nftFee(plan: plan)]
            }
        }
        .eraseToAnyPublisher()
    }

    private func nftFee(plan: SolanaNFTTransferPlan) async throws -> Fee {
        let parameters = nftFeeParameters(plan: plan)
        let transaction = try await makeNFTTransaction(plan: plan, feeParameters: parameters)
        let networkFee = try await networkService.getFeeForCompiled(message: transaction.message.base64EncodedString()).async()

        var rent: Decimal = 0
        for space in plan.createdAccountSpaces {
            rent += try await networkService.minimalBalanceForRentExemption(dataLength: space).async()
        }

        return Fee(Amount(with: wallet.blockchain, type: .coin, value: networkFee + rent), parameters: parameters)
    }

    private func nftFeeParameters(plan: SolanaNFTTransferPlan) -> SolanaFeeParameters {
        let usesComputeBudget = !NFCUtils.isPoorNfcQualityDevice

        return SolanaFeeParameters(
            destinationAccountExists: plan.createdAccountSpaces.isEmpty,
            computeUnitLimit: usesComputeBudget ? plan.computeUnitLimit : nil,
            computeUnitPrice: usesComputeBudget ? Constants.nftComputeUnitPrice : nil
        )
    }

    private func sendNFT(_ transaction: Transaction, token: Token, signer: TransactionSigner) -> AnyPublisher<TransactionID, Error> {
        Future.async { [weak self] in
            guard let self else {
                throw BlockchainSdkError.empty
            }

            let route = try await nftTransferBuilder.route(
                assetAddress: token.contractAddress,
                owner: transaction.sourceAddress,
                destination: transaction.destinationAddress,
                payer: transaction.sourceAddress
            )

            switch route {
            case .splToken:
                return try await sendSplToken(transaction, token: token, signer: signer).async()
            case .program(let plan):
                return try await sendNFT(plan: plan, feeParameters: transaction.fee.parameters, signer: signer)
            }
        }
        .eraseToAnyPublisher()
    }

    private func sendNFT(plan: SolanaNFTTransferPlan, feeParameters: FeeParameters?, signer: TransactionSigner) async throws -> TransactionID {
        guard let feeParameters = feeParameters as? SolanaFeeParameters else {
            throw BlockchainSdkError.failedToSendTx
        }

        let transaction = try await makeNFTTransaction(plan: plan, feeParameters: feeParameters)
        let solanaSigner = SolanaTransactionSigner(transactionSigner: signer, walletPublicKey: wallet.publicKey)
        let signature = try await solanaSigner.sign(message: transaction.message)

        do {
            return try await networkService.sendRaw(
                base64serializedTransaction: try transaction.serialized(signature: signature).base64EncodedString(),
                startSendingTimestamp: transaction.blockhashFetchedAt
            ).async()
        } catch {
            throw SolanaSendError.mapped(from: error)
        }
    }

    private func makeNFTTransaction(plan: SolanaNFTTransferPlan, feeParameters: SolanaFeeParameters) async throws -> SolanaSelfPaidTransaction {
        let computeBudgetInstructions = SolanaComputeBudgetInstruction.instructions(
            computeUnitLimit: feeParameters.computeUnitLimit,
            computeUnitPrice: feeParameters.computeUnitPrice
        )
        let blockhashFetchedAt = Date()
        let blockhash = SolanaBlockhash(value: try await networkService.getLatestBlockhash(), fetchedAt: blockhashFetchedAt)

        return try SolanaSelfPaidTransaction.make(
            instructions: computeBudgetInstructions + plan.instructions,
            feePayer: wallet.publicKey.blockchainKey,
            blockhash: blockhash
        )
    }

    private var nftTransferBuilder: SolanaNFTTransferBuilder {
        SolanaNFTTransferBuilder(accountProvider: networkService)
    }

    func makeTokenTransferAmountPublisher(
        tokenProgramId: PublicKey,
        amount: Decimal,
        token: Token
    ) -> AnyPublisher<UInt64, Error> {
        if tokenProgramId != .token2022ProgramId {
            return makeRawTokenAmount(amount: amount, token: token, multiplier: nil)
        }

        return networkService.getScaledUIAmountMultiplier(
            mintAddress: token.contractAddress,
            transactionDate: Date()
        )
        .tryMap { [weak self] multiplier in
            guard let self else {
                throw BlockchainSdkError.empty
            }

            return try makeRawTokenAmount(amount: amount, token: token, multiplier: multiplier)
        }
        .eraseToAnyPublisher()
    }

    private func makeRawTokenAmount(
        amount: Decimal,
        token: Token,
        multiplier: Decimal?
    ) -> AnyPublisher<UInt64, Error> {
        Result {
            try makeRawTokenAmount(amount: amount, token: token, multiplier: multiplier)
        }
        .publisher
        .eraseToAnyPublisher()
    }

    private func makeRawTokenAmount(
        amount: Decimal,
        token: Token,
        multiplier: Decimal?
    ) throws -> UInt64 {
        let normalizedAmount = try ScaledUIAmount.unscale(displayed: amount, by: multiplier)
        let rawAmount = (normalizedAmount * token.decimalValue).rounded(scale: 0, roundingMode: .down)
        guard rawAmount >= 0, rawAmount <= Decimal(UInt64.max) else {
            throw BlockchainSdkError.failedToBuildTx
        }

        return rawAmount.uint64Value
    }

    func associatedTokenAddress(accountAddress: String, mintAddress: String, tokenProgramId: PublicKey) -> String? {
        guard
            let accountPublicKey = PublicKey(string: accountAddress),
            let tokenMintPublicKey = PublicKey(string: mintAddress),
            case .success(let associatedSourceTokenAddress) = PublicKey.associatedTokenAddress(walletAddress: accountPublicKey, tokenMintAddress: tokenMintPublicKey, tokenProgramId: tokenProgramId)
        else {
            return nil
        }

        return associatedSourceTokenAddress.base58EncodedString
    }
}

private extension SolanaWalletManager {
    enum Constants {
        static let nftComputeUnitPrice: UInt64 = 1_000_000
    }
}

extension SolanaWalletManager: RentProvider {
    func minimalBalanceForRentExemption() -> AnyPublisher<Amount, Error> {
        let amountValue = Amount(with: wallet.blockchain, value: mainAccountRentExemption)
        return .justWithError(output: amountValue).eraseToAnyPublisher()
    }

    func rentAmount() -> AnyPublisher<Amount, Error> {
        networkService.accountRentFeePerEpoch()
            .tryMap { [weak self] fee in
                guard let self = self else {
                    throw BlockchainSdkError.empty
                }

                let blockchain = wallet.blockchain
                return Amount(with: blockchain, type: .coin, value: fee)
            }
            .eraseToAnyPublisher()
    }
}

extension SolanaWalletManager: RentExtemptionRestrictable {
    var minimalAmountForRentExemption: Amount {
        Amount(with: wallet.blockchain, value: mainAccountRentExemption)
    }

    func validateDestinationForRentExemption(amount: Amount, fee: Fee, destination: DestinationType) async throws {
        // this check is valid for coins only
        guard amount.type == .coin else {
            return
        }

        // we assume that the destination for swap is created
        guard case .address = destination else {
            return
        }

        // unexpected case, should not happen
        guard let solanaFeeParameters = fee.parameters as? SolanaFeeParameters else {
            return
        }

        if solanaFeeParameters.destinationAccountExists {
            return
        }

        // The size of the uncreated account for coin transfer is space independent
        let minAmountValue = try await networkService.minimalBalanceForRentExemption(dataLength: 0).async()

        if amount.value >= minAmountValue {
            return
        }

        let minCoinAmount = Amount(with: wallet.blockchain, value: minAmountValue)
        throw ValidationError.sendingAmountIsLessThanRentExemption(amount: minCoinAmount)
    }
}

extension SolanaWalletManager: ThenProcessable {}

// MARK: - PendingTransactionRecordAdding

extension SolanaWalletManager: PendingTransactionRecordAdding {
    func addPendingTransaction(_ transaction: Transaction, hash: String) {
        let mapper = PendingTransactionRecordMapper()
        wallet.addPendingTransaction(mapper.mapToPendingTransactionRecord(transaction: transaction, hash: hash))
    }
}

// MARK: - StakeKitTransactionSender, StakingTransactionsBuilder

extension SolanaWalletManager: StakeKitTransactionSender, StakingTransactionsBuilder {
    struct RawTransactionData: CustomStringConvertible {
        let serializedData: String
        let blockhashFetchedAt: Date

        var description: String {
            serializedData
        }
    }

    typealias RawTransaction = RawTransactionData

    func buildRawTransactions<T: StakingTransaction>(
        from transactions: [T],
        publicKey: Wallet.PublicKey,
        signer: any TransactionSigner
    ) async throws -> [RawTransaction] {
        guard let transactions = transactions as? [StakeKitTransaction] else {
            throw BlockchainSdkError.failedToBuildTx
        }

        let blockhashFetchedAt = Date()
        let blockhash = Data(Base58.decode(try await networkService.getLatestBlockhash()))
        try Task.checkCancellation()

        let patchedTransactions: [Data] = try transactions.map { transaction in
            let original = Data(hex: transaction.unsignedData)
            let patched = try transactionHelper.replaceRecentBlockhash(blockhash, in: original)
            try transactionHelper.assertDiffersOnlyInRecentBlockhash(original: original, patched: patched)
            return patched
        }

        let hashes = try patchedTransactions.map {
            try transactionHelper.removeSignaturesPlaceholders(from: $0).transaction
        }

        let signatures: [SignatureInfo] = try await signer.sign(
            hashes: hashes,
            walletPublicKey: publicKey
        ).async()

        return try zip(patchedTransactions, signatures).map { patched, signature in
            RawTransactionData(
                serializedData: try transactionHelper.addSignature(signature.signature, transaction: patched),
                blockhashFetchedAt: blockhashFetchedAt
            )
        }
    }
}

extension SolanaWalletManager: StakeKitTransactionDataBroadcaster {
    func broadcast(rawTransaction: RawTransaction) async throws -> String {
        try await networkService.sendRaw(
            base64serializedTransaction: rawTransaction.serializedData,
            startSendingTimestamp: rawTransaction.blockhashFetchedAt
        ).async()
    }
}

// MARK: - CompiledTransactionSender & CompiledTransactionFeeProvider

extension SolanaWalletManager: CompiledTransactionSender, CompiledTransactionFeeProvider {
    func getFee(compiledTransaction data: Data) async throws -> [Fee] {
        let buildForSign = (try transactionHelper.removeSignaturesPlaceholders(from: data)).transaction

        let decimalFeeValue = try await networkService.getFeeForCompiled(message: buildForSign.base64EncodedString()).async()
        let feeAmount = Amount(with: wallet.blockchain, type: .coin, value: decimalFeeValue)

        return [Fee(feeAmount)]
    }

    func send(compiledTransaction data: Data, signer: any TransactionSigner) async throws -> TransactionSendResult {
        let walletKey = wallet.publicKey.blockchainKey
        let (prepared, signatures) = try await signer.sign(walletPublicKey: wallet.publicKey) { [networkService, transactionHelper] in
            guard let networkService else {
                throw BlockchainSdkError.empty
            }

            let blockhashFetchedAt = Date()
            let transaction = try await Self.refreshRecentBlockhash(
                in: data,
                walletKey: walletKey,
                networkService: networkService,
                transactionHelper: transactionHelper
            )
            let hashes = [try transactionHelper.removeSignaturesPlaceholders(from: transaction).transaction]
            return ((transaction: transaction, blockhashFetchedAt: blockhashFetchedAt), hashes)
        }

        guard let signature = signatures.first?.signature else {
            throw BlockchainSdkError.failedToSendTx
        }

        let buildForSend = try transactionHelper.putSignature(signature, publicKey: walletKey, transaction: prepared.transaction)

        let hash = try await networkService.sendRaw(
            base64serializedTransaction: buildForSend.base64EncodedString(),
            startSendingTimestamp: prepared.blockhashFetchedAt
        ).async()

        return TransactionSendResult(hash: hash, currentProviderHost: currentHost)
    }

    private static func refreshRecentBlockhash(
        in transaction: Data,
        walletKey: Data,
        networkService: SolanaNetworkService,
        transactionHelper: SolanaTransactionHelper
    ) async throws -> Data {
        guard
            try transactionHelper.isSoleRequiredSigner(walletKey, transaction: transaction),
            try !transactionHelper.usesDurableNonce(in: transaction)
        else {
            return transaction
        }

        let blockhash = Data(Base58.decode(try await networkService.getLatestBlockhash()))
        let patched = try transactionHelper.replaceRecentBlockhash(blockhash, in: transaction)

        try transactionHelper.assertDiffersOnlyInRecentBlockhash(original: transaction, patched: patched)
        return patched
    }
}

extension SolanaWalletManager: MinimalBalanceProvider {
    func minimalBalance() -> Decimal {
        minimalAmountForRentExemption.value
    }
}

extension SolanaWalletManager: ScaledUIAmountProvider {
    func fetchMultiplier(contractAddress: String) async throws -> Decimal? {
        let tokenProgramId = try await networkService.tokenProgramId(contractAddress: contractAddress).async()

        guard tokenProgramId == .token2022ProgramId else {
            return nil
        }

        return try await networkService.getScaledUIAmountMultiplier(
            mintAddress: contractAddress,
            transactionDate: Date()
        )
        .async()
    }
}
