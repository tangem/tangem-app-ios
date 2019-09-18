//
//  BTCEngine.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation

class BTCEngine: CardEngine {
    
    unowned var card: Card
    var currentBackend = BtcBackend.blockchainInfo
    
    private let operationQueue = OperationQueue()
    var addressResponse: BtcResponse? {
        didSet {
            unconfirmedBalance = addressResponse?.unconfirmed_balance
        }
    }
    var unconfirmedBalance: Int?
    var blockchainDisplayName: String {
        return "Bitcoin"
    }
    
    var walletType: WalletType {
        return .btc
    }
    
    var walletUnits: String {
        return "BTC"
    }
    
    var qrCodePreffix: String {
        return "bitcoin:"
    }
    
    var walletAddress: String = ""
    var exploreLink: String {
        return "https://blockchain.info/address/" + walletAddress
    }
    
    required init(card: Card) {
        self.card = card
        if card.isWallet {
            setupAddress()
        }
    }
    
    func setupAddress() {
        let hexPublicKey = card.walletPublicKey
        
        let binaryPublicKey = dataWithHexString(hex: hexPublicKey)
        
        guard let binaryHash = sha256(binaryPublicKey) else {
            assertionFailure()
            return
        }
        
        let binaryRipemd160 = RIPEMD160.hash(message: binaryHash)
        let netSelectionByte = card.isTestBlockchain ? "6f" : "00"
        let hexRipend160 = netSelectionByte + binaryRipemd160.hexEncodedString()
        
        let binaryExtendedRipemd = dataWithHexString(hex: hexRipend160)
        guard let binaryOneSha = sha256(binaryExtendedRipemd) else {
            assertionFailure()
            return
        }
        
        guard let binaryTwoSha = sha256(binaryOneSha) else {
            assertionFailure()
            return
        }
        
        let binaryTwoShaToHex = binaryTwoSha.hexEncodedString()
        let checkHex = String(binaryTwoShaToHex[..<binaryTwoShaToHex.index(binaryTwoShaToHex.startIndex, offsetBy: 8)])
        let addCheckToRipemd = hexRipend160 + checkHex
        
        let binaryForBase58 = dataWithHexString(hex: addCheckToRipemd)
        
        walletAddress = String(base58Encoding: binaryForBase58) 
        
        card.node = randomNode() 
    }
    
    var targetAddress: String?
    var amount: Decimal?
    var change: Decimal?
    
    func switchBackend() {
        currentBackend =  (currentBackend == .blockcypher) ? .blockchainInfo : .blockcypher
    }
}

extension BTCEngine: CoinProvider {
    var coinTraitCollection: CoinTrait {
        return CoinTrait.all
    }
    
    func buildPrefix(for data: Data) -> Data {
        switch data.count {
        case 0..<Int(Op.pushData1.rawValue):
            return Data([data.count.byte])
        case Int(Op.pushData1.rawValue)..<Int(0xff):
            let prefix = [Op.pushData1.rawValue] + [data.count.byte]
            return Data(prefix)
        case Int(0xff)..<Int(0xffff):
            let prefix = [Op.pushData2.rawValue] + data.count.bytes2
            return Data(prefix)
        default:
            let prefix = [Op.pushData4.rawValue] + data.count.bytes4
            return Data(prefix)
        }
    }
    
    func buildOutputScript(address: String) -> [UInt8]? {
        let decoded = address.base58DecodedData!
        let first = decoded[0]
        let data = decoded[1...20]
        //P2H
        if (first == 0 || first == 111 || first == 48) { //0 for BTC/BCH 1 address | 48 for LTC L address
            return [Op.dup.rawValue, Op.hash160.rawValue ] + buildPrefix(for: data) + data + [Op.equalVerify.rawValue, Op.checkSig.rawValue]
        }
        //P2SH
        if(first == 5 || first == 0xc4 || first == 50) { //5 for BTC/BCH/LTC 3 address | 50 for LTC M address
            return [Op.hash160.rawValue] + data + [Op.equal.rawValue]
        }        
        return nil
    }
    
    func buildUnspents(with outputScripts:[[UInt8]], txRefs: [BtcTx]) -> [UnspentTransaction]? {
        let unspentTransactions: [UnspentTransaction] = txRefs.enumerated().compactMap({ index, txRef  in
            guard let hash = txRef.tx_hash.asciiHexToData() else {
                return nil
            }
            
            let outputScript = outputScripts.count == 1 ? outputScripts.first! : outputScripts[index]
            return UnspentTransaction(amount: txRef.value, outputIndex: txRef.tx_output_n, hash: hash, outputScript: outputScript)
        })
        
        return unspentTransactions
    }
    
