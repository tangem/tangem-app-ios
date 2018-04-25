//
//  BalanceService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Yulia Moskaleva. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class BalanceService{
    static let sharedInstance = BalanceService()
    init(){}
    struct Constants {
        static let coinMarket = "https://api.coinmarketcap.com/v1/ticker/?convert=USD&lmit=10"
        static let ethereumMainNet = "https://mainnet.infura.io/AfWg0tmYEX5Kukn2UkKV"
        static let ethereumTestNet = "https://ropsten.infura.io/"
        static let btcTestNet = "testnetnode.arihanc.com:51001"
        static let btcMainNet_0 = "vps.hsmiths.com: 8080"
        static let btcMainNet_1 = "arihancckjge66iv.onion: 8080"
        static let btcMainNet_2 = "electrumx.bot.nu: 50001"
        static let btcMainNet_3 = "btc.asis.io: 50001"
        static let btcMainNet_4 = "e-x.not.fyi: 50001"
        static let btcMainNet_5 = "electrum.backplanedns.org: 50001"
        static let btcMainNet_6 = "helicarrier.bauerj.eu: 50001"
    }
    
    func getCoinMarketInfo(_ name:String, completionHandler: @escaping (String?, String?) -> ()){
        Alamofire.request(Constants.coinMarket, method:.get).responseJSON{
            response in
            
            switch response.result {
            case .success(let value):
                var price_usd:String?
               if let json = try? JSON(value) {
                    for item in json.arrayValue {
                        let id = item["id"].stringValue
                        if id == name {
                            price_usd = item["price_usd"].stringValue
                            break
                         }
                    }
                    completionHandler(price_usd,nil)
                    //completionHandler(nil,"test")
               }
                
            case.failure(let error):
                completionHandler(nil,String(describing: error))
//                if let err = error as? URLError, err.code == .notConnectedToInternet {
//                    completionHandler(nil, "Check your internet connection")
//                } else {
//                    if let data = response.data {
//                        let errorInfo = String(data: data, encoding: .utf8)
//                        print("Market Info error: \( String(describing: errorInfo))");
//                        completionHandler(nil, errorInfo)
//                    }
//                }
            }
            
        }
    }
    
    func getBitcoinMain(_ address:String, completionHandler: @escaping (Int?, String?) -> ()){
        Alamofire.request("https://blockchain.info/balance?active="+address, method:.get).responseJSON{
            response in
            
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
    
    func getBitcoinTestNet(_ address:String, completionHandler: @escaping (Int?, String?) -> ()){
        Alamofire.request("https://testnet.blockchain.info/balance?active="+address, method:.get).responseJSON{
            response in
            
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
    
    func getEthereumMainNet(_ address:String, completionHandler: @escaping (UInt64?, String?) -> ()){
        let url = URL(string: "https://mainnet.infura.io")!
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
                
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject] else { return }
                //print("RESULT \(json)")
                let check = json["result"] as? String
                guard let checkStr = check  else {
                    return
                }
                if checkStr == "0x0" {
                    completionHandler(0,nil)
                }
                let  checkWithoutTwoFirstLetters = String(checkStr[checkStr.index(checkStr.startIndex,offsetBy:2)...])
                print("RESULT \(checkStr)")
                let checkArray = checkWithoutTwoFirstLetters.asciiHexToData()
                guard let checkArrayUInt8 = checkArray else {
                    return
                }
                let checkInt64 = arrayToUInt64(checkArrayUInt8)
                completionHandler(checkInt64,nil)
            } catch {
                print("error:", error)
                completionHandler(nil,String(describing: error))
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
                
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject] else { return }
                let check = json["result"] as? String
                guard let checkStr = check  else {
                    return
                }
                if checkStr == "0x0" {
                    completionHandler(0,nil)
                }
                let  checkWithoutTwoFirstLetters = String(checkStr[checkStr.index(checkStr.startIndex,offsetBy:2)...])
                let checkArray = checkWithoutTwoFirstLetters.asciiHexToData()
                guard let checkArrayUInt8 = checkArray else {
                    return
                }
                let checkInt64 = arrayToUInt64(checkArrayUInt8)
                
                
                print("json: \(json)")
                completionHandler(checkInt64,nil)
            } catch {
                print("error:", error)
                completionHandler(nil,String(describing: error))
            }
        }
        
        task.resume()
        
    }
    
    func geBtcTestNet(_ testAddress:String, completionHandler: @escaping (String?, String?) -> ()){
        //Address for tests "mj6rrLQGJBKwuPenWxraiG4xvxeh6x2ofF"
        let url = URL(string: "http:"+Constants.btcTestNet)!
        
        
        
        let jsonDict = ["id": 1 , "method": "blockchain.address.get_balance", "params":[testAddress]] as [String : Any]
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
              
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject] else { return }
                
              
                print("json: \(json)")
                completionHandler("ok",nil)
            } catch {
                print("error:", error)
                completionHandler(nil,String(describing: error))
            }
        }
        
        task.resume()
        
    }
    
    
}

