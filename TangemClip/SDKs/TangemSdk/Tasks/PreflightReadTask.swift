//
//  PreflightReadTask.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

/// Use this protocol when you need to define if your Task or Command need to Read card at the session start.
/// By default `needPreflightRead` set to `true` and `preflightReadSettings`  - to  `ReadCardOnly`
public protocol PreflightReadCapable { //[REDACTED_TODO_COMMENT]
    var needPreflightRead: Bool { get }
    var preflightReadSettings: PreflightReadSettings { get }
}

extension PreflightReadCapable {
    public var needPreflightRead: Bool { true }
    public var preflightReadSettings: PreflightReadSettings { .readCardOnly } //[REDACTED_TODO_COMMENT]
}

/// Settings for preflight read task
/// - Note: Valid for cards with COS v.4 and higher. Older card will always read card and wallet info
public enum PreflightReadSettings: Equatable {
    /// Read only card info without wallet info
    case readCardOnly
    /// Read card info and single wallet specified in associated index `WalletIndex`
    case readWallet(index: WalletIndex)
    /// Read card info and all wallets
    case fullCardRead
}

public final class PreflightReadTask {
    typealias CommandResponse = ReadResponse
    
    private var readSettings: PreflightReadSettings
    
    public init(readSettings: PreflightReadSettings) {
        self.readSettings = readSettings
    }
    
    deinit {
        Log.debug("PreflightReadTask deinit")
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<ReadResponse>) {
        Log.debug("=========================== Perform preflight check with settings: \(readSettings) ======================")
        ReadCommand().run(in: session) { (result) in
            switch result {
            case .success(let readResponse):
                self.finalizeRead(in: session, with: readResponse, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func finalizeRead(in session: CardSession, with readResponse: ReadResponse, completion: @escaping CompletionResult<ReadResponse>) {
        if readResponse.firmwareVersion < FirmwareConstraints.AvailabilityVersions.walletData || self.readSettings == .readCardOnly {
            completion(.success(readResponse))
            return
        }
        
        let resp: (Result<[CardWallet], TangemSdkError>) -> Void = {
            switch $0 {
            case .success(let wallets):
                var card = readResponse
                card.setWallets(wallets)
                session.environment.card = card
                completion(.success(card))
            case .failure(let error):
                completion(.failure(error))
            }
            
        }
        switch readSettings {
        case .readWallet(let index):
            readWallet(at: index, in: session, with: readResponse, completion: resp)
        case .fullCardRead:
            readWalletsList(in: session, with: readResponse, completion: resp)
        default:
            break
        }
    }
    
    private func readWallet(at index: WalletIndex, in session: CardSession, with readResponse: ReadResponse, completion: @escaping (Result<[CardWallet], TangemSdkError>) -> Void) {
        ReadWalletCommand(walletIndex: index).run(in: session) { (result) in
            switch result {
            case .success(let response):
                completion(.success([response.wallet]))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func readWalletsList(in session: CardSession, with readResponse: ReadResponse, completion: @escaping (Result<[CardWallet], TangemSdkError>) -> Void) {
        ReadWalletListCommand().run(in: session) { (result) in
            switch result {
            case .success(let listRepsonse):
                completion(.success(listRepsonse.wallets))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    
}

