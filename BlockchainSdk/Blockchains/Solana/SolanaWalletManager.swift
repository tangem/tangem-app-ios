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
    var solanaSdk: Solana!
    var networkService: SolanaNetworkService!

    var currentHost: String { networkService.host }

    /// Dictionary storing token account space requirements for each mint address.
    /// Used when sending tokens to accounts that don't exist yet to calculate minimum rent.
    /// Key is mint address, value is required space in bytes.
    var ownerTokenAccountSpacesByMint: [String: UInt64] = [:]

    /// It is taken into account in the calculation of the account rent commission for the sender
    private var mainAccountRentExemption: Decimal = 0

    override func update(completion: @escaping (Result<Void, Error>) -> Void) {
        cancellable = networkService.getInfo(accountId: wallet.address, tokens: cardTokens)
            .sink { [weak self] in
                switch $0 {
                case .failure(let error):
                    self?.wallet.clearAmounts()
                    completion(.failure(error))
                case .finished:
                    completion(.success(()))
                }
            } receiveValue: { [weak self] info in
                self?.updateWallet(info: info)
            }
    }

    private func updateWallet(info: SolanaAccountInfoResponse) {
        mainAccountRentExemption = info.mainAccountRentExemption

        // Store token account sizes for define minimal rent when destination token account is not created
        ownerTokenAccountSpacesByMint = info.tokensByMint.reduce(into: [:]) { $0[$1.key] = $1.value.space }

        wallet.add(coinValue: info.balance)

        for cardToken in cardTokens {
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
            return .sendTxFail(error: WalletError.empty)
        }

        return sendPublisher
            .tryMap { [weak self] hash in
                guard let self else {
                    throw WalletError.empty
                }

                let mapper = PendingTransactionRecordMapper()
                let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: hash)
                wallet.addPendingTransaction(record)

                return TransactionSendResult(hash: hash)
            }
            .eraseSendError()
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
            return .anyFail(error: WalletError.failedToSendTx)
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
            return .anyFail(error: WalletError.failedToSendTx)
        }

        let decimalAmount = transaction.amount.value * token.decimalValue
        let intAmount = (decimalAmount.rounded() as NSDecimalNumber).uint64Value
        let signer = SolanaTransactionSigner(transactionSigner: signer, walletPublicKey: wallet.publicKey)
        let tokenProgramIdPublisher = networkService.tokenProgramId(contractAddress: token.contractAddress)

        return tokenProgramIdPublisher
            .flatMap { [weak self] tokenProgramId -> AnyPublisher<TransactionID, Error> in
                guard let self else {
                    return .anyFail(error: WalletError.empty)
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
                    throw WalletError.empty
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

extension SolanaWalletManager: StakeKitTransactionsBuilder, StakeKitTransactionSender, StakeKitTransactionDataProvider {
    struct RawTransactionData: CustomStringConvertible {
        let serializedData: String
        let blockhashDate: Date

        var description: String {
            serializedData
        }
    }

    typealias RawTransaction = RawTransactionData

    func prepareDataForSign(transaction: StakeKitTransaction) throws -> Data {
        try SolanaStakeKitTransactionHelper().prepareForSign(transaction.unsignedData)
    }

    func prepareDataForSend(transaction: StakeKitTransaction, signature: SignatureInfo) throws -> RawTransaction {
        let signedTransaction = try SolanaStakeKitTransactionHelper().prepareForSend(
            transaction.unsignedData,
            signature: signature.signature
        )
        return RawTransactionData(
            serializedData: signedTransaction,
            blockhashDate: transaction.params.solanaBlockhashDate
        )
    }
}

extension SolanaWalletManager: StakeKitTransactionDataBroadcaster {
    func broadcast(transaction: StakeKitTransaction, rawTransaction: RawTransaction) async throws -> String {
        try await networkService.sendRaw(
            base64serializedTransaction: rawTransaction.serializedData,
            startSendingTimestamp: rawTransaction.blockhashDate
        ).async()
    }
}
