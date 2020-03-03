//
//  EthIdEngine.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Smart Cash AG. All rights reserved.
//

import Foundation
import web3swift
import BigInt
import HDWalletKit

public class ETHIdEngine: CardEngine {
    let approvalPubkey = "04EAD74FEEE4061044F46B19EB654CEEE981E9318F0C8FE99AF5CDB9D779D2E52BB51EA2D14545E0B323F7A90CF4CC72753C973149009C10DB2D83DCEC28487729"
    let ethEngine: ETHEngine
    
    var approvalAddress: String!
    
    var chainId: BigUInt {
        return 1
    }
    
    var blockchain: Blockchain {
        return .ethereum
    }
    
    var mainNetURL: String { TokenNetwork.eth.rawValue }
    
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
        return "ethereum:"
    }
    
    public var hasApprovalTx: Bool = false
    
    public var approvalTxCount: Int {
        get { return ethEngine.txCount }
        set {
            ethEngine.txCount = newValue
        }
    }
    
    public var walletAddress: String = ""
    public var exploreLink: String {
        return "https://etherscan.io/address/" + walletAddress
    }
    
    required public init(card: CardViewModel) {
        self.card = card
        ethEngine = ETHEngine(card: card)
        if card.isWallet {
            setupAddress()
        }
    }
    
    public func setupAddress() {
        walletAddress = calculateAddress(from: card.walletPublicKey)
        approvalAddress = calculateAddress(from: approvalPubkey)
        card.node = "mainnet.infura.io"
    }
    
    private func calculateAddress(from key: String) -> String {
        let hexPublicKeyWithoutTwoFirstLetters = String(key[key.index(key.startIndex, offsetBy: 2)...])
        let binaryCuttPublicKey = dataWithHexString(hex: hexPublicKeyWithoutTwoFirstLetters)
        let keccak = binaryCuttPublicKey.sha3(.keccak256)
        let hexKeccak = keccak.hexEncodedString()
        let cutHexKeccak = String(hexKeccak[hexKeccak.index(hexKeccak.startIndex, offsetBy: 24)...])        
        return "0x" + cutHexKeccak
    }
    
    func getTxToSign(targetAddress: String) -> [Data]? {
        let gasPrice = Decimal(10000000000)
        let gasLimit = Decimal(21000)
        let fee = gasPrice * gasLimit
        let amount = fee + Decimal(1)
        let hashes = ethEngine.getHashForSignature(amount: "\(amount)", fee: "\(fee)", includeFee: true, targetAddress: targetAddress)
        return hashes
    }
    
    func calculateWallet(name: String, lastname: String, birthDate: Date, gender: Gender, photo: UIImage) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd"
        let dateString = dateFormatter.string(from: birthDate)
        let inputs = "\(name) \(lastname);\(dateString)\(gender.rawValue)"
        let info = inputs.data(using: .utf8)! + UIImageJPEGRepresentation(photo, 1.0)!
        let infoHash = info.sha256()
        
        let master = PrivateKey(privateKey: Data(pubKeyCompressed), chainCode: infoHash, index: 0, coin: .ethereum)
        let child = master.derived(at: .hardened(1))
        let childPublicKey = child.publicKey.uncompressedPublicKey.asHexString()
        let address = calculateAddress(from: childPublicKey)
        return address
    }
}

enum Gender: String {
    case M
    case F
}
