//
//  BCHEngine.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation
import HDWalletKit
import Moya
import SwiftyJSON

class BCHEngine: CardEngine, PayIdProvider {
    unowned var card: CardViewModel
    
    var payIdManager: PayIdManager? = PayIdManager(network: .BCH)
    
    var blockchainDisplayName: String { "Bitcoin Cash" }
    
    var walletType: WalletType { .bch }
    
    var walletUnits: String { "BCH" }
    
    var walletAddress: String = ""
    
    var qrCodePreffix: String = ""
    
    var exploreLink: String {
        return "https://blockchair.com/bitcoin-cash/address/" + walletAddress
    }

    var addressResponse: BtcResponse? {
        didSet {
            unconfirmedBalance = addressResponse?.unconfirmed_balance
            txBuilder.unspentOutputs = addressResponse?.txrefs
        }
    }
    var unconfirmedBalance: Int?
    
    private var txBuilder: BitcoinCashTransactionBuilder!
    private var transaction: Transaction?
    private let moyaProvider = MoyaProvider<BlockchairTarget>()
    
    required init(card: CardViewModel) {
        self.card = card
        if card.isWallet {
            setupAddress()
        } 
    }
    
    func setupAddress() {
        let prefix = Data([UInt8(0x00)]) //public key hash
        let payload = RIPEMD160.hash(message: Data(pubKeyCompressed.sha256()))
        walletAddress = Bech32.encode(prefix + payload, prefix: "bitcoincash")
        txBuilder = BitcoinCashTransactionBuilder(walletAddress: walletAddress, walletPublicKey: Data(pubKeyCompressed), isTestnet: card.isTestBlockchain)
    }
}

extension BCHEngine: CoinProvider {
    var hasPendingTransactions: Bool {
        return unconfirmedBalance != 0
    }
    var coinTraitCollection: CoinTrait {
        .allowsFeeInclude
    }
    
    func getHashForSignature(amount: String, fee: String, includeFee: Bool, targetAddress: String) -> [Data]? {
        guard let feeValue = Decimal(string: fee),
            let amountValue = Decimal(string: amount) else {
                return nil
        }
        
            
        let finalAmount = includeFee ? amountValue - feeValue : amountValue
            
        transaction = Transaction(fee: Amount(value: feeValue),
                                  amount: Amount(value: finalAmount),
                                  destinationAddress: targetAddress)
        
        guard let hashes = txBuilder.buildForSign(transaction: transaction!) else {
            return nil
        }
        
        return hashes
    }
    
    func sendToBlockchain(signFromCard: [UInt8], completion: @escaping (Bool, Error?) -> Void) {
        guard let transaction = self.transaction,
            let txToSend = txBuilder.buildForSend(transaction:transaction, signature: Data(signFromCard)) else {
            completion(false, "Empty transaction. Try again")
            return
        }
        
        let txHexString = txToSend.toHexString()
        print(txHexString.uppercased())
        moyaProvider.request(.send(txHex:txHexString)) {[weak self] result in
            switch result {
            case .success(let response):
                guard let json = try? JSON(data: response.data) else {
                    completion(false, "Map response failed")
                    return
                }
                
                let data = json["data"]
                
                if let hash = data["transaction_hash"].string  {
                    self?.unconfirmedBalance = nil
                    completion(true, nil)
                    return
                }
                
               completion(false, "Failed request")
            case .failure(let error):
                //  print(error)
                completion(false, error)
            }
        }
    }
    
    func getFee(targetAddress: String, amount: String, completion: @escaping ((min: String, normal: String, max: String)?) -> Void) {
        moyaProvider.request(.fee()) {[weak self] result in
            switch result {
            case .failure(let error):
                Analytics.log(error: error)
                print(error)
                completion(nil)
            case .success(let response):
                guard let json = try? JSON(data: response.data) else {
                    completion(nil)
                    return
                }
                
                let data = json["data"]
                guard let feePerByteSatoshi = data["suggested_transaction_fee_per_byte_sat"].int  else {
                        completion(nil)
                        return
                }
                
                guard let amountValue = Decimal(string: amount),
                let outputs = self?.txBuilder.unspentOutputs else {
                    completion(nil)
                     return
                }
                
                let transaction = Transaction(fee: Amount(value: Decimal(0.00)),
                                              amount: Amount(value: amountValue),
                                                             destinationAddress: targetAddress)
                
                guard let estimatedTx = self?.txBuilder.buildForSend(transaction: transaction,
                                                                     signature: Data(repeating: UInt8(0x01), count: 64 * outputs.count)) else {
                    completion(nil)
                    return
                }
                
                let estimatedTxSize = Decimal(estimatedTx.count + 1)
                let fee = (Decimal(feePerByteSatoshi) * estimatedTxSize)/Decimal(100000000)
                let relayFee = Decimal(0.00001)
                let finalFee = fee >= relayFee ? fee : relayFee
                let feeString = "\(finalFee.rounded(blockchain: .bitcoinCash))"
                completion((feeString,feeString,feeString))
            }
        }
    }
    
