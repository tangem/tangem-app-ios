//
//  BalanceService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class BalanceService {
    
    static let sharedInstance = BalanceService()
    let balanceFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.minimumIntegerDigits = 1
        numberFormatter.maximumFractionDigits = 8
        numberFormatter.minimumFractionDigits = 2
        return numberFormatter
    }()
    
    struct Constants {
        static let coinMarket = "https://api.coinmarketcap.com/v1/ticker/?convert=USD&lmit=10"
        static let ethereumMainNet = "https://mainnet.infura.io/AfWg0tmYEX5Kukn2UkKV"
        static let ethereumTestNet = "https://ropsten.infura.io/"
        static let btcTestNet = "testnetnode.arihanc.com:51001"
        static let btcTestNet_0 = "testnet.hsmiths.com:53011"
        static let btcTestNet_1 = "testnetnode.arihanc.com:51001"
        static let btcTestNet_2 = "testnet1.bauerj.eu:50001"
        static let btcMainNet_0 = "vps.hsmiths.com: 8080"
        static let btcMainNet_1 = "tardis.bauerj.eu:50001"
        static let btcMainNet_2 = "electrumx.bot.nu: 50001"
        static let btcMainNet_3 = "electrumx.hopto.org:50001"
        static let btcMainNet_4 = "e-x.not.fyi: 50001"
        static let btcMainNet_5 = "electrum.backplanedns.org: 50001"
        static let btcMainNet_6 = "helicarrier.bauerj.eu: 50001"
    }
    
    func getCoinMarketInfo(_ name: String, completionHandler: @escaping (String?, String?) -> ()) {
        Alamofire.request(Constants.coinMarket, method:.get).responseJSON { response in
            switch response.result {
            case .success(let value):
                var price_usd: String?
                let json = JSON(value)
                for item in json.arrayValue {
                    let id = item["id"].stringValue
                    if id == name {
                        price_usd = item["price_usd"].stringValue
                        break
                     }
                }
                completionHandler(price_usd, nil)
                
            case .failure(let error):
                completionHandler(nil,String(describing: error))
            }
            
        }
    }
    
    func getBitcoinMain(_ address:String, completionHandler: @escaping (Int?, String?) -> ()) {
        Alamofire.request("https://blockchain.info/balance?active="+address, method: .get).responseJSON { response in
            switch response.result {
            case .success(let value):
                
                let balanceInfo = JSON(value)
                let result:Int? = balanceInfo[address]["final_balance"].intValue 
                
                completionHandler(result, nil)

            case.failure(let error):
                completionHandler(nil,String(describing: error))
                if let err = error as? URLError, err.code == .notConnectedToInternet {
                    completionHandler(nil, "Check your internet connection")
                } else {
                    if let data = response.data {
                        let errorInfo = String(data: data, encoding: .utf8) ?? ""
                        print("Error Info: \( String(describing: errorInfo))");
                        completionHandler(nil, errorInfo)
                    }
                }
            }
            
        }
    }
    
    func getBitcoinTestNet(_ address:String, completionHandler: @escaping (Int?, String?) -> ()) {
        Alamofire.request("https://testnet.blockchain.info/balance?active="+address, method:.get).responseJSON { response in
            
            switch response.result {
            case .success(let value):
                
                let balanceInfo = JSON(value)
                let result:Int? = balanceInfo[address]["final_balance"].intValue
                
                completionHandler(result, nil)
                //completionHandler(nil,"test")
            case.failure(let error):
                completionHandler(nil,String(describing: error))
                if let err = error as? URLError, err.code == .notConnectedToInternet {
                    completionHandler(nil, "Check your internet connection")
                } else {
                    if let data = response.data {
                        let errorInfo = String(data: data, encoding: .utf8) ?? ""
                        print("Error Info: \( String(describing: errorInfo))");
                        completionHandler(nil, errorInfo)
                    }
                }
            }
            
        }
    }
    
    func getEthereumMainNet(_ address: String, completionHandler: @escaping (UInt64?, String?) -> ()) {
        let url = URL(string: "https://mainnet.infura.io")!
        let jsonDict = ["jsonrpc":  "2.0", "method": "eth_getBalance", "params": [address, "latest"], "id": 03] as [String : Any]
        let jsonData = try! JSONSerialization.data(withJSONObject: jsonDict, options: [])
        
        var request = URLRequest(url: url)
        request.httpMethod = "post"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                completionHandler(nil, "error")
                return
            }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject] else {
                    completionHandler(nil, "error")
                    return
                }
                
                let check = json["result"] as? String
                guard let checkStr = check else {
                    completionHandler(nil, "error")
                    return
                }
                
                if checkStr == "0x0" {
                    completionHandler(0, nil)
                }
                let checkWithoutTwoFirstLetters = String(checkStr[checkStr.index(checkStr.startIndex,offsetBy: 2)...])
                print("RESULT \(checkStr)")
                
                let checkArray = checkWithoutTwoFirstLetters.asciiHexToData()
                guard let checkArrayUInt8 = checkArray else {
                    completionHandler(nil, "error")
                    return
                }
                let checkInt64 = arrayToUInt64(checkArrayUInt8)
                
                completionHandler(checkInt64, nil)
            } catch {
                print("error:", error)
                completionHandler(nil, String(describing: error))
            }
        }
        
        task.resume()
        
    }
    
    func getEthereumTestNet(_ address:String, completionHandler: @escaping (UInt64?, String?) -> ()){
        let url = URL(string: "https://rinkeby.infura.io")!
        let jsonDict = ["jsonrpc": "2.0", "method": "eth_getBalance", "params":[address,"latest"] ,"id":03] as [String : Any]
        let jsonData = try! JSONSerialization.data(withJSONObject: jsonDict, options: [])
       
        var request = URLRequest(url: url)
        request.httpMethod = "post"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard  let data = data else {
                completionHandler(nil,"error")
                return
            }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject] else {
                    completionHandler(nil, "error")
                    return
                }
                
                let check = json["result"] as? String
                guard let checkStr = check else {
                    completionHandler(nil, "error")
                    return
                }
                
                if checkStr == "0x0" {
                    completionHandler(0, nil)
                }
                let checkWithoutTwoFirstLetters = String(checkStr[checkStr.index(checkStr.startIndex,offsetBy:2)...])
                let checkArray = checkWithoutTwoFirstLetters.asciiHexToData()
                guard let checkArrayUInt8 = checkArray else {
                    return
                }
                let checkInt64 = arrayToUInt64(checkArrayUInt8)
                
                print("json: \(json)")
                completionHandler(checkInt64, nil)
            } catch {
                print("error:", error)
                completionHandler(nil, String(describing: error))
            }
        }
        
        task.resume()
        
    }
    
    func getTokenBalance(_ address: String, contract: String, completionHandler: @escaping (NSDecimalNumber?, String?) -> ()) {
        let url = URL(string: "https://mainnet.infura.io")!
        
        
        let index = address.index(address.startIndex, offsetBy: 2)
        let dataValue = ["data": "0x70a08231000000000000000000000000\(address[index...])", "to": contract.replacingOccurrences(of: "\n", with: "")]
        
        let jsonDict = ["method": "eth_call", "params": [dataValue, "latest"], "id": 03] as [String : Any]
        let jsonData = try! JSONSerialization.data(withJSONObject: jsonDict, options: [])
        
        var request = URLRequest(url: url)
        request.httpMethod = "post"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                completionHandler(nil, "error")
                return
            }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject] else {
                    completionHandler(nil, "error")
                    return
                }
                print("RESULT \(json)")
                let check = json["result"] as? String
                guard let checkStr = check else {
                    completionHandler(nil, "error")
                    return
                }
                
                if checkStr == "0x0" {
                    completionHandler(0, nil)
                }
                let checkWithoutTwoFirstLetters = String(checkStr[checkStr.index(checkStr.startIndex, offsetBy: 2)...])
                print("RESULT \(checkStr)")
                
                let decimalNumber = arrayToDecimalNumber(checkWithoutTwoFirstLetters.asciiHexToData()!)
                
                completionHandler(decimalNumber, nil)
            } catch {
                print("error:", error)
                completionHandler(nil,String(describing: error))
            }
        }
        
        task.resume()
    }
    
}

