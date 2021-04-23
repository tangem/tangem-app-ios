//
//  ReadWalletCommand.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

struct WalletResponse: JSONStringConvertible {
    let cid: String
    let wallet: CardWallet
}

class ReadWalletCommand: Command {
    
    var needPreflightRead: Bool { false }
    
    private let walletIndex: WalletIndex
    
    init(walletIndex: WalletIndex) {
        self.walletIndex = walletIndex
    }
    
    deinit {
        Log.debug("ReadWalletCommand deinit")
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<WalletResponse>) {
        Log.debug("Attempt to read wallet at index: \(walletIndex)")
        transieve(in: session, completion: completion)
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.pin1.value)
            .append(.interactionMode, value: ReadMode.readWallet)
            .append(.cardId, value: environment.card?.cardId)
        
        if let keys = environment.terminalKeys {
            try tlvBuilder.append(.terminalPublicKey, value: keys.publicKey)
        }
        
        try walletIndex.addTlvData(to: tlvBuilder)
        
        return CommandApdu(.read, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> WalletResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        
        let wallet = try CardWalletDeserializer.deserialize(from: decoder)
        let cid: String = try decoder.decode(.cardId)
        
        Log.debug("Read wallet at index: \(walletIndex): \(wallet)")
        return WalletResponse(cid: cid, wallet: wallet)
    }
    
}