    func validate(address: String) -> Bool {
        return (try? BitcoinCashAddress(address)) != nil
    }
    
    func getApiDescription() -> String {
        "blockchair"
    }
}


class BitcoinCashTransactionBuilder {
    let isTestnet: Bool
    let walletAddress: String
    let walletPublicKey: Data
    var unspentOutputs: [BtcTx]?
    
    init(walletAddress: String, walletPublicKey: Data, isTestnet: Bool) {
        self.walletAddress = walletAddress
        self.walletPublicKey = walletPublicKey
        self.isTestnet = isTestnet
    }
    
    public func buildForSign(transaction: Transaction) -> [Data]? {
        guard let fee = transaction.fee?.value, let amount = transaction.amount.value else {
            return nil
        }
        
        guard let legacyWalletAddress = try? BitcoinCashAddress(walletAddress).base58,
            let legacyTargetAddress =  try? BitcoinCashAddress(transaction.destinationAddress).base58 else {
                return nil
        }
        
        guard let outputScript = buildOutputScript(address: legacyWalletAddress) else {
            return nil
        }
        
        guard let unspents = buildUnspents(with: [outputScript]) else {
            return nil
        }
        
        let amountSatoshi = amount * Decimal(100000000)
        let changeSatoshi = calculateChange(unspents: unspents, amount: amount, fee: fee)
        
        var hashes = [Data]()
        
        for index in 0..<unspents.count {
            guard let tx = buildPreimage(unspents: unspents, amount: amountSatoshi, change: changeSatoshi, targetAddress: legacyTargetAddress, index: index) else {
                return nil
            }
            // tx.append(contentsOf: [UInt8(0x01),UInt8(0x00),UInt8(0x00),UInt8(0x00)]) for btc
            let hash = tx.sha256().sha256()
            hashes.append(hash)
        }
        
        return hashes
    }
    
    public func buildForSend(transaction: Transaction, signature: Data) -> Data? {
        guard let fee = transaction.fee?.value, let unspentOutputs = unspentOutputs,
            let amount = transaction.amount.value else {
                return nil
        }
        
        guard let legacyTargetAddress =  try? BitcoinCashAddress(transaction.destinationAddress).base58  else {
            return nil
        }
        
        guard let outputScripts = buildSignedScripts(signature: signature,
                                                     publicKey: walletPublicKey,
                                                     outputsCount: unspentOutputs.count),
            let unspents = buildUnspents(with: outputScripts) else {
                return nil
        }
        
        let amountSatoshi = amount * Decimal(100000000)
        let changeSatoshi = calculateChange(unspents: unspents, amount: amount, fee: fee)
        
        let tx = buildTxBody(unspents: unspents, amount: amountSatoshi, change: changeSatoshi, targetAddress: legacyTargetAddress, index: nil)
        return tx
    }
    
    private func calculateChange(unspents: [UnspentTransaction], amount: Decimal, fee: Decimal) -> Decimal {
        let fullAmountSatoshi = Decimal(unspents.reduce(0, {$0 + $1.amount}))
        let feeSatoshi = fee * Decimal(100000000)
        let amountSatoshi = amount * Decimal(100000000)
        return fullAmountSatoshi - amountSatoshi - feeSatoshi
    }
    
    private func buildPrefix(for data: Data) -> Data {
        switch data.count {
        case 0..<Int(Op.pushData1.rawValue):
            return data.count.byte.asData
        case Int(Op.pushData1.rawValue)..<Int(0xff):
            return Data([Op.pushData1.rawValue]) + data.count.byte.asData
        case Int(0xff)..<Int(0xffff):
            return Data([Op.pushData2.rawValue]) + data.count.bytes2LE
        default:
            return Data([Op.pushData4.rawValue]) + data.count.bytes4LE
        }
    }
    
    private func getOpCode(for data: Data) -> UInt8? {
        var opcode: UInt8
        
        if data.count == 0 {
            opcode = Op.op0.rawValue
        } else if data.count == 1 {
            let byte = data[0]
            if byte >= 1 && byte <= 16 {
                opcode = byte - 1 + Op.op1.rawValue
            } else {
                opcode = 1
            }
        } else if data.count < Op.pushData1.rawValue {
            opcode = UInt8(truncatingIfNeeded: data.count)
        } else if data.count < 256 {
            opcode = Op.pushData1.rawValue
        } else if data.count < 65536 {
            opcode = Op.pushData2.rawValue
        } else {
            return nil
        }
        
        return opcode
    }
    
