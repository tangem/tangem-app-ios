//
//  LinksResponse.swift
//  stellarsdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public class PagingLinksResponse: NSObject, Decodable {
    
    /// Link to the current request URL.
    public var selflink:LinkResponse
    
    /// Link to the next "page" of the result.
    public var next:LinkResponse?
    
    /// Link to the previous "page" of the result.
    public var prev:LinkResponse?
    
    
    // Properties to encode and decode.
    enum CodingKeys: String, CodingKey {
        case selflink = "self"
        case next
        case prev
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        selflink = try values.decode(LinkResponse.self, forKey: .selflink)
        next = try values.decodeIfPresent(LinkResponse.self, forKey: .next)
        prev = try values.decodeIfPresent(LinkResponse.self, forKey: .prev)
    }
}
