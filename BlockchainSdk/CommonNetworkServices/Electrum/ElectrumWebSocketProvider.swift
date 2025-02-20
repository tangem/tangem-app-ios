//
//  ElectrumWebSocketProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

class ElectrumWebSocketProvider: HostProvider {
    var host: String { webSocketProvider.host }

    private let webSocketProvider: JSONRPCWebSocketProvider
    private let encoder: JSONEncoder = .init()
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    init(
        url: URL,
        ping: WebSocketConnection.Ping = ElectrumWebSocketProvider.ping(),
        timeoutInterval: TimeInterval = Constants.timeoutInterval
    ) {
        webSocketProvider = JSONRPCWebSocketProvider(url: url, ping: ping, timeoutInterval: timeoutInterval)
    }

    func getBalance(identifier: Identifier) async throws -> ElectrumDTO.Response.Balance {
        switch identifier {
        case .address(let address):
            return try await send(method: Method.Blockchain.Address.getBalance, parameter: [address])
        case .scriptHash(let scriptHash):
            return try await send(method: Method.Blockchain.ScriptHash.getBalance, parameter: [scriptHash])
        }
    }

    func getTxHistory(identifier: Identifier) async throws -> [ElectrumDTO.Response.History] {
        switch identifier {
        case .address(let address):
            return try await send(method: Method.Blockchain.Address.getHistory, parameter: [address])
        case .scriptHash(let scriptHash):
            return try await send(method: Method.Blockchain.ScriptHash.getHistory, parameter: [scriptHash])
        }
    }

    func getTransaction(hash: String) async throws -> ElectrumDTO.Response.Transaction {
        try await send(method: Method.Blockchain.Transaction.get, parameter: [AnyEncodable(hash), AnyEncodable(true)])
    }

    func getUnspents(identifier: Identifier) async throws -> [ElectrumDTO.Response.ListUnspent] {
        switch identifier {
        case .address(let address):
            return try await send(method: Method.Blockchain.Address.listunspent, parameter: [address])
        case .scriptHash(let scriptHash):
            return try await send(method: Method.Blockchain.ScriptHash.listunspent, parameter: [scriptHash])
        }
    }

    func send(transactionHex: String) async throws -> ElectrumDTO.Response.Broadcast {
        try await send(method: Method.Blockchain.Transaction.broadcast, parameter: transactionHex)
    }

    /**
     Use for specify Radiant blockchain answer for example
     ```
     {
         "jsonrpc": "2.0",
         "result": "8827bae7cc2409b2a49b38ca5482a0a1cb296f458e6e7eb669a30def0c9b63ee",
         "id": 5
     }
     ```
     */
    func send(transactionHex: String) async throws -> String {
        try await send(method: Method.Blockchain.Transaction.broadcast, parameter: [transactionHex])
    }

    func estimateFee(block: Int) async throws -> Decimal {
        try await send(method: Method.Blockchain.estimatefee, parameter: [block])
    }
}

// MARK: - Private

private extension ElectrumWebSocketProvider {
    func send<Method, Parameter, Result>(method: Method, parameter: Parameter) async throws -> Result
        where Parameter: Encodable,
        Result: Decodable,
        Method: RawRepresentable,
        Method.RawValue == String {
        try await webSocketProvider.send(
            method: method.rawValue,
            parameter: parameter,
            encoder: encoder,
            decoder: decoder
        )
    }
}

// MARK: - Identifier

extension ElectrumWebSocketProvider {
    private enum Constants {
        static let timeoutInterval: TimeInterval = 30
    }

    enum Identifier {
        case address(_ address: String)
        case scriptHash(_ hash: String)
    }
}

// MARK: - Ping

extension ElectrumWebSocketProvider {
    static func ping() -> WebSocketConnection.Ping {
        do {
            let request: JSONRPC.Request = .ping(method: Method.Server.ping.rawValue)
            let message = try request.string(encoder: .init())
            return .message(message: .string(message))
        } catch {
            BSDKLogger.error(error: error)
            return .plain()
        }
    }
}

// MARK: - Methods

private extension ElectrumWebSocketProvider {
    enum Method {
        enum Server: String {
            case ping = "server.ping"
        }

        enum Blockchain: String {
            case estimatefee = "blockchain.estimatefee"
        }
    }
}

private extension ElectrumWebSocketProvider.Method.Blockchain {
    enum Transaction: String {
        case get = "blockchain.transaction.get"
        case broadcast = "blockchain.transaction.broadcast"
    }
}

private extension ElectrumWebSocketProvider.Method.Blockchain {
    enum Address: String {
        case getBalance = "blockchain.address.get_balance"
        case getHistory = "blockchain.address.get_history"
        case listunspent = "blockchain.address.listunspent"
    }

    enum ScriptHash: String {
        case getBalance = "blockchain.scripthash.get_balance"
        case getHistory = "blockchain.scripthash.get_history"
        case listunspent = "blockchain.scripthash.listunspent"
    }
}
