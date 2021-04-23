//
//  BinanceAccountParser.swift
//  TangemClip
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftyJSON

enum BinanceParseError: Error {
    case failedToParseResponseBody
}

protocol BinanceParser {
    func parse(response: BinanceChain.Response, data: Data) throws
    func parse(_ json: JSON, response: BinanceChain.Response)
}

extension BinanceParser {
    func parse(response: BinanceChain.Response, data: Data) throws {
        guard let json = try? JSON(data: data) else {
            guard let body = String(data: data, encoding: .utf8) else { throw BinanceParseError.failedToParseResponseBody }
            response.error = BinanceError(message: body)
            return
        }
        self.parse(json, response: response)
    }
}

class BinanceAccountParser: BinanceParser {
    
    func parse(_ json: JSON, response: BinanceChain.Response) {
        response.account = self.parseAccount(json)
    }
    
    func parseAccount(_ json: JSON) -> BinanceAccount {
        let account = BinanceAccount()
        account.accountNumber = json["account_number"].intValue
        account.address = json["address"].stringValue
        account.balances = json["balances"].map({ self.parseBalance($0.1) })
        account.publicKey = self.parsePublicKey(json["public_key"])
        account.sequence = json["sequence"].intValue
        return account
    }
    
    func parseBalance(_ json: JSON) -> BinanceBalance {
        let balance = BinanceBalance()
        balance.symbol = json["symbol"].string ?? json["a"].stringValue
        balance.free = json["free"].doubleString ?? json["f"].doubleValue
        balance.locked = json["locked"].doubleString ?? json["l"].doubleValue
        balance.frozen = json["frozen"].doubleString ?? json["r"].doubleValue
        return balance
    }
    
    func parsePublicKey(_ json: JSON) -> Data {
        var key = json.arrayValue.map { UInt8($0.intValue) }
        return Data(bytes: &key, count: key.count * MemoryLayout<UInt8>.size)
    }
    
}

class ErrorParser: BinanceParser {
    func parse(_ json: JSON, response: BinanceChain.Response) {
        response.error = self.parseError(json)
    }
    
    func parseError(_ json: JSON) -> Error {
        let code = json["code"].intValue
        let message = json["message"].stringValue
        if let nested = JSON(parseJSON: message)["message"].string {
            return BinanceError(code: code, message: nested)
        }
        return BinanceError(code: code, message: message)
    }
}

extension JSON {
    // Handle doubles returned as strings, eg. "199.97207842"
    var doubleString: Double? {
        guard (self.exists()) else { return nil }
        return self.doubleValue
    }
}
