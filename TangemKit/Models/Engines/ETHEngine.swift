//
//  ETHEngine.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation
import web3swift
import BigInt

public class ETHEngine: CardEngine, PayIdProvider {
    private let _payIdManager = PayIdManager(network: .ETH)
    var payIdManager: PayIdManager? {
        return _payIdManager
    }
    
    
    var chainId: BigUInt {
        return card.isTestBlockchain ? Networks.Rinkeby.chainID : Networks.Mainnet.chainID
    }

    var blockchain: Blockchain {
        return .ethereum
    }
    
    var mainNetURL: String { card.isTestBlockchain ? TokenNetwork.ethTest.rawValue : TokenNetwork.eth.rawValue }
    
    unowned public var card: CardViewModel
    
    private var transaction: EthereumTransaction?
    private var hashForSign: Data?
    private let operationQueue = OperationQueue()

    
    public var blockchainDisplayName: String {
        return "Ethereum"
    }
    
    public var walletType: WalletType {
        return .eth
    }
    
    public var walletUnits: String {
        return "ETH"
    }
    
    public var qrCodePreffix: String {
        return card.isTestBlockchain ? "" : "ethereum:"
    }
    
    public var txCount: Int = -1
    public var pendingTxCount: Int = -1
    
    public var walletAddress: String = ""
    public var exploreLink: String {
        let baseUrl = card.isTestBlockchain ? "https://rinkeby.etherscan.io/address/" : "https://etherscan.io/address/"
        return baseUrl + walletAddress
    }
    
    required public init(card: CardViewModel) {
        self.card = card
        if card.isWallet {
            setupAddress()
        }
    }
    
    public func setupAddress() {
        let hexPublicKey = card.walletPublicKey
        let hexPublicKeyWithoutTwoFirstLetters = String(hexPublicKey[hexPublicKey.index(hexPublicKey.startIndex, offsetBy: 2)...])
        let binaryCuttPublicKey = dataWithHexString(hex: hexPublicKeyWithoutTwoFirstLetters)
        let keccak = binaryCuttPublicKey.sha3(.keccak256)
        let hexKeccak = keccak.hexEncodedString()
        let cutHexKeccak = String(hexKeccak[hexKeccak.index(hexKeccak.startIndex, offsetBy: 24)...])
        
        walletAddress = "0x" + cutHexKeccak
        
        card.node = "mainnet.infura.io"
    }
}


extension ETHEngine: CoinProvider {
    public func getApiDescription() -> String {
        return "main"
    }
    
    public var coinTraitCollection: CoinTrait {
        return isToken ? CoinTrait.allowsFeeSelector : CoinTrait.all
       }
    
    var isToken: Bool {
        return card.units != walletUnits
    }
    
    public func getHashForSignature(amount: String, fee: String, includeFee: Bool, targetAddress: String) -> [Data]? {
        let nonceValue = BigUInt(txCount)
        
        guard let feeValue = Web3.Utils.parseToBigUInt(fee, units: .eth),
            let amountValue = Web3.Utils.parseToBigUInt(amount, units: .eth) else {
                return nil
        }
        
        let gasLimit = getGasLimit()
        guard let data = getData(amount: amount, targetAddress: targetAddress) else {
            return nil
        }
        
        guard let targetAddr = !isToken ? targetAddress : card.tokenContractAddress else {
            return nil
        }
        
        let amount = !isToken ? (includeFee ? amountValue - feeValue : amountValue) : BigUInt.zero
        
        guard let transaction = EthereumTransaction(amount: amount,
                                                    fee: feeValue,
                                                    targetAddress: targetAddr,
                                                    nonce: nonceValue,
                                                    gasLimit: gasLimit,
                                                    data: data) else {
                                                        return nil
        }
        
        guard let hashForSign = transaction.hashForSignature(chainID: chainId) else {
            return nil
        }
      
        self.transaction = transaction
        self.hashForSign = hashForSign
        return [hashForSign]
    }
    
    private func getData(amount: String, targetAddress: String) -> Data? {
        if !isToken {
            return Data()
        }
        
        guard let tokenDecimals = card.tokenDecimal else {
            return nil
        }
        
        guard let amountDecimal = Web3.Utils.parseToBigUInt(amount, decimals: tokenDecimals) else {
            return nil
        }

        var amountString = String(amountDecimal, radix: 16).remove("0X")
        while amountString.count < 64 {
            amountString = "0" + amountString
        }
        
        let amountData = Data(hex: amountString)
        
        guard let addressData = EthereumAddress(targetAddress)?.addressData else {
                return nil
        }
        let prefixData = Data(hex: "a9059cbb000000000000000000000000")
        return prefixData + addressData + amountData
    }
    
    private func getGasLimit() -> BigUInt {
        if !isToken {
            return 21000
        }
        
        if card.tokenSymbol == "DGX" {
            return 300000
        }
        
        if card.tokenSymbol == "AWG" {
            return 150000
        }
        
        return 60000
    }
    
