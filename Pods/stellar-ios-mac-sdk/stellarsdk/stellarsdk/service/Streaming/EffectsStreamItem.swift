//
//  EffectsStreamItem.swift
//  stellarsdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public class EffectsStreamItem: NSObject {
    private var streamingHelper: StreamingHelper
    private var subpath: String
    let effectsFactory = EffectsFactory()
    
    public init(baseURL:String, subpath:String) {
        streamingHelper = StreamingHelper(baseURL: baseURL)
        self.subpath = subpath
    }
    
    public func onReceive(response:@escaping StreamResponseEnum<EffectResponse>.ResponseClosure) {
        streamingHelper.streamFrom(path:subpath) { [weak self] (helperResponse) -> (Void) in
            switch helperResponse {
            case .open:
                response(.open)
            case .response(let id, let data):
                do {
                    let jsonData = data.data(using: .utf8)!
                    guard let effects = try self?.effectsFactory.effectFromData(data: jsonData) else { return }
                    response(.response(id: id, data: effects))
                } catch {
                    response(.error(error: HorizonRequestError.parsingResponseFailed(message: error.localizedDescription)))
                }
            case .error(let error):
                let effectSubPath = self?.subpath ?? "unknown"
                response(.error(error: HorizonRequestError.errorOnStreamReceive(message: "Error from Horizon on stream with path \(effectSubPath): \(error?.localizedDescription ?? "nil")")))
            }
        }
    }
    
    public func closeStream() {
        streamingHelper.close()
    }
}