extension BalanceService {
    
    func getBalanceBTC(_ card: Card, onResult: @escaping (Card) -> Void) {
        
        var card = card
        BalanceService.sharedInstance.getCoinMarketInfo("bitcoin") { success, error in
            if let success = success {
                card.mult = success
            }
            
            guard error == nil else {
                card.mult = "0"
                card.error = 1
                onResult(card)
                return
            }
            
            let onCompletion = { (balanceValue: Int?, error: String?) in
                if let balanceValue = balanceValue {
                    card.value = balanceValue
                }
                guard error == nil else {
                    card.walletValue = ""
                    card.usdWalletValue = ""
                    card.error = 1
                    DispatchQueue.main.async {
                        onResult(card)
                    }
                    return
                }
                
                let price_usd = (card.mult as NSString).doubleValue
                let satoshi = Double(card.value)
                
                let first = satoshi / 100000000.0
                card.walletValue = self.balanceFormatter.string(from: NSNumber(value: first))!
                
                let second = price_usd / 1000.0
                let value = first * second
                card.usdWalletValue = self.balanceFormatter.string(from: NSNumber(value: value))!
                if (card.mult == "0") {
                    card.usdWalletValue = ""
                }
                card.checkedBalance = true
                print("Card BTC \(card)")
                
                DispatchQueue.main.async {
                    onResult(card)
                }
            }
            
            if card.isTestNet {
                BalanceService.sharedInstance.getBitcoinTestNet(card.btcAddressTest) { success, error in
                    onCompletion(success, error)
                }
            } else {
                BalanceService.sharedInstance.getBitcoinMain(card.btcAddressMain) { success, error in
                    onCompletion(success, error)
                }
            }
        }
    }
    