    public func getFee(targetAddress: String, amount: String, completion: @escaping  ((min: String, normal: String, max: String)?)->Void) {
        
        let url = URL(string: mainNetURL)!
        
        
        guard let network = fromInt(chainId) else {
            completion(nil)
            return
        }
        
        let provider = Web3HttpProvider(url, network: network, keystoreManager: nil)!
        let web = web3(provider: provider)
        
        DispatchQueue.global().async {
            do {
                let gasPrice = try web.eth.getGasPrice()
                let m = self.getGasLimit()
                let decimalCount = Int(self.blockchain.decimalCount)
                let minValue = gasPrice * m
                let min = Web3.Utils.formatToEthereumUnits(minValue, toUnits: .eth, decimals: decimalCount, decimalSeparator: ".", fallbackToScientific: false)!
                
                let normalValue = gasPrice * BigUInt(12) / BigUInt(10) * m
                let normal = Web3.Utils.formatToEthereumUnits(normalValue, toUnits: .eth, decimals: decimalCount, decimalSeparator: ".", fallbackToScientific: false)!
                
                let maxValue = gasPrice * BigUInt(15) / BigUInt(10) * m
                let max = Web3.Utils.formatToEthereumUnits(maxValue, toUnits: .eth, decimals: decimalCount, decimalSeparator: ".", fallbackToScientific: false)!
                
                let fee = (min.trimZeroes(), normal.trimZeroes(), max.trimZeroes())
                completion(fee)
                
            } catch {
                Analytics.log(error: error)
                completion(nil)
            }
        }
    }
    
    public func sendToBlockchain(signFromCard: [UInt8], completion: @escaping (Bool, Error?) -> Void) {
        
        guard let tx = getHashForSend(signFromCard: signFromCard) else {
            completion(false, "Empty hashes. Try again")
            return
        }
        let txHexString = "0x\(tx.toHexString())"
        
        let sendOperation = EthereumNetworkSendOperation(tx: txHexString, networkUrl: mainNetURL) { [weak self] (result) in
            switch result {
            case .success(let value):
                self?.txCount += 1
                //print(value)
                completion(true, nil)
            case .failure(let error):
              //  print(error)
                completion(false, error)
            }
        }
        
        self.operationQueue.addOperation(sendOperation)
    }
    
    
    public func getHashForSend(signFromCard: [UInt8]) -> Data? {
        guard let hashForSign = self.hashForSign else {
            return nil
        }
        
        let publicKey = card.walletPublicKeyBytesArray
        
        guard let normalizedSignature = getNormalizedVerifyedSignature(for: signFromCard, publicKey: publicKey, hashToSign: hashForSign.bytes),
            let recoveredSignature = recoverSignature(for: normalizedSignature, hashToSign: hashForSign, publicKey: publicKey),
            let unmarshalledSignature = SECP256K1.unmarshalSignature(signatureData: recoveredSignature) else {
                return nil
        }
        
        transaction?.v = BigUInt(unmarshalledSignature.v)
        transaction?.r = BigUInt(unmarshalledSignature.r)
        transaction?.s = BigUInt(unmarshalledSignature.s)
        
        let encodedBytesToSend = transaction?.encodeForSend(chainID: chainId)
        return encodedBytesToSend
    }
    
    private func recoverSignature(for normalizedSign: Data, hashToSign: Data, publicKey: [UInt8]) -> Data? {
        for v in 27..<31 {
            let testV = UInt8(v)
            let testSign = normalizedSign + Data(bytes: [testV])
            if let recoveredKey = SECP256K1.recoverPublicKey(hash: hashToSign, signature: testSign, compressed: false),
                recoveredKey.bytes == publicKey {
                return testSign
            }
        }
        return nil
    }
    
    private func getNormalizedVerifyedSignature(for sign: [UInt8], publicKey: [UInt8], hashToSign: [UInt8]) -> Data? {
        var vrfy: secp256k1_context = secp256k1_context_create(.SECP256K1_CONTEXT_VERIFY)!
        defer {secp256k1_context_destroy(&vrfy)}
        var sig = secp256k1_ecdsa_signature()
        var normalizied = secp256k1_ecdsa_signature()
        _ = secp256k1_ecdsa_signature_parse_compact(vrfy, &sig, sign)
        _ = secp256k1_ecdsa_signature_normalize(vrfy, &normalizied, sig)
        
        var pubkey = secp256k1_pubkey()
        _ = secp256k1_ec_pubkey_parse(vrfy, &pubkey, publicKey, 65)
        if !secp256k1_ecdsa_verify(vrfy, normalizied, hashToSign, pubkey) {
            return nil
        }        
        return Data(normalizied.data)
    }
    
    public var hasPendingTransactions: Bool {
        return txCount != pendingTxCount
    }
    
    public func validate(address: String) -> Bool {
        guard !address.isEmpty,
            address.lowercased().starts(with: "0x"),
            address.count == 42
            else {
                return false
        }
        
        return true;
    }
    
    func fromInt(_ networkID: BigUInt) -> Networks? {
        switch networkID {
        case 1:
            return Networks.Mainnet
        case 3:
            return Networks.Ropsten
        case 4:
            return Networks.Rinkeby
        case 42:
            return Networks.Kovan
        default:
            return Networks.Custom(networkID: networkID)
        }
    }
}

