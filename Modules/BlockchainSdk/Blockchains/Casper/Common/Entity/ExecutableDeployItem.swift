import Foundation

/**
 Enumeration type represents the ExecutableDeployItem
 */
let versionNullValue: UInt32 = 100000
enum ExecutableDeployItem {
    case moduleBytes(module_bytes: CSPRBytes, args: RuntimeArgs)
    case storedContractByHash(hash: String, entryPoint: String, args: RuntimeArgs)
    case storedContractByName(name: String, entryPoint: String, args: RuntimeArgs)
    case storedVersionedContractByHash(hash: String, version: UInt32?, entryPoint: String, args: RuntimeArgs)
    case storedVersionedContractByName(name: String, version: UInt32?, entryPoint: String, args: RuntimeArgs)
    case transfer(args: RuntimeArgs)
    case none
}

/*
 Class supports the getting of ExecutableDeployItem from Json String
 */

enum ExecutableDeployItemHelper {
    /*
        Function to get  json string from ExecutableDeployItem enum type
       - Parameter: a ExecutableDeployItem enum type  value
       - Returns: json string representing the ExecutableDeployItem enum type value
     */

    static func toJsonString(input: ExecutableDeployItem) -> String {
        var retStr = ""
        switch input {
        case .moduleBytes(let moduleBytes, let args):
            let argsString = ExecutableDeployItemHelper.argsToJsonString(args: args)
            let innerJson = "{\"module_bytes\": \"\(moduleBytes.value)\",\(argsString)}"
            retStr = "{\"ModuleBytes\": \(innerJson)}"
            return retStr
        case .storedContractByHash(let hash, let entryPoint, let args):
            let argsString = ExecutableDeployItemHelper.argsToJsonString(args: args)
            let innerJson = "{\"hash\": \"\(hash)\",\"entry_point\": \"\(entryPoint)\",\(argsString)}"
            retStr = "{\"StoredContractByHash\": \(innerJson)}"
            return retStr
        case .storedContractByName(let name, let entryPoint, let args):
            let argsString = ExecutableDeployItemHelper.argsToJsonString(args: args)
            let innerJson = "{\"name\": \"\(name)\",\"entry_point\": \"\(entryPoint)\",\(argsString)}"
            retStr = "{\"StoredContractByName\": \(innerJson)}"
            return retStr
        case .storedVersionedContractByHash(let hash, let version, let entryPoint, let args):
            let argsString = ExecutableDeployItemHelper.argsToJsonString(args: args)
            if version == versionNullValue {
                let innerJson = "{\"hash\": \"\(hash)\",\"version\": null , \"entry_point\": \"\(entryPoint)\",\(argsString)}"
                retStr = "{\"StoredVersionedContractByHash\": \(innerJson)}"
                return retStr
            } else {
                let innerJson = "{\"hash\": \"\(hash)\",\"version\": \(version!), \"entry_point\": \"\(entryPoint)\",\(argsString)}"
                retStr = "{\"StoredVersionedContractByHash\": \(innerJson)}"
            }
            return retStr
        case .storedVersionedContractByName(let name, let version, let entryPoint, let args):
            let argsString: String = ExecutableDeployItemHelper.argsToJsonString(args: args)
            if version == versionNullValue {
                let innerJson = "{\"name\": \"\(name)\",\"version\": null, \"entry_point\": \"\(entryPoint)\",\(argsString)}"
                retStr = "{\"StoredVersionedContractByName\": \(innerJson)}"
            } else {
                let innerJson = "{\"name\": \"\(name)\",\"version\": \(version!), \"entry_point\": \"\(entryPoint)\",\(argsString)}"
                retStr = "{\"StoredVersionedContractByName\": \(innerJson)}"
            }
            return retStr
        case .transfer(let args):
            let argsString = ExecutableDeployItemHelper.argsToJsonString(args: args)
            let innerJson = "{\(argsString)}"
            retStr = "{\"Transfer\": \(innerJson)}"
            return retStr
        case .none:
            break
        }
        return retStr
    }

    /*
     Get ExecutableDeployItem object from Json string
     - Parameter: a Json String represents the ExecutableDeployItem object
     - Returns: ExecutableDeployItem object
     */

    /*
        Function to get  json string from RuntimeArgs object
       - Parameter: a RuntimeArgs object
       - Returns: json string representing the RuntimeArgs object
     */

    static func argsToJsonString(args: RuntimeArgs) -> String {
        var ret = ""
        let totalArg: Int = args.listNamedArg.count
        for i in 0 ... totalArg - 1 {
            let clValueStr: String = CLValueToJson.getJsonString(clValue: args.listNamedArg[i].argsItem)
            let argStr = "[\"\(args.listNamedArg[i].name)\",\(clValueStr)]"
            ret = ret + argStr + ","
        }
        let index = ret.index(ret.endIndex, offsetBy: -1)
        ret = String(ret[..<index])
        ret = "\"args\": [" + ret + "]"
        return ret
    }
}
