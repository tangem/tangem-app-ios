//
//  StreamingHelper.swift
//  stellarsdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public class StreamingHelper: NSObject {
    var eventSource: EventSource!
    var baseURL: String
    
    private var closed = false
    
    init(baseURL:String) {
        self.baseURL = baseURL
    }
    
    func streamFrom(path:String, responseClosure:@escaping StreamResponseEnum<String>.ResponseClosure) {
        let streamingURL = baseURL + path
        eventSource = EventSource(url: streamingURL, headers: ["Accept" : "text/event-stream"])
        eventSource.onOpen { [weak self] httpResponse in
            if httpResponse?.statusCode == 404 {
                let error = HorizonRequestError.notFound(message: "Horizon object missing", horizonErrorResponse: nil)
                responseClosure(.error(error: error))
            } else if let self = self, !self.closed {
                responseClosure(.open)
            }
        }
        
        eventSource.onError { [weak self] error in
            if let self = self, !self.closed {
                responseClosure(.error(error: error))
            }
        }
        
        eventSource.onMessage { [weak self] (id, event, data) in
            if let self = self, !self.closed {
                responseClosure(.response(id: id ?? "", data: data ?? ""))
            }
        }
    }
    
    func close() {
        closed = true
        if let eventSource = eventSource {
            eventSource.close()
            self.eventSource = nil
        }
    }
}
