//
//  InputStream+.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation

extension InputStream {
    func readBytes(_ count: Int) -> [UInt8]? {
        var buffer: [UInt8] =  Array(repeating: 0x00, count: count)
        let bytesRead = self.read(&buffer, maxLength: count)
        
        guard bytesRead > 0 else {
            return nil
        }
        
        return buffer
    } 
}
