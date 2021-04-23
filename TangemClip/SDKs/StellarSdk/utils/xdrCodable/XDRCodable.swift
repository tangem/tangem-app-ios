//
//  XDRCodable.swift
//  stellarsdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Soneso. All rights reserved.
//

// Based on https://github.com/kinfoundation/StellarKit

/// A convenient shortcut for indicating something is both encodable and decodable.
public typealias XDRCodable = XDREncodable & XDRDecodable
