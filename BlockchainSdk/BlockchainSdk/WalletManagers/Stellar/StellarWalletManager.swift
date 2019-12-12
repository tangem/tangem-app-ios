//
//  StellarWalletmanager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import stellarsdk
import SwiftyJSON

enum StellarError: Error {
    case noFee
    case failedToBuildTransaction
}

class StellarWalletManager: WalletManager {    
    var wallet: Wallet { return _wallet }
    
    private var _wallet: CurrencyWallet
    private let cardId: String
    private var baseFee: Decimal?
    private let txBuilder: StellarTransactionBuilder
    private let stellarSdk: StellarSDK
    
    init(cardId: String, walletPublicKey: Data, walletConfig: WalletConfig, asset: Token?, isTestnet: Bool) {
        
        let url = isTestnet ? "https://horizon-testnet.stellar.org" : "https://horizon.stellar.org"
        self.stellarSdk = StellarSDK(withHorizonUrl: url)
        //self.asset = asset
        self.cardId = cardId
        let blockchain: Blockchain = isTestnet ? .stellarTestnet: .stellar
        let address = blockchain.makeAddress(from: walletPublicKey)
        self._wallet = CurrencyWallet(address: address, blockchain: blockchain, config: walletConfig)
        
        if let asset = asset {
            let assetAmount = Amount(type: .token, currencySymbol: asset.symbol, value: nil, address: asset.contractAddress, decimals: asset.decimals)
            _wallet.addAmount(assetAmount)
        }
        
        self.txBuilder = StellarTransactionBuilder(stellarSdk: stellarSdk, walletPublicKey: walletPublicKey, isTestnet: isTestnet)
    }
    
    func update() {
        
    }
}

