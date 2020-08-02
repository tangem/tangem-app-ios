//
//  DucatusEngine.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Smart Cash AG. All rights reserved.
//

import Foundation
import Moya

class DucatusEngine: LTCEngine {
   let provider = MoyaProvider<BitcoreTarget>(plugins: [NetworkLoggerPlugin()])
    
    private let _payIdManager = PayIdManager(network: .DUC)
    override var payIdManager: PayIdManager? {
        return _payIdManager
    }
    
    override var trait: CoinTrait {
        .all
    }
    
    override var blockchainDisplayName: String {
        return "Ducatus"
    }
    
    override var walletType: WalletType {
        return .ducatus
    }
    
    override var walletUnits: String {
        return "DUC"
    }
    
    override var qrCodePreffix: String {
        return ""
    }
    
    override var exploreLink: String {
        return "https://insight.ducatus.io/#/DUC/mainnet/address/" + walletAddress
    }
    
    override func setupAddress() {
        let hash = Data(card.walletPublicKeyBytesArray.sha256())
        let ripemd160Hash = RIPEMD160.hash(message: hash)
        let netSelectionByte = Byte(0x31).asData
        let extendedRipemd160Hash = netSelectionByte + ripemd160Hash
        let sha = extendedRipemd160Hash.sha256().sha256()
        let ripemd160HashWithChecksum = extendedRipemd160Hash + sha[..<4]
        let base58 = String(base58Encoding: ripemd160HashWithChecksum, alphabet:Base58String.btcAlphabet)
        
        walletAddress = base58
        card.node = randomNode()
    }
    
    
    override func getFee(targetAddress: String, amount: String, completion: @escaping ((min: String, normal: String, max: String)?) -> Void) {
        guard let _ = self.getHashForSignature(amount: amount, fee: "0.00000001", includeFee: true, targetAddress: targetAddress),
            let txRefs = self.addressResponse?.txrefs,
            let testTx  = self.buildTxForSend(signFromCard: [UInt8](repeating: UInt8(0x01), count: 64 * txRefs.count), txRefs: txRefs, publicKey: self.card.walletPublicKeyBytesArray) else {
                completion(nil)
                return
        }
        let estimatedTxSize = Decimal(testTx.count + 1)
        let minFee = Decimal(0.00000089) * estimatedTxSize
        let normalFee = Decimal(0.00000144) * estimatedTxSize
        let maxFee = Decimal(0.00000350) * estimatedTxSize
        
        let fee = ("\(minFee.rounded(blockchain: .ducatus))",
            "\(normalFee.rounded(blockchain: .ducatus))",
            "\(maxFee.rounded(blockchain: .ducatus))")
        completion(fee)
    }
    
    override func sendToBlockchain(signFromCard: [UInt8], completion: @escaping (Bool, Error?) -> Void) {
        guard let txRefs = addressResponse?.txrefs,
            let txToSend = buildTxForSend(signFromCard: signFromCard, txRefs: txRefs, publicKey: card.walletPublicKeyBytesArray) else {
                completion(false, "Empty transaction. Try again")
                return
        }
        
        let txHexString = txToSend.toHexString()
        provider.request(.send(txHex: txHexString)) { [weak self] result in
            switch result {
            case .success(let response):
                if let sendResponse = try? response.map(BitcoreSendResponse.self),
                    sendResponse.txid != nil {
                    self?.unconfirmedBalance = nil
                    completion(true, nil)
                } else {
                    completion(false, "Unknown send error")
                }
            case .failure(let error):
                completion(false,error)
            }
        }
    }
}
