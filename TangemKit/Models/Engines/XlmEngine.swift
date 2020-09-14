//
//  XlmEngine.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation
import stellarsdk
import SwiftyJSON

public class XlmEngine: CardEngine, PayIdProvider {
    unowned public var card: CardViewModel

    private let _payIdManager = PayIdManager(network: .XLM)
    var payIdManager: PayIdManager? {
        if walletType == .slix2 {
            return nil
        } else {
            return _payIdManager
        }
    }

    public lazy var stellarSdk: StellarSDK = {
        return StellarSDK(withHorizonUrl: "https://\(card.node)")
    }()
    
    public var blockchainDisplayName: String {
        if walletType == .slix2 {
            return
                """
                Tangem TAG
                Stellar non-fungible token
                """
        }
        else {
            return  card.tokenSymbol == nil ?  "Stellar" : "Stellar Asset"
        }
    }
    
    public var walletType: WalletType {
        if card.productMask.contains(.tag) { //slix tag
            return .slix2
        }
        
        return .stellar
    }
    
    public var walletUnits: String {
        return "XLM"
    }
    
    public var qrCodePreffix: String {
        return ""
    }
    
    public var walletReserve: String?

    public var walletAddress: String = ""
    var sequence: Int64?
    var baseReserve: Decimal?
    var baseFee: Decimal?
    var latestTxDate: Date?
    var transaction: TransactionXDR?
    var useTimebounds = true
    var hasIncomingTrustedTx: Bool = false
    var hasOutgoingTrustedTx: Bool = false
    public var assetBalance: Decimal?
    public var assetCode: String?
    
    var sourceKeyPair: KeyPair?
    
    public var exploreLink: String {
        let baseUrl = card.isTestBlockchain ? "https://stellar.expert/explorer/testnet/account/" : "https://stellar.expert/explorer/public/account/"
        return baseUrl + walletAddress
    }
    
    public required init(card: CardViewModel) {
        self.card = card
        if card.isWallet {
            setupAddress()
        }
    }
    
    public func setupAddress() {        
        guard let keyPair = try? KeyPair(publicKey: PublicKey(card.walletPublicKeyBytesArray)) else {
            return
        }
        sourceKeyPair = keyPair
        walletAddress = keyPair.accountId
        card.node = card.isTestBlockchain ? "horizon-testnet.stellar.org" : "horizon.stellar.org"
        
    }
}

extension XlmEngine: CoinProvider, CoinProviderAsync {
    public func getApiDescription() -> String {
        return "main"
    }
    
    public var hasPendingTransactions: Bool {
        guard let txDate = latestTxDate else {
            return false
        }
        
        let sinceTxInterval = DateInterval(start: txDate, end: Date()).duration
        let expired = Int(sinceTxInterval) > 10
        if expired {
            latestTxDate = nil
            return false
        }
        return true
    }
    
