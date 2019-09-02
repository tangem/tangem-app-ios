//  web3swift
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Alex Vlasov. All rights reserved.
//

import Foundation

extension Dictionary where Key == String, Value: Equatable {
    func keyForValue(value : Value) -> String? {
        for key in self.keys {
            if self[key] == value {
                return key
            }
        }
        return nil
    }
}