    private func buildOutputScript(address: String) -> Data? {
        //segwit bech32
        if address.starts(with: "bc1") || address.starts(with: "tb1") {
            let networkPrefix = isTestnet ? "tb" : "bc"
            guard let segWitData = try? SegWitBech32.decode(hrp: networkPrefix, addr: address) else { return nil }
            
            let version = segWitData.version
            guard version >= 0 && version <= 16 else { return nil }
            
            var script = Data()
            script.append(version == 0 ? Op.op0.rawValue : version - 1 + Op.op1.rawValue) //smallNum
            let program = segWitData.program
            if program.count == 0 {
                script.append(Op.op0.rawValue) //smallNum
            } else {
                guard let opCode = getOpCode(for: program) else { return nil }
                if opCode < Op.pushData1.rawValue {
                    script.append(opCode)
                } else if opCode == Op.pushData1.rawValue {
                    script.append(Op.pushData1.rawValue)
                    script.append(program.count.byte)
                } else if opCode == Op.pushData2.rawValue {
                    script.append(Op.pushData2.rawValue)
                    script.append(contentsOf: program.count.bytes2LE) //little endian
                } else if opCode == Op.pushData4.rawValue {
                    script.append(Op.pushData4.rawValue)
                    script.append(contentsOf: program.count.bytes4LE)
                }
                script.append(contentsOf: program)
            }
            return script
        }
        
        let decoded = address.base58DecodedData!
        let first = decoded[0]
        let data = decoded[1...20]
        //P2H
        if (first == 0 || first == 111 || first == 48) { //0 for BTC/BCH 1 address | 48 for LTC L address
            return [Op.dup.rawValue, Op.hash160.rawValue ] + buildPrefix(for: data) + data + [Op.equalVerify.rawValue, Op.checkSig.rawValue]
        }
        //P2SH
        if(first == 5 || first == 0xc4 || first == 50) { //5 for BTC/BCH/LTC 3 address | 50 for LTC M address
            return [Op.hash160.rawValue] + buildPrefix(for: data) + data + [Op.equal.rawValue]
        }
        return nil
    }
    
    private func buildUnspents(with outputScripts:[Data]) -> [UnspentTransaction]? {
        let unspentTransactions: [UnspentTransaction]? = unspentOutputs?.enumerated().compactMap({ index, txRef  in
            let hash = Data(hex: txRef.tx_hash)
            let outputScript = outputScripts.count == 1 ? outputScripts.first! : outputScripts[index]
            return UnspentTransaction(amount: txRef.value, outputIndex: txRef.tx_output_n, hash: Array(hash), outputScript: Array(outputScript))
        })
        
        return unspentTransactions
    }
    
