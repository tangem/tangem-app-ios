import Foundation

enum CSPRUtils {
    static var deploy: CSPRDeploy = .init()

    // value parse based on this site https:// docs.rs/humantime/latest/humantime/fn.parse_duration.html

    static func ttlToMilisecond(ttl: String) -> UInt64 {
        if ttl.contains(" ") {
            let elements = ttl.components(separatedBy: " ")
            let totalElement = elements.count
            var valueBack: UInt64 = .init(0)
            for i in 0 ... totalElement - 1 {
                valueBack = valueBack + ttlToMilisecond(ttl: elements[i])
            }
            return valueBack
        }

        if ttl.contains("msec") {
            let index = ttl.index(ttl.endIndex, offsetBy: -4)
            return UInt64(String(ttl[..<index]))!
        } else if ttl.contains("ms") {
            let index = ttl.index(ttl.endIndex, offsetBy: -2)
            return UInt64(String(ttl[..<index]))!
        }

        return 0
    }

    static func dateStrToMilisecond(dateStr: String) -> UInt64 {
        let elements = dateStr.components(separatedBy: ".")
        let realStr = elements[0] + "Z"
        let remainMiliStr = elements[1]
        let index = remainMiliStr.index(remainMiliStr.startIndex, offsetBy: 3)
        let milisecondStr = String(remainMiliStr[..<index])
        let milisecondU64 = UInt64(milisecondStr)!
        let dateFormatter = DateFormatter()
        // set locale to reliable US_POSIX
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        let date = dateFormatter.date(from: realStr)!
        let ret = UInt64(date.millisecondsSince1970) + milisecondU64
        return ret
    }

    /// Supporter method for sorting U128 Array
    static func sortU128Array(array: inout [U128Class]) {
        let total = array.count
        for _ in 0 ... total {
            for j in 0 ... total - 2 {
                if !Self.isBigNum1SmallerThanBigNum2(num1: array[j].valueInStr, num2: array[j + 1].valueInStr) {
                    let temp = array[j]
                    array[j] = array[j + 1]
                    array[j + 1] = temp
                }
            }
        }
    }

    /// Supporter method for sorting U256 Array
    static func sortU256Array(array: inout [U256Class]) {
        let total = array.count
        for _ in 0 ... total {
            for j in 0 ... total - 2 {
                if !Self.isBigNum1SmallerThanBigNum2(num1: array[j].valueInStr, num2: array[j + 1].valueInStr) {
                    let temp = array[j]
                    array[j] = array[j + 1]
                    array[j + 1] = temp
                }
            }
        }
    }

    /// Supporter method for sorting U512 Array
    static func sortU512Array(array: inout [U512Class]) {
        let total = array.count
        for _ in 0 ... total {
            for j in 0 ... total - 2 {
                if !Self.isBigNum1SmallerThanBigNum2(num1: array[j].valueInStr, num2: array[j + 1].valueInStr) {
                    let temp = array[j]
                    array[j] = array[j + 1]
                    array[j + 1] = temp
                }
            }
        }
    }

    /// Support function to compare two big number, such as U128 or U256 or U512, return true if num1 < num2 and vice versa
    static func isBigNum1SmallerThanBigNum2(num1: String, num2: String) -> Bool {
        // if num1 < num2 return true
        let num1Length = num1.count
        let num2Length = num2.count
        if num1Length > num2Length {
            return false
        } else if num1Length < num2Length {
            return true
        } else {
            for i in 0 ... num1Length - 1 {
                if UInt8(num1[i])! > UInt8(num2[i])! {
                    return false
                }
            }
            return true
        }
    }
}

private extension Date {
    var millisecondsSince1970: Int64 {
        Int64((timeIntervalSince1970 * 1000.0).rounded())
    }

    init(milliseconds: Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}

private extension String {
    var length: Int {
        return count
    }

    subscript(i: Int) -> String {
        return self[i ..< i + 1]
    }

    func substring(fromIndex: Int) -> String {
        return self[min(fromIndex, length) ..< length]
    }

    func substring(toIndex: Int) -> String {
        return self[0 ..< max(0, toIndex)]
    }
}