    func getHashForSignature(amount: String, fee: String, includeFee: Bool, targetAddress: String) -> Data? {
        guard let txRefs = addressResponse?.txrefs else {
            return nil
        }
        
        guard let outputScript = buildOutputScript(address: walletAddress) else {
            return nil
        }
        
        guard let unspentTransactions = buildUnspents(with: [outputScript], txRefs: txRefs) else {
            return nil
        }
        
        let fullAmount = Decimal(unspentTransactions.reduce(0, {$0 + $1.amount}))
        guard let feeValue = Decimal(string: fee),
            let amountValue = Decimal(string: amount) else {
                return nil
        }
        
        let feeSatoshi = feeValue * Decimal(100000000)
        var amountSatoshi = amountValue * Decimal(100000000)
        var change = fullAmount - amountSatoshi
        if includeFee {
            amountSatoshi -= feeSatoshi;
        } else {
            change -= feeSatoshi;
        }
        
        self.targetAddress = targetAddress
        self.amount = amountSatoshi
        self.change = change
        
        var hashes = [UInt8]()
        
        for index in 0..<unspentTransactions.count {
            guard var txToSign = buildTxBody(unspentTransactions: unspentTransactions, amount: amountSatoshi, change: change, targetAddress: targetAddress, index: index) else {
                return nil
            }
            txToSign.append(contentsOf: [UInt8(0x01),UInt8(0x00),UInt8(0x00),UInt8(0x00)])
            hashes.append(contentsOf: txToSign.sha256().sha256())
        }
        
        let returnData = Data(hashes)
        return returnData
    }
    
    func buildTxBody(unspentTransactions: [UnspentTransaction], amount: Decimal, change: Decimal, targetAddress: String, index: Int?) -> [UInt8]? {
        var txToSign = [UInt8]()
        // version
        txToSign.append(contentsOf: [UInt8(0x01),UInt8(0x00),UInt8(0x00),UInt8(0x00)])
        
        //01
        txToSign.append(unspentTransactions.count.byte)
        
        //hex str hash prev btc
        
        
        for (inputIndex, input) in unspentTransactions.reversed().enumerated() {
            let hashKey: [UInt8] = input.hash.reversed()
            txToSign.append(contentsOf: hashKey)
            txToSign.append(contentsOf: input.outputIndex.bytes4)
            if (index == nil) || (inputIndex == index) {
                txToSign.append(input.outputScript.count.byte)
                txToSign.append(contentsOf: input.outputScript)
            } else {
                txToSign.append(UInt8(0x00))
            }
            //ffffffff
            txToSign.append(contentsOf: [UInt8(0xff),UInt8(0xff),UInt8(0xff),UInt8(0xff)]) // sequence
        }
        
        //02
        let outputCount = change == 0 ? 1 : 2
        txToSign.append(outputCount.byte)
        
        //8 bytes
        txToSign.append(contentsOf: amount.bytes8)
        guard let outputScriptBytes = buildOutputScript(address: targetAddress) else {
            return nil
        }
        //hex str 1976a914....88ac
        txToSign.append(outputScriptBytes.count.byte)
        txToSign.append(contentsOf: outputScriptBytes)
        
        if change != 0 {
            //8 bytes
            txToSign.append(contentsOf: change.bytes8)
            //hex str 1976a914....88ac
            guard let outputScriptChangeBytes = buildOutputScript(address: walletAddress) else {
                return nil
            }
            txToSign.append(outputScriptChangeBytes.count.byte)
            txToSign.append(contentsOf: outputScriptChangeBytes)
        }
        //00000000
        txToSign.append(contentsOf: [UInt8(0x00),UInt8(0x00),UInt8(0x00),UInt8(0x00)])
        
        return txToSign
    }
    
    func buildSignedScripts(signFromCard: [UInt8], publicKey: [UInt8], outputsCount: Int) -> [[UInt8]]? {
        var scripts = [[UInt8]](reserveCapacity: outputsCount)
        for index in 0..<outputsCount {
            let offset = index*64
            let sig = signFromCard[offset..<offset+64]
            guard let signDer = serializeSignature(for: Array(sig)) else {
                return nil
            }
            var script = [UInt8]()
            script.append((signDer.count+1).byte)
            script.append(contentsOf: signDer)
            script.append(UInt8(0x1))
            script.append(UInt8(0x41))
            script.append(contentsOf: publicKey)
            scripts.append(script)
        }
        return scripts
    }
    
    private func serializeSignature(for sign: [UInt8]) -> [UInt8]? {
        var ctx: secp256k1_context = secp256k1_context_create(.SECP256K1_CONTEXT_NONE)!
        defer {secp256k1_context_destroy(&ctx)}
        var sig = secp256k1_ecdsa_signature()
        var normalized = secp256k1_ecdsa_signature()
        _ = secp256k1_ecdsa_signature_parse_compact(ctx, &sig, sign)
        _ = secp256k1_ecdsa_signature_normalize(ctx, &normalized, sig)
        
        var length: UInt = 128
        var der = [UInt8].init(repeating: UInt8(0x0), count: Int(length))
        let res = secp256k1_ecdsa_signature_serialize_der(ctx, &der, &length, normalized)
        guard res else { return nil }
        
        return Array(der[0..<Int(length)])
    }
    