extension StellarWalletManager: TransactionSender {
    func send(_ transaction: Transaction, signer: TransactionSigner, completion: @escaping (Result<Bool, Error>) -> Void) {
        txBuilder.buildForSign(transaction: transaction) {[weak self] buildForSignResponse in
            guard let self = self else { return }
            
            guard let buildForSignResponse = buildForSignResponse else {
                completion(.failure(StellarError.failedToBuildTransaction))
                return
            }
            
            signer.sign(hashes: [buildForSignResponse.hash], cardId: self.cardId) {[weak self] result in
                switch result {
                case .event(let response):
                    guard let self = self else { return }
                    
                    guard let tx = self.txBuilder.buildForSend(signature: response.signature, transaction: buildForSignResponse.transaction) else {
                        completion(.failure(BitcoinError.failedToBuildTransaction))
                        return
                    }
                    
                    self.stellarSdk.transactions.postTransaction(transactionEnvelope: tx) {[weak self] postResponse -> Void in
                        switch postResponse {
                        case .success(let submitTransactionResponse):
                            if submitTransactionResponse.transactionResult.code == .success {
                                //self?.latestTxDate = Date()
                                completion(.success(true))
                            } else {
                                print(submitTransactionResponse.transactionResult.code)
                                completion(.failure("Result code: \(submitTransactionResponse.transactionResult.code)"))
                            }
                        case .failure(let horizonRequestError):
                            let horizonMessage = horizonRequestError.message
                            let json = JSON(parseJSON: horizonMessage)
                            let detailMessage = json["detail"].stringValue
                            let extras = json["extras"]
                            let codes = extras["result_codes"].rawString() ?? ""
                            let errorMessage: String = (!detailMessage.isEmpty && !codes.isEmpty) ? "\(detailMessage). Codes: \(codes)" : horizonMessage
                            completion(.failure(errorMessage))
                        }
                    }
                    
                case .completion(let error):
                    if let error = error {
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
}

extension StellarWalletManager: FeeProvider {
    func getFee(amount: Amount, source: String, destination: String, completion: @escaping (Result<[Amount], Error>) -> Void) {
        if let fee = self.baseFee {
            let feeAmount = Amount(type: .coin, currencySymbol: wallet.blockchain.currencySymbol, value: fee, address: source, decimals: wallet.blockchain.decimalCount)
            completion(.success([feeAmount]))
        } else {
            completion(.failure(StellarError.noFee))
        }
    }
}

class StellarTransactionBuilder {
    public var sequence: Int64?
    
    private let stellarSdk: StellarSDK
    private let walletPublicKey: Data
    private let isTestnet: Bool
    
    init(stellarSdk: StellarSDK, walletPublicKey: Data, isTestnet: Bool) {
        self.stellarSdk = stellarSdk
        self.walletPublicKey = walletPublicKey
        self.isTestnet = isTestnet
    }
    
    public func buildForSign(transaction: Transaction, completion: @escaping ((hash: Data, transaction: stellarsdk.TransactionXDR)?) -> Void ) {
        guard let destinationKeyPair = try? KeyPair(accountId: transaction.destinationAddress),
            let sourceKeyPair = try? KeyPair(accountId: transaction.sourceAddress) else {
                completion(nil)
                return
        }
        
        if transaction.amount.type == .coin {
            guard let amount = transaction.amount.value else {
                completion(nil)
                return
            }
            
            checkIfAccountCreated(transaction.destinationAddress) { [weak self] isCreated in
                let operation = isCreated ? PaymentOperation(sourceAccount: sourceKeyPair,
                                                             destination: destinationKeyPair,
                                                             asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                                                             amount: amount ) :
                    CreateAccountOperation(destination: destinationKeyPair, startBalance: amount)
                
                self?.serializeOperation(operation, sourceKeyPair: sourceKeyPair, completion: completion)
            }
        } else if transaction.amount.type == .token {
            guard let keyPair = try? KeyPair(accountId: transaction.amount.address),
                let asset = createNonNativeAsset(code: transaction.amount.currencySymbol, issuer: keyPair) else {
                    completion(nil)
                    return
            }
            
            var operation: stellarsdk.Operation
            if let amount = transaction.amount.value {
                operation = PaymentOperation(sourceAccount: sourceKeyPair,
                                             destination: destinationKeyPair,
                                             asset: asset,
                                             amount: amount)
            } else {
                operation = ChangeTrustOperation(sourceAccount: sourceKeyPair, asset: asset, limit: Decimal(string: "900000000000.0000000"))
            }
            
            serializeOperation(operation, sourceKeyPair: sourceKeyPair, completion: completion)
        }
        assertionFailure("unsuported amount type")
        completion(nil)
    }
    
    public func buildForSend(signature: Data, transaction: TransactionXDR) -> String? {
        var transaction = transaction
        var publicKeyData = walletPublicKey
        let hint = Data(bytes: &publicKeyData, count: publicKeyData.count).suffix(4)
        let decoratedSignature = DecoratedSignatureXDR(hint: WrappedData4(hint), signature: signature)
        transaction.addSignature(signature: decoratedSignature)
        let envelope = try? transaction.encodedEnvelope()
        return envelope
    }
    
    private func createNonNativeAsset(code: String, issuer: KeyPair) -> Asset? {
        if code.count >= 1 && code.count <= 4 {
            return Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: code, issuer: issuer)
        } else if code.count >= 5 && code.count <= 12 {
            return Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM12, code: code, issuer: issuer)
        } else {
            return nil
        }
    }
    
    private func checkIfAccountCreated(_ address: String, completion: @escaping (Bool) -> Void) {
        stellarSdk.accounts.getAccountDetails(accountId: address) { response -> (Void) in
            switch response {
            case .success(_):
                completion(true)
            case .failure(_):
                completion(false)
            }
        }
    }
    
    private func serializeOperation(_ operation: stellarsdk.Operation, sourceKeyPair: KeyPair, completion: @escaping ((hash: Data, transaction: stellarsdk.TransactionXDR)?) -> Void ) {
        guard let xdrOperation = try? operation.toXDR(),
            let seqNumber = sequence else {
                completion(nil)
                return
        }
        
        let currentTime = Date().timeIntervalSince1970
        let minTime = currentTime - 60.0
        let maxTime = currentTime + 60.0
        
        let tx = TransactionXDR(sourceAccount: sourceKeyPair.publicKey,
                                seqNum: seqNumber + 1,
                                timeBounds:  TimeBoundsXDR(minTime: UInt64(minTime), maxTime: UInt64(maxTime)),
                                memo: Memo.none.toXDR(),
                                operations: [xdrOperation])
        
        let network = isTestnet ? Network.testnet : Network.public
        guard let hash = try? tx.hash(network: network) else {
            completion(nil)
            return
        }
        
        completion((hash, tx))
    }
}

extension HorizonRequestError {
    var message: String {
        switch self {
        case .emptyResponse:
            return "emptyResponse"
        case .beforeHistory(let message, _):
            return message
        case .badRequest(let message, _):
            return message
        case .errorOnStreamReceive(let message):
            return message
        case .forbidden(let message, _):
            return message
        case .internalServerError(let message, _):
            return message
        case .notAcceptable(let message, _):
            return message
        case .notFound(let message, _):
            return message
        case .notImplemented(let message, _):
            return message
        case .parsingResponseFailed(let message):
            return message
        case .rateLimitExceeded(let message, _):
            return message
        case .requestFailed(let message):
            return message
        case .staleHistory(let message, _):
            return message
        case .unauthorized(let message):
            return message
        }
    }
}
