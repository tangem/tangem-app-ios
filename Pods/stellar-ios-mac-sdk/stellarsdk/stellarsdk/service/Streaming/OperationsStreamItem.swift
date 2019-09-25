//
//  OperationsStreamItem.swift
//  stellarsdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public class OperationsStreamItem: NSObject {
    private var streamingHelper: StreamingHelper
    private var subpath: String
    let operationsFactory = OperationsFactory()
    
    public init(baseURL:String, subpath:String) {
        streamingHelper = StreamingHelper(baseURL: baseURL)
        self.subpath = subpath
    }
    
    public func onReceive(response:@escaping StreamResponseEnum<OperationResponse>.ResponseClosure) {
        streamingHelper.streamFrom(path:subpath) { [weak self] (helperResponse) -> (Void) in
            switch helperResponse {
            case .open:
                response(.open)
            case .response(let id, let data):
                do {
                    let jsonData = data.data(using: .utf8)!
                    guard let operation = try self?.operationsFactory.operationFromData(data: jsonData) else { return }
                    response(.response(id: id, data: operation))
                } catch {
                    response(.error(error: HorizonRequestError.parsingResponseFailed(message: error.localizedDescription)))
                }
            case .error(let error):
                let operationSubpath = self?.subpath ?? "unknown"
                response(.error(error: HorizonRequestError.errorOnStreamReceive(message: "Error from Horizon on stream with path \(operationSubpath): \(error?.localizedDescription ?? "nil")")))
            }
        }
    }
    
    public func closeStream() {
        streamingHelper.close()
    }
}
