//
//  PaymentsService.swift
//  stellarsdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum PaymentsChange {
    case allPayments(cursor:String?)
    case paymentsForAccount(account:String, cursor:String?)
    case paymentsForLedger(ledger:String, cursor:String?)
    case paymentsForTransaction(transaction:String, cursor:String?)
}

/// Builds requests connected to payments.
public class PaymentsService: NSObject {
    let serviceHelper: ServiceHelper
    let operationsFactory = OperationsFactory()
    
    private override init() {
        serviceHelper = ServiceHelper(baseURL: "")
    }
    
    init(baseURL: String) {
        serviceHelper = ServiceHelper(baseURL: baseURL)
    }
    
    /// This function responds with all payment operations that are part of validated transactions.
    /// See [Horizon API]: (https://www.stellar.org/developers/horizon/reference/endpoints/payments-all.html "All Payments")
    ///
    /// - Parameter cursor: An optional paging token, specifying where to start returning records from.
    /// - Parameter order: The order in which to return rows, “asc” or “desc”.
    /// - Parameter limit: Maximum number of records to return default 10
    /// - Parameter includeFailed: set to true to include payments of failed transactions in results.
    /// - Parameter join: Currently, the only valid value for the parameter is transactions. If join=transactions is included in a request then the response will include a transaction field for each operation in the response.
    ///
    open func getPayments(from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil, response:@escaping PageResponse<OperationResponse>.ResponseClosure) {
        let path = "/payments"
        getPayments(onPath: path, from:cursor, order:order, limit:limit, includeFailed:includeFailed, join:join, response:response)
    }
    
    /// This function responds with a collection of payment operations where the given account was either the sender or receiver.
    /// See [Horizon API]: (https://www.stellar.org/developers/horizon/reference/endpoints/payments-for-account.html "Payments for Account")
    ///
    /// - Parameter accountId: The Stellar account ID of the account used to constrain results.
    /// - Parameter cursor: An optional paging token, specifying where to start returning records from.
    /// - Parameter order: The order in which to return rows, “asc” or “desc”.
    /// - Parameter limit: Maximum number of records to return default 10
    /// - Parameter includeFailed: set to true to include payments of failed transactions in results.
    /// - Parameter join: Currently, the only valid value for the parameter is transactions. If join=transactions is included in a request then the response will include a transaction field for each operation in the response.
    ///
    open func getPayments(forAccount accountId:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil, response:@escaping PageResponse<OperationResponse>.ResponseClosure) {
        let path = "/accounts/" + accountId + "/payments"
        getPayments(onPath: path, from:cursor, order:order, limit:limit, includeFailed:includeFailed, join:join, response:response)
    }
    
    /// This function responds with all payment operations that are part of a valid transactions in a given ledger.
    /// See also [Horizon API]: (https://www.stellar.org/developers/horizon/reference/endpoints/payments-for-ledger.html "Payments for Ledger")
    ///
    /// - Parameter accountId: The ledger id of the ledger used to constrain results.
    /// - Parameter cursor: An optional paging token, specifying where to start returning records from.
    /// - Parameter order: The order in which to return rows, “asc” or “desc”.
    /// - Parameter limit: Maximum number of records to return default 10
    /// - Parameter includeFailed: set to true to include payments of failed transactions in results.
    /// - Parameter join: Currently, the only valid value for the parameter is transactions. If join=transactions is included in a request then the response will include a transaction field for each operation in the response.
    ///
    open func getPayments(forLedger ledger:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil, response:@escaping PageResponse<OperationResponse>.ResponseClosure) {
        let path = "/ledgers/" + ledger + "/payments"
        getPayments(onPath: path, from:cursor, order:order, limit:limit, includeFailed:includeFailed, join:join, response:response)
    }
    
    /// This function responds with all payment operations that are part of a given transaction.
    /// See [Horizon API]: (https://www.stellar.org/developers/horizon/reference/endpoints/payments-for-transaction.html "Payments for Transaction")
    ///
    /// - Parameter hash: A transaction hash, hex-encoded.
    /// - Parameter cursor: An optional paging token, specifying where to start returning records from.
    /// - Parameter order: The order in which to return rows, “asc” or “desc”.
    /// - Parameter limit: Maximum number of records to return default 10
    /// - Parameter includeFailed: set to true to include payments of failed transactions in results.
    /// - Parameter join: Currently, the only valid value for the parameter is transactions. If join=transactions is included in a request then the response will include a transaction field for each operation in the response.
    ///
    open func getPayments(forTransaction hash:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil, response:@escaping PageResponse<OperationResponse>.ResponseClosure) {
        let path = "/transactions/" + hash + "/payments"
        getPayments(onPath: path, from:cursor, order:order, limit:limit, includeFailed:includeFailed, join:join, response:response)
    }
    
    private func getPayments(onPath path:String, from cursor:String? = nil, order:Order? = nil, limit:Int? = nil, includeFailed:Bool? = nil, join:String? = nil, response:@escaping PageResponse<OperationResponse>.ResponseClosure) {
        var requestPath = path
        
        var params = Dictionary<String,String>()
        params["cursor"] = cursor
        params["order"] = order?.rawValue
        if let limit = limit { params["limit"] = String(limit) }
        if let isIncludeFailed = includeFailed, isIncludeFailed { params["include_failed"] = "true" }
        if let join = join { params["join"] = join }
        
        if let pathParams = params.stringFromHttpParameters(),
            pathParams.count > 0 {
            requestPath += "?\(pathParams)"
        }
        
        getPaymentsFromUrl(url:serviceHelper.baseURL + requestPath, response:response)
    }
    
    /// Loads payments for a given url if valid. E.g. for a "next" link from a PageResponse<OperationResponse> object where the operation response is of type payment.
    ///
    /// - Parameter url: The url to be used to load the payments.
    ///
    open func getPaymentsFromUrl(url:String, response:@escaping PageResponse<OperationResponse>.ResponseClosure) {
        serviceHelper.GETRequestFromUrl(url: url) { (result) -> (Void) in
            switch result {
            case .success(let data):
                do {
                    let operations = try self.operationsFactory.operationsFromResponseData(data: data)
                    response(.success(details: operations))
                } catch {
                    response(.failure(error: error as! HorizonRequestError))
                }
            case .failure(let error):
                response(.failure(error:error))
            }
        }
    }
    
    /// Allows to stream SSE events from horizon.
    /// Certain endpoints in Horizon can be called in streaming mode using Server-Sent Events. This mode will keep the connection to horizon open and horizon will continue to return responses as ledgers close.
    ///
    open func stream(for transactionsType:PaymentsChange) -> OperationsStreamItem {
        var subpath:String!
        switch transactionsType {
        case .allPayments(let cursor):
            subpath = "/payments"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        case .paymentsForAccount(let accountId, let cursor):
            subpath = "/accounts/" + accountId + "/payments"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        case .paymentsForLedger(let ledger, let cursor):
            subpath = "/ledgers/" + ledger + "/payments"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        case .paymentsForTransaction(let transaction, let cursor):
            subpath = "/transactions/" + transaction + "/payments"
            if let cursor = cursor {
                subpath = subpath + "?cursor=" + cursor
            }
        }
    
        let streamItem = OperationsStreamItem(baseURL: serviceHelper.baseURL, subpath:subpath)
        return streamItem
    }
}
