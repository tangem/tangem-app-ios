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

class SolanaWalletManager: BaseManager, WalletManager {
    var networkService: SolanaNetworkService!

    var currentHost: String { networkService.host }

    /// Dictionary storing token account space requirements for each mint address.
    /// Used when sending tokens to accounts that don't exist yet to calculate minimum rent.
    /// Key is mint address, value is required space in bytes.
    var ownerTokenAccountSpacesByMint: [String: UInt64] = [:]

    /// It is taken into account in the calculation of the account rent commission for the sender
    private var mainAccountRentExemption: Decimal = 0

    private let transactionHelper = SolanaTransactionHelper()

    override func updateWalletManager() async throws {
        do {
            let tokens = cardTokens
            let info = try await networkService.getInfo(accountId: wallet.address, tokens: tokens).async()
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
    var allowsFeeSelection: Bool { false }

    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        let sendPublisher: AnyPublisher<TransactionID, Error>
        switch transaction.amount.type {
        case .coin:
            sendPublisher = sendSol(transaction, signer: signer)
        case .token(let token):
            sendPublisher = sendSplToken(transaction, token: token, signer: signer)
        case .reserve, .feeResource:
            return .sendTxFail(error: BlockchainSdkError.empty)
        }

        return sendPublisher
            .withWeakCaptureOf(self)
            .tryMap { manager, hash in
                let mapper = PendingTransactionRecordMapper()
                let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: hash)
                manager.wallet.addPendingTransaction(record)

                return TransactionSendResult(hash: hash, currentProviderHost: manager.currentHost)
            }
            .mapSendTxError()
            .eraseToAnyPublisher()
    }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
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

        let signer = SolanaTransactionSigner(transactionSigner: signer, walletPublicKey: wallet.publicKey)

        let decimalAmount = transaction.amount.value * wallet.blockchain.decimalValue
        let intAmount = (decimalAmount.rounded() as NSDecimalNumber).uint64Value

        return networkService.sendSol(
            amount: intAmount,
            computeUnitLimit: solanaFeeParameters.computeUnitLimit,
            computeUnitPrice: solanaFeeParameters.computeUnitPrice,
            destinationAddress: transaction.destinationAddress,
            signer: signer
        )
    }

    private func sendSplToken(_ transaction: Transaction, token: Token, signer: TransactionSigner) -> AnyPublisher<TransactionID, Error> {
        guard let solanaFeeParameters = transaction.fee.parameters as? SolanaFeeParameters else {
            return .anyFail(error: BlockchainSdkError.failedToSendTx)
        }

        let decimalAmount = transaction.amount.value * token.decimalValue
        let intAmount = (decimalAmount.rounded() as NSDecimalNumber).uint64Value
        let signer = SolanaTransactionSigner(transactionSigner: signer, walletPublicKey: wallet.publicKey)
        let tokenProgramIdPublisher = networkService.tokenProgramId(contractAddress: token.contractAddress)

        return tokenProgramIdPublisher
            .flatMap { [weak self] tokenProgramId -> AnyPublisher<TransactionID, Error> in
                guard let self else {
                    return .anyFail(error: BlockchainSdkError.empty)
                }

                guard
                    let associatedSourceTokenAccountAddress = associatedTokenAddress(accountAddress: transaction.sourceAddress, mintAddress: token.contractAddress, tokenProgramId: tokenProgramId)
                else {
                    return .anyFail(error: BlockchainSdkError.failedToConvertPublicKey)
                }

                return networkService.sendSplToken(
                    amount: intAmount,
                    computeUnitLimit: solanaFeeParameters.computeUnitLimit,
                    computeUnitPrice: solanaFeeParameters.computeUnitPrice,
                    sourceTokenAddress: associatedSourceTokenAccountAddress,
                    destinationAddress: transaction.destinationAddress,
                    token: token,
                    tokenProgramId: tokenProgramId,
                    signer: signer
                )
            }
            .eraseToAnyPublisher()
    }

    private func associatedTokenAddress(accountAddress: String, mintAddress: String, tokenProgramId: PublicKey) -> String? {
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

// MARK: - StakeKitTransactionSender, StakeKitTransactionSenderProvider

extension SolanaWalletManager: StakeKitTransactionSender, StakingTransactionsBuilder, StakeKitTransactionDataProvider {
    struct RawTransactionData: CustomStringConvertible {
        let serializedData: String
        let blockhashDate: Date

        var description: String {
            serializedData
        }
    }

    typealias RawTransaction = RawTransactionData

    func prepareDataForSign(transaction: StakeKitTransaction) throws -> Data {
        let transactionData = Data(hex: transaction.unsignedData)
        let prepared = try transactionHelper.removeSignaturesPlaceholders(from: transactionData)
        return prepared.transaction
    }

    func prepareDataForSend(transaction: StakeKitTransaction, signature: SignatureInfo) throws -> RawTransaction {
        let signedTransaction = try transactionHelper.addSignature(
            signature.signature,
            transaction: Data(hex: transaction.unsignedData)
        )

        guard let solanaBlockhashDate = transaction.solanaBlockhashDate else {
            throw BlockchainSdkError.failedToBuildTx
        }

        return RawTransactionData(
            serializedData: signedTransaction,
            blockhashDate: solanaBlockhashDate
        )
    }
}

extension SolanaWalletManager: StakeKitTransactionDataBroadcaster {
    func broadcast(rawTransaction: RawTransaction) async throws -> String {
        try await networkService.sendRaw(
            base64serializedTransaction: rawTransaction.serializedData,
            startSendingTimestamp: rawTransaction.blockhashDate
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
        guard let walletPublicKey = SolanaSwift.PublicKey(data: wallet.publicKey.blockchainKey) else {
            let error = BlockchainSdkError.failedToBuildTx
            BSDKLogger.error(error: error)
            throw error
        }

        let solanaSigner = SolanaTransactionSigner(
            transactionSigner: signer,
            walletPublicKey: wallet.publicKey
        )

        let transaction: VersionedTransaction

        do {
            transaction = try VersionedTransaction.deserialize(data: data, isIncludeSignature: true)
        } catch {
            BSDKLogger.error(error: error)
            throw error
        }

        let buildForSign = try transaction.prepareForSign()
        let signature = try await solanaSigner.sign(message: buildForSign)
        let signatures = [Signature(signature: signature, publicKey: walletPublicKey)]
        try transaction.prepareForSend(signatures: signatures)
        let buildForSend = try transaction.serialize()

        let hash = try await networkService.sendRaw(
            base64serializedTransaction: buildForSend.base64EncodedString(),
            startSendingTimestamp: Date()
        ).async()

        return TransactionSendResult(hash: hash, currentProviderHost: currentHost)
    }
}

extension SolanaWalletManager: MinimalBalanceProvider {
    func minimalBalance() -> Decimal {
        minimalAmountForRentExemption.value
    }
}
