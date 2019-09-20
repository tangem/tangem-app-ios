//
//  Web3+ERC165.swift
//  web3swift-iOS
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 The Matter Inc. All rights reserved.
//

import Foundation

//Standard Interface Detection
protocol IERC165 {
    
    func supportsInterface(interfaceID: String) throws -> Bool
    
}
