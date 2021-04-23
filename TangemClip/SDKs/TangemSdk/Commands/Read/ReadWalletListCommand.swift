//
//  ReadWalletListCommand.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

struct WalletListResponse: JSONStringConvertible {
    let cid: String
    let wallets: [CardWallet]
}

class ReadWalletListCommand: Command {
    
    var needPreflightRead: Bool { false }
    
    private var walletIndex: WalletIndex?
    private var tempWalletList: [CardWallet] = []
    
    deinit {
        Log.debug("ReadWalletCommand deinit")
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<WalletListResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(.cardError))
            return
        }
        
        transieve(in: session) { (result) in
            switch result {
            case .success(let listResponse):
                self.tempWalletList.append(contentsOf: listResponse.wallets)
                let loadedWalletsCount = self.tempWalletList.count
                
                if loadedWalletsCount == 0 && listResponse.wallets.count == 0 {
                    completion(.failure(.cardWithMaxZeroWallets))
                    return
                }
                
                guard loadedWalletsCount == card.walletsCount else {
                    self.walletIndex = .index(loadedWalletsCount)
                    self.run(in: session, completion: completion)
                    return
                }
                
                completion(.success(WalletListResponse(cid: listResponse.cid, wallets: self.tempWalletList)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.pin1.value)
            .append(.interactionMode, value: ReadMode.readWalletList)
            .append(.cardId, value: environment.card?.cardId)
        
        if let keys = environment.terminalKeys {
            try tlvBuilder.append(.terminalPublicKey, value: keys.publicKey)
        }
        
        try walletIndex?.addTlvData(to: tlvBuilder)
        
        return CommandApdu(.read, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> WalletListResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        
        let cid: String = try decoder.decode(.cardId)
        let cardWalletsData: [Data] = try decoder.decodeArray(.cardWallet)
        
        guard cardWalletsData.count > 0 else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let walletDecoders: [TlvDecoder] = cardWalletsData.compactMap {
            guard let infoTlvs = Tlv.deserialize($0) else { return nil }
            
            return TlvDecoder(tlv: infoTlvs)
        }
        
        let wallets: [CardWallet] = try walletDecoders.map {
            try CardWalletDeserializer.deserialize(from: $0)
        }
        return WalletListResponse(cid: cid, wallets: wallets)
    }
    
}
