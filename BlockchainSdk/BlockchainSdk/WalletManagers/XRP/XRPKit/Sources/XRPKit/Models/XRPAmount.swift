//
//  XRPAmount.swift
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

public enum XRPAmountError: Error {
    case invalidAmount
}

public struct XRPAmount {
    
    private(set) var drops: Int!
    
    public init(drops: Int) throws {
        if drops < 0 || drops > UInt64(100000000000000000) {
            throw XRPAmountError.invalidAmount
        }
        self.drops = drops
    }
    
    public init(_ text: String) throws {
        // removed commas
        let stripped = text.replacingOccurrences(of: ",", with: "")
        if !stripped.replacingOccurrences(of: ".", with: "").isNumber {
            throw XRPAmountError.invalidAmount
        }
        // get parts
        var xrp = stripped
        var drops = ""
        if let decimalIndex = stripped.firstIndex(of: ".") {
            xrp = String(stripped.prefix(upTo: decimalIndex))
            let _index = stripped.index(decimalIndex, offsetBy: 1)
            drops = String(stripped.suffix(from: _index))
        }
        // adjust values
        drops = drops + String.init(repeating: "0", count: 6-drops.count)
        // combine parts
        let _drops = Int(xrp+drops)!
        if _drops < 0 || _drops > UInt64(100000000000000000) {
            throw XRPAmountError.invalidAmount
        }
        self.drops = _drops

    }
    
    public func prettyPrinted() -> String {
        let drops = self.drops%1000000
        let xrp = self.drops/1000000
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        let formattedNumber = numberFormatter.string(from: NSNumber(value: xrp))!
        let leadingZeros: [Character] = Array(repeating: "0", count: 6 - String(drops).count)
        return formattedNumber + "." + String(leadingZeros) + String(drops)
    }

}