    func getBalanceETH(_ card: Card, onResult: @escaping (Card) -> Void) {
        
        var card = card
        BalanceService.sharedInstance.getCoinMarketInfo("ethereum") { success, error in
            if let success = success {
                card.mult = success
            }
            
            guard error == nil else {
                card.mult = "0"
                card.error = 1
                onResult(card)
                return
            }
            
            let onCompletion = { (balanceValue: UInt64?, error: String?) in
                if let balanceValue = balanceValue {
                    card.valueUInt64 = balanceValue
                }
                guard error == nil else {
                    card.walletValue = ""
                    card.usdWalletValue = ""
                    card.error = 1
                    DispatchQueue.main.async {
                        onResult(card)
                    }
                    return
                }
                let price_usd = (card.mult as NSString).doubleValue
                let wei = Double(card.valueUInt64)
                let first = wei / 1000000000000000000.0
                card.walletValue = self.balanceFormatter.string(from: NSNumber(value: first))!
                
                let value = first * price_usd
                card.usdWalletValue = self.balanceFormatter.string(from: NSNumber(value: value))!
                
                if (card.mult == "0"){
                    card.usdWalletValue = ""
                }
                card.checkedBalance = true
                print("Card ETH: \(card)")
                
                DispatchQueue.main.async {
                    onResult(card)
                }
            }
            
            if card.isTestNet {
                BalanceService.sharedInstance.getEthereumTestNet(card.ethAddress) { balanceValue, error in
                    onCompletion(balanceValue, error)
                }
            } else {
                BalanceService.sharedInstance.getEthereumMainNet(card.ethAddress) { balanceValue, error in
                    onCompletion(balanceValue, error)
                }
            }
        }
    }
    
    
    
    func getBalanceToken(_ card: Card, onResult: @escaping (Card) -> Void) {
        
        var card = card
        BalanceService.sharedInstance.getCoinMarketInfo("ethereum") { success, error in
            
            if let success = success {
//                card.mult = success
                card.mult = "0"
            }
            
            guard error == nil else {
                card.mult = "0"
                card.error = 1
                onResult(card)
                return
            }
            
            let onCompletion = { (balanceValue: NSDecimalNumber?, error: String?) in
                if let balanceValue = balanceValue {
                    card.valueUInt64 = balanceValue.uint64Value
                }
                guard error == nil else {
                    card.walletValue = ""
                    card.usdWalletValue = ""
                    card.error = 1
                    DispatchQueue.main.async {
                        onResult(card)
                    }
                    return
                }
                
                guard let normalisedValue = balanceValue?.dividing(by: NSDecimalNumber(value: 1).multiplying(byPowerOf10: Int16(card.tokenDecimal))) else {
                    card.error = 1
                    DispatchQueue.main.async {
                        onResult(card)
                    }
                    return
                }
                card.walletValue = self.balanceFormatter.string(from: NSNumber(value: normalisedValue.doubleValue))!
                
                let price_usd = Double(card.mult)!
                let value = normalisedValue.doubleValue * price_usd
                card.usdWalletValue = self.balanceFormatter.string(from: NSNumber(value: value))!
                
                card.checkedBalance = true
                print("Card Token: \(card)")
                
                DispatchQueue.main.async {
                    onResult(card)
                }
            }
            
            guard let tokenContractAddress = card.tokenContractAddress else {
                DispatchQueue.main.async {
                    onResult(card)
                }
                return
            }
            
            BalanceService.sharedInstance.getTokenBalance(card.ethAddress, contract: tokenContractAddress) { balanceValue, error in
                onCompletion(balanceValue, error)
            }
        }
    }
    
}