    public var coinTraitCollection: CoinTrait {        
        if let assetBalance = self.assetBalance, assetBalance > 0 {
            return .none
        } else {
            return .allowsFeeInclude
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
    
    public func getHashForSignature(amount: String, fee: String, includeFee: Bool, targetAddress: String, completion: @escaping ([Data]?, Error?) -> Void) {
        guard let amountDecimal = Decimal(string: amount),
            let feeDecimal = Decimal(string: fee),
            let sourceKeyPair = self.sourceKeyPair,
            let destinationKeyPair = try? KeyPair(accountId: targetAddress) else {
                completion(nil, nil)
                return
        }
        let assetBalance = self.assetBalance ?? 0
        let finalAmountDecimal = includeFee && assetBalance == 0  ? amountDecimal - feeDecimal : amountDecimal
        
        if card.tokenSymbol == nil || (card.tokenSymbol != nil && self.assetBalance != nil && self.assetBalance! <= 0) {
            checkIfAccountCreated(targetAddress) { [weak self] isCreated in
                if !isCreated && finalAmountDecimal < 1 {
                    completion(nil, Localizations.xlmCreateAccountHint)
                    return
                }
                
                
                let operation = isCreated ? PaymentOperation(sourceAccount: nil,
                                                             destination: destinationKeyPair,
                                                             asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                                                             amount: finalAmountDecimal) :
                    CreateAccountOperation(destination: destinationKeyPair, startBalance: finalAmountDecimal)
                
                self?.serializeOperation(operation, completion: completion)
            }
        } else { //if asset
            guard let contractAddress = card.tokenContractAddress, let keyPair = try? KeyPair(accountId: contractAddress),
                let asset = createNonNativeAsset(code: card.tokenSymbol!, issuer: keyPair) else {
                    completion(nil, nil)
                    return
            }
             
            if self.assetBalance == nil {
                let operation = ChangeTrustOperation(sourceAccount: sourceKeyPair, asset: asset, limit: Decimal(string: "900000000000.0000000"))
                 serializeOperation(operation, completion: completion)
            } else {
              checkIfAccountCreated(targetAddress) { [weak self] isCreated in
                if !isCreated {
                    completion(nil, Localizations.xlmAssetCreateAccountHint)
                    return
                }
                
                let operation = PaymentOperation(sourceAccount: sourceKeyPair,
                                                destination: destinationKeyPair,
                                                asset: asset,
                                                amount: finalAmountDecimal)
                           
                self?.serializeOperation(operation, completion: completion)
                }
            }
        }
    }
    
    private func serializeOperation(_ operation: stellarsdk.Operation, completion: @escaping ([Data]?, Error?) -> Void ) {
        guard let xdrOperation = try? operation.toXDR(),
            let seqNumber = self.sequence,
            let sourceKeyPair = self.sourceKeyPair else {
                completion(nil, nil)
                return
        }
        
        let currentTime = Date().timeIntervalSince1970
        let minTime = currentTime - 60.0
        let maxTime = currentTime + 60.0
        
        let tx = TransactionXDR(sourceAccount: sourceKeyPair.publicKey,
                                seqNum: seqNumber + 1,
                                timeBounds:  useTimebounds ? TimeBoundsXDR(minTime: UInt64(minTime), maxTime: UInt64(maxTime)) : nil,
                                memo: Memo.text("").toXDR(),
                                operations: [xdrOperation])
        
        let network = self.card.isTestBlockchain ? Network.testnet : Network.public
        guard let hash = try? tx.hash(network: network) else {
            completion(nil, nil)
            return
        }
        self.transaction = tx
        completion([hash], nil)
    }
    
    
    
    public func getHashForSignature(amount: String, fee: String, includeFee: Bool, targetAddress: String) -> [Data]? {
        return nil
    }
    
    public func sendToBlockchain(signFromCard: [UInt8], completion: @escaping (Bool, Error?) -> Void) {
        guard transaction != nil else {
            completion(false, "Empty transaction. Try again")
            return
        }
        
        var publicKeyData = card.walletPublicKeyBytesArray
        let hint = Data(bytes: &publicKeyData, count: publicKeyData.count).suffix(4)
        let decoratedSignature = DecoratedSignatureXDR(hint: WrappedData4(hint), signature: Data(signFromCard))
        transaction!.addSignature(signature: decoratedSignature)
        
        guard let envelope = try? transaction!.encodedEnvelope() else {
            completion(false, "Failed to encode envelope. Try again")
            return
        }
        stellarSdk.transactions.postTransaction(transactionEnvelope: envelope) {[weak self] postResponse -> Void in
            switch postResponse {
            case .success(let submitTransactionResponse):
                if submitTransactionResponse.transactionResult.code == .success {
                    self?.latestTxDate = Date()
                    completion(true, nil)
                } else {
                    print(submitTransactionResponse.transactionResult.code)
                    completion(false, "Result code: \(submitTransactionResponse.transactionResult.code)")
                }
                break
                 case .destinationRequiresMemo(let destinationAccountId):
                   completion(false, "Destination \(destinationAccountId) requires Memo")
            case .failure(let horizonRequestError):
                let horizonMessage = horizonRequestError.message
                let json = JSON(parseJSON: horizonMessage)
                let detailMessage = json["detail"].stringValue
                let extras = json["extras"]
                let codes = extras["result_codes"].rawString() ?? ""
                let errorMessage: String = (!detailMessage.isEmpty && !codes.isEmpty) ? "\(detailMessage). Codes: \(codes)" : horizonMessage
                completion(false, errorMessage)
            }
        }
    }
    
    public func getFee(targetAddress: String, amount: String, completion: @escaping ((min: String, normal: String, max: String)?) -> Void) {
        guard let fee = baseFee else {
            completion(nil)
            return
        }
        let feeString = "\(fee)"
        completion((feeString,feeString,feeString))
    }
    
    public func validate(address: String) -> Bool {
        let keyPair = try? KeyPair(accountId: address)
        return keyPair != nil
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

extension XlmEngine: Claimable {
    public var claimStatus: ClaimStatus {
        let balance =  NSDecimalNumber(string: card.walletValue).doubleValue
        if balance > 0.0 && hasIncomingTrustedTx {
            return .genuine
        } else if balance == 0.0 && hasIncomingTrustedTx && hasOutgoingTrustedTx {
            return .claimed
        }
        
        return .notGenuine
    }
    
    public func claim(amount: String, fee: String, targetAddress: String, signature: Data, completion: @escaping (Bool, Error?) -> Void) {
        useTimebounds = false
        getHashForSignature(amount: amount, fee: fee, includeFee: false, targetAddress: targetAddress) {[weak self] _ , _ in
            self?.sendToBlockchain(signFromCard: Array(signature), completion: completion)
        }
    }
}
