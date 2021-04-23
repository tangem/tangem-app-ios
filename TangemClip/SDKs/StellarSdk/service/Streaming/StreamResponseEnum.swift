//
//  StreamResponseEnum.swift
//  StellarSDKClips
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

public enum StreamResponseEnum<Data:Decodable> {
    case open
    case response(id:String, data:Data)
    case error(error:Error?)
    
    public typealias ResponseClosure = (_ response:StreamResponseEnum<Data>) -> (Void)
}