    func buildTxForSend(signFromCard: [UInt8], txRefs: [BtcTx], publicKey: [UInt8]) -> [UInt8]? {
        guard let outputScripts = buildSignedScripts(signFromCard: signFromCard,
                                                     publicKey: publicKey,
                                                     outputsCount: txRefs.count) else {
                                                        return nil
        }
            
        guard let unspentTransactions = buildUnspents(with: outputScripts, txRefs: txRefs),
            let amount = self.amount,
            let target = self.targetAddress,
            let change = self.change else {
                return nil
        }
        
        
        
        guard let txToSign = buildTxBody(unspentTransactions: unspentTransactions, amount: amount, change: change, targetAddress: target, index: nil) else {
            return nil
        }
        
        return txToSign
    }
    
    func sendToBlockchain(signFromCard: [UInt8], completion: @escaping (Bool) -> Void) {
        guard let txRefs = addressResponse?.txrefs,
            let txToSend = buildTxForSend(signFromCard: signFromCard, txRefs: txRefs, publicKey: card.walletPublicKeyBytesArray) else {
                completion(false)
                return
        }
        
        let txHexString = txToSend.toHexString()
        
        let sendOp = BtcSendOperation(with: self, txHex: txHexString, completion: {[weak self] result in
            switch result {
            case .success(let sendResponse):
                self?.unconfirmedBalance = nil
               // print(sendResponse?.tx)
                completion(true)
            case .failure(let error):
              //  print(error)
                completion(false)
            }
        })
        operationQueue.addOperation(sendOp)
    }
    
    func getFee(targetAddress: String, amount: String, completion: @escaping ((min: String, normal: String, max: String)?) -> Void) {
        
        let feeRequestOperation = BtcFeeOperation(with: self, completion: {[weak self] result in
                switch result {
                case .success(let feeResponse):
                    guard let self = self else {
                         completion(nil)
                        return
                    }
                    
                    let kb = Decimal(1024)
                    let minPerByte = feeResponse.minimalKb/kb
                    let normalPerByte = feeResponse.normalKb/kb
                    let maxPerByte = feeResponse.priorityKb/kb
                    
                    guard let _ = self.getHashForSignature(amount: amount, fee: "0.00000001", includeFee: true, targetAddress: targetAddress),
                            let txRefs = self.blockcypherResponse?.txrefs,
                            let testTx  = self.buildTxForSend(signFromCard: [UInt8](repeating: UInt8(0x01), count: 64 * txRefs.count), txRefs: txRefs, publicKey: self.card.walletPublicKeyBytesArray) else {
                            completion(nil)
                            return
                    }
                    let estimatedTxSize = Decimal(testTx.count + 1)
                    let minFee = (minPerByte * estimatedTxSize)
                    let normalFee = (normalPerByte * estimatedTxSize)
                    let maxFee = (maxPerByte * estimatedTxSize)
                    
                    let fee = ("\(minFee.rounded(blockchain: .bitcoin))",
                        "\(normalFee.rounded(blockchain: .bitcoin))",
                        "\(maxFee.rounded(blockchain: .bitcoin))")
                    completion(fee)
                
                case .failure(let error):
                  //  print(error)
                    completion(nil)
                }
        })

        operationQueue.addOperation(feeRequestOperation)
    }
    
    var hasPendingTransactions: Bool {
        return unconfirmedBalance != 0
    }
    
    func validate(address: String) -> Bool {
        let possibleFirstCharacters = ["1","2","3","n","m"]
       
        guard !address.isEmpty,
            (26...35) ~= address.count,
            possibleFirstCharacters.contains(String(address.first!))
        else {
            return false
        }
    
        guard let decoded = address.base58DecodedData,
            decoded.count > 24 else {
            return false
        }

        let rip = decoded[0..<21]
        let kcv = rip.sha256().sha256()

        for i in 0..<4 {
            if kcv[i] != decoded[21+i] {
                return false
            }
        }
        
        if card.isTestBlockchain && (address.starts(with: "1") || address.starts(with: "3")) {
          return false
        }
        
        return true;
    }
}


enum Op: UInt8 {
    case hash160 = 0xA9
    case equal = 0x87
    case dup = 0x76
    case equalVerify = 0x88
    case checkSig = 0xAC
    case pushData1 = 0x4c
    case pushData2 = 0x4d
    case pushData4 = 0x4e
}
