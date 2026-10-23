import Foundation

/**
 Class for Deploy Header object
 */
class CSPRDeployHeader: Codable {
    /// Deploy Header  account hash
    var account: String = ""
    /// Deploy Header body hash
    var bodyHash: String = ""
    /// Deploy Header  chain name
    var chainName: String = ""
    /// Deploy Header gas price, in UInt64 format
    var gasPrice: UInt64 = 0
    /// Deploy Header  timestamp
    var timestamp: String = ""
    /// Deploy Header  time to live, in format of "1day", "2h", "30m" ...
    var ttl: String = ""
    /// Deploy Header list of dependencies
    var dependencies: [String] = .init()
    /*
     Get DeployHeader object from Json string
     - Parameter : a Json String represent the DeployHeader object
     - Returns: DeployHeader object
     */
}