    private func buildPreimage(unspents: [UnspentTransaction], amount: Decimal, change: Decimal, targetAddress: String, index: Int) -> Data? {
        guard let legacyWalletAddress = try? BitcoinCashAddress(walletAddress).base58 else {
            return nil
        }
        
        var txToSign = Data()
        // version
        txToSign.append(contentsOf: [UInt8(0x02),UInt8(0x00),UInt8(0x00),UInt8(0x00)])
        //txToSign.append(contentsOf: [UInt8(0x01),UInt8(0x00),UInt8(0x00),UInt8(0x00)]) for btc

        //hashPrevouts (32-byte hash)
        let prevouts = Data(unspents.map { Data($0.hash.reversed()) + $0.outputIndex.bytes4LE }
            .joined())
        let hashPrevouts = prevouts.sha256().sha256()
        txToSign.append(contentsOf: hashPrevouts)
        
        //hashSequence (32-byte hash), ffffffff only
        let sequence = Data(repeating: UInt8(0xFF), count: 4*unspents.count)
        let hashSequence = sequence.sha256().sha256()
        txToSign.append(contentsOf: hashSequence)
        
        //outpoint (32-byte hash + 4-byte little endian)
        let currentOutput = unspents[index]
        txToSign.append(contentsOf: currentOutput.hash.reversed())
        txToSign.append(contentsOf: currentOutput.outputIndex.bytes4LE)
        
        //scriptCode of the input (serialized as scripts inside CTxOuts)
        guard let scriptCode = buildOutputScript(address: legacyWalletAddress) else { //build change out
            return nil
        }
        txToSign.append(scriptCode.count.byte)
        txToSign.append(contentsOf: scriptCode)
        
        //value of the output spent by this input (8-byte little endian)
        txToSign.append(contentsOf: currentOutput.amount.bytes8LE)
        
        //nSequence of the input (4-byte little endian), ffffffff only
        txToSign.append(contentsOf: [UInt8(0xff),UInt8(0xff),UInt8(0xff),UInt8(0xff)])
        
        //hashOutputs (32-byte hash)
        var outputs = Data()
        outputs.append(contentsOf: amount.bytes8LE)
        guard let sendScript = buildOutputScript(address: targetAddress) else {
            return nil
        }
        outputs.append(sendScript.count.byte)
        outputs.append(contentsOf: sendScript)
        
        //output for change (if any)
        if change != 0 {
            outputs.append(contentsOf: change.bytes8LE)
            guard let outputScriptChangeBytes = buildOutputScript(address: legacyWalletAddress) else {
                return nil
            }
            outputs.append(outputScriptChangeBytes.count.byte)
            outputs.append(contentsOf: outputScriptChangeBytes)
        }
        
        let hashOutputs = outputs.sha256().sha256()
        txToSign.append(contentsOf: hashOutputs)
        
        //nLocktime of the transaction (4-byte little endian)
        txToSign.append(contentsOf: [UInt8(0x00),UInt8(0x00),UInt8(0x00),UInt8(0x00)])
        
        //sighash type of the signature (4-byte little endian)
        txToSign.append(contentsOf: [UInt8(0x41),UInt8(0x00),UInt8(0x00),UInt8(0x00)])
        
        return txToSign
    }
    
    
    private func buildTxBody(unspents: [UnspentTransaction], amount: Decimal, change: Decimal, targetAddress: String, index: Int?) -> Data? {
        guard let legacyWalletAddress = try? BitcoinCashAddress(walletAddress).base58 else {
                  return nil
              }
        
        var txToSign = Data()
        // version
        txToSign.append(contentsOf: [UInt8(0x02),UInt8(0x00),UInt8(0x00),UInt8(0x00)])
        //txToSign.append(contentsOf: [UInt8(0x01),UInt8(0x00),UInt8(0x00),UInt8(0x00)]) for btc
        //01
        txToSign.append(unspents.count.byte)
        
        //hex str hash prev btc
        
        for (inputIndex, input) in unspents.enumerated() {
            let hashKey: [UInt8] = input.hash.reversed()
            txToSign.append(contentsOf: hashKey)
            txToSign.append(contentsOf: input.outputIndex.bytes4LE)
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
        txToSign.append(contentsOf: amount.bytes8LE)
        guard let outputScriptBytes = buildOutputScript(address: targetAddress) else {
            return nil
        }
        //hex str 1976a914....88ac
        txToSign.append(outputScriptBytes.count.byte)
        txToSign.append(contentsOf: outputScriptBytes)
        
        if change != 0 {
            //8 bytes
            txToSign.append(contentsOf: change.bytes8LE)
            //hex str 1976a914....88ac
            guard let outputScriptChangeBytes = buildOutputScript(address: legacyWalletAddress) else {
                return nil
            }
            txToSign.append(outputScriptChangeBytes.count.byte)
            txToSign.append(contentsOf: outputScriptChangeBytes)
        }
        //00000000
        txToSign.append(contentsOf: [UInt8(0x00),UInt8(0x00),UInt8(0x00),UInt8(0x00)])
        
        return txToSign
    }
    
    private func buildSignedScripts(signature: Data, publicKey: Data, outputsCount: Int) -> [Data]? {
        var scripts: [Data] = .init()
        scripts.reserveCapacity(outputsCount)
        for index in 0..<outputsCount {
            let offsetMin = index*64
            let offsetMax = offsetMin+64
            guard offsetMax <= signature.count else {
                return nil
            }
            
            let sig = signature[offsetMin..<offsetMax]
            guard let signDer = serializeToDer(secp256k1Signature: sig) else {
                return nil
            }
            
            var script = Data()
            script.append((signDer.count+1).byte)
            script.append(contentsOf: signDer)
            script.append(UInt8(0x41))
            script.append(UInt8(0x21))
            script.append(contentsOf: publicKey)
            scripts.append(script)
        }
        return scripts
    }
    
    private func serializeToDer(secp256k1Signature sign: Data) -> [UInt8]? {
        var ctx: secp256k1_context = secp256k1_context_create(.SECP256K1_CONTEXT_NONE)!
        defer {secp256k1_context_destroy(&ctx)}
        var sig = secp256k1_ecdsa_signature()
        var normalized = secp256k1_ecdsa_signature()
        guard secp256k1_ecdsa_signature_parse_compact(ctx, &sig, Array(sign)) else { return nil }
        
        _ = secp256k1_ecdsa_signature_normalize(ctx, &normalized, sig)
        var length: UInt = 128
        var der = [UInt8].init(repeating: UInt8(0x0), count: Int(length))
        guard secp256k1_ecdsa_signature_serialize_der(ctx, &der, &length, normalized)  else { return nil }
        
        return Array(der[0..<Int(length)])
    }
}


public struct Transaction {
    let fee: Amount?
    let amount: Amount
    let destinationAddress: String
}

public struct Amount {
    let value: Decimal?
}
