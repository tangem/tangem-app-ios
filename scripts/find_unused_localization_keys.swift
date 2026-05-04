#!/usr/bin/env swift

// Finds unused localization keys in the project and verifies by building.
//
// Steps:
//   1. Extracts all keys from Localizable.strings and Localizable.stringsdict
//   2. Greps the codebase to find which keys have no `Localization.<key>` references
//   3. Removes unused keys from source files, runs SwiftGen + fastlane to verify
//   4. Reverts all changes via `git checkout`
//   5. Remove ios platfrom on Lokalise for selected keys
//
// Usage:
//   export LOKALISE_API_TOKEN=<your-token>
//   swift scripts/find_unused_localization_keys.swift [app|appTest]

import Foundation

// MARK: - Helpers

func log(_ message: String) {
    FileHandle.standardError.write(Data("\(message)\n".utf8))
}

@discardableResult
func shell(_ command: String, silent: Bool = false) -> (output: String, exitCode: Int32) {
    let process = Process()
    let pipe = Pipe()
    process.executableURL = URL(fileURLWithPath: "/bin/zsh")
    process.arguments = ["-c", command]
    process.standardOutput = pipe
    process.standardError = silent ? FileHandle.nullDevice : pipe
    try! process.run()
    // Read data BEFORE waitUntilExit to avoid pipe buffer deadlock
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .newlines) ?? ""
    return (output, process.terminationStatus)
}

func snakeToCamelCase(_ input: String) -> String {
    var result = ""
    var capitalizeNext = false
    for char in input {
        if char == "_" || char == " " {
            capitalizeNext = true
        } else if capitalizeNext {
            result.append(char.uppercased())
            capitalizeNext = false
        } else {
            result.append(char)
        }
    }
    return result
}

func loadStringsDict(from url: URL) -> [String: Any] {
    let data = try! Data(contentsOf: url)
    let plist = try! PropertyListSerialization.propertyList(from: data, options: [], format: nil)

    guard let dict = plist as? [String: Any] else {
        fatalError("Root object is not a dictionary")
    }

    return dict
}

func saveStringsDict(_ dict: [String: Any], to url: URL) {
    let data = try! PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0)
    try! data.write(to: url, options: .atomic)
}

func removeTopLevelKeys(_ keys: [String], from dict: inout [String: Any]) {
    keys.forEach { dict.removeValue(forKey: $0) }
}

struct LocalizationKey: Hashable {
    let raw: String
    let camel: String
}

enum LokaliseProject: String {
    case app
    case appTest

    var projectId: String {
        switch self {
        case .app: return "4965953963bd330202ba50.61798973"
        case .appTest: return "7815978369bbc8ae946df2.33345065"
        }
    }
}

struct LokaliseService {
    private let apiToken: String
    private let project: LokaliseProject
    private var baseURL: String { "https://api.lokalise.com/api2/projects/\(project.projectId)" }

    init(apiToken: String, project: LokaliseProject) {
        self.apiToken = apiToken
        self.project = project
    }

    /// Fetches key info from Lokalise and removes "ios" from its platforms if present.
    func removeIOSPlatform(forKey keyName: String) {
        guard let keyInfo = fetchKey(named: keyName) else {
            log("LokaliseService: key '\(keyName)' not found")
            return
        }

        guard keyInfo.platforms.contains("ios") else {
            log("LokaliseService: key '\(keyName)' does not have ios platform, skipping")
            return
        }

        let updatedPlatforms = keyInfo.platforms.filter { $0 != "ios" }
        updatePlatforms(keyId: keyInfo.keyId, platforms: updatedPlatforms)
    }

    func removeIOSPlatform(forKeys keyNames: [String]) {
        for keyName in keyNames {
            removeIOSPlatform(forKey: keyName)
        }
    }

    private struct KeysResponse: Decodable {
        let keys: [Key]
    }

    private struct Key: Decodable {
        let keyId: Int
        let keyName: KeyName
        let platforms: [String]

        enum CodingKeys: String, CodingKey {
            case keyId = "key_id"
            case keyName = "key_name"
            case platforms
        }
    }

    private struct KeyName: Decodable {
        let ios: String
    }

    private func fetchKey(named keyName: String) -> Key? {
        let escapedName = keyName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? keyName
        let result = shell(
            "curl -sSf -H 'X-Api-Token: \(apiToken)' '\(baseURL)/keys?filter_keys=\(escapedName)'"
        )

        guard result.exitCode == 0 else {
            log("LokaliseService: failed to fetch key '\(keyName)': \(result.output)")
            return nil
        }

        guard let data = result.output.data(using: .utf8) else { return nil }

        let response = try! JSONDecoder().decode(KeysResponse.self, from: data)

        return response.keys.first { $0.keyName.ios == keyName }
    }

    private func updatePlatforms(keyId: Int, platforms: [String]) {
        let platformsJSON = platforms.map { "\"\($0)\"" }.joined(separator: ",")
        let body = "{\"platforms\":[\(platformsJSON)]}"
        let result = shell(
            "curl -sSf -X PUT -H 'X-Api-Token: \(apiToken)' -H 'Content-Type: application/json' '\(baseURL)/keys/\(keyId)' -d '\(body)'"
        )
        if result.exitCode == 0 {
            log("LokaliseService: updated key \(keyId), platforms: \(platforms)")
        } else {
            log("LokaliseService: failed to update key \(keyId): \(result.output)")
        }
    }
}

// MARK: - Paths

let scriptURL = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
let projectDir = scriptURL.deletingLastPathComponent().path
let localizationsDir = "\(projectDir)/Modules/TangemLocalization/Localizations/en.lproj"
let stringsFile = "\(localizationsDir)/Localizable.strings"
let stringsdictFile = "\(localizationsDir)/Localizable.stringsdict"

// MARK: - Steps

func extractAllKeys() -> [LocalizationKey] {
    var allRawKeys: [String] = []

    // From .strings file
    let stringsContent = try! String(contentsOfFile: stringsFile, encoding: .utf8)
    let regex = try! NSRegularExpression(pattern: #"^"([^"]+)""#, options: .anchorsMatchLines)
    let matches = regex.matches(in: stringsContent, range: NSRange(stringsContent.startIndex..., in: stringsContent))
    for match in matches {
        if let range = Range(match.range(at: 1), in: stringsContent) {
            allRawKeys.append(String(stringsContent[range]))
        }
    }

    // From .stringsdict file
    let dict = loadStringsDict(from: URL(fileURLWithPath: stringsdictFile))
    allRawKeys.append(contentsOf: dict.keys)

    let allKeys = Array(Set(allRawKeys).map { LocalizationKey(raw: $0, camel: snakeToCamelCase($0)) })
        .sorted { $0.camel < $1.camel }

    return allKeys
}

func findUnusedKeys(from allKeys: [LocalizationKey]) -> [LocalizationKey] {
    let pid = ProcessInfo.processInfo.processIdentifier
    let patternsFile = NSTemporaryDirectory() + "patterns_\(pid).txt"

    // Build patterns file: one regex per key with word boundary to avoid substring matches
    let patterns = allKeys.map { "Localization\\.\($0.camel)\\b" }.joined(separator: "\n")
    try! patterns.write(toFile: patternsFile, atomically: true, encoding: .utf8)
    defer { try! FileManager.default.removeItem(atPath: patternsFile) }

    let grepOutput: String
    if shell("which rg", silent: true).exitCode == 0 {
        grepOutput = shell(
            "rg --no-filename --only-matching --file '\(patternsFile)' --glob '*.swift' --glob '!Localizable+Generated.swift' --glob '!.build/' '\(projectDir)' | sort -u",
            silent: true
        ).output
    } else {
        log("Using git grep. This will take some time. For much faster execution try 'brew install ripgrep'")
        grepOutput = shell(
            "cd '\(projectDir)' && git grep --no-color -ohf '\(patternsFile)' -- '*.swift' ':!**/Localizable+Generated.swift' | sort -u",
            silent: true
        ).output
    }

    let usedCamelKeys: Set<String> = Set(
        grepOutput
            .components(separatedBy: "\n")
            .compactMap { line in
                guard line.hasPrefix("Localization.") else { return nil }
                return String(line.dropFirst("Localization.".count))
            }
    )

    return allKeys.filter { !usedCamelKeys.contains($0.camel) }
}

func removeKeysFromStringsFile(_ keys: [LocalizationKey]) {
    log("Removing keys from Localizable.strings")
    let stringsContent = try! String(contentsOfFile: stringsFile, encoding: .utf8)

    var stringsRemoved = 0
    let rawKeySet = Set(keys.map(\.raw))
    let lines = stringsContent.components(separatedBy: "\n")
    let filteredLines = lines.filter { line in
        guard line.hasPrefix("\"") else { return true }
        if let endQuote = line.dropFirst().firstIndex(of: "\"") {
            let key = String(line[line.index(after: line.startIndex) ..< endQuote])
            if rawKeySet.contains(key) {
                stringsRemoved += 1
                return false
            }
        }
        return true
    }
    try! filteredLines.joined(separator: "\n").write(toFile: stringsFile, atomically: true, encoding: .utf8)
    log("Removed \(stringsRemoved) entries from .strings")
}

func removeKeysFromStringsdictFile(_ keys: [LocalizationKey]) {
    log("Removing keys from Localizable.stringsdict")
    let url = URL(fileURLWithPath: stringsdictFile)

    var dict = loadStringsDict(from: url)

    let rawKeys = keys.map(\.raw)
    let before = dict.count
    removeTopLevelKeys(rawKeys, from: &dict)
    log("Removed \(before - dict.count) entries from .stringsdict")

    saveStringsDict(dict, to: url)
}

func buildProject() -> (output: String, exitCode: Int32) {
    log("Running SwiftGen")
    shell("cd '\(projectDir)' && mint run swiftgen@6.6.3 config run --config swiftgen.yml", silent: true)

    log("Building project (fastlane verify_tangem_build_no_sign)...")
    // Non-interactive shells do not run rbenv init; prepend shims so `bundle` uses Ruby from
    // `.ruby-version` (see bootstrap.sh) instead of `/usr/bin/bundle` + system Ruby.
    return shell(
        "cd '\(projectDir)' && PATH=\"$HOME/.rbenv/shims:$HOME/.rbenv/bin:$PATH\" bundle exec fastlane verify_tangem_build_no_sign 2>&1"
    )
}

func revertChanges() {
    shell("cd '\(projectDir)' && git checkout -- '\(stringsFile)' '\(stringsdictFile)'")
    shell("cd '\(projectDir)' && mint run swiftgen@6.6.3 config run --config swiftgen.yml", silent: true)
}

func promptUser(_ message: String) -> String {
    log(message)
    return (readLine(strippingNewline: true) ?? "").lowercased()
}

func askToRemoveIOSPlatform(forKeys keys: [LocalizationKey], lokalise: LokaliseService) {
    for key in keys {
        let answer = promptUser("\nRemove iOS platform for '\(key.raw)'? (y/n/q to quit): ")
        switch answer {
        case "y", "yes":
            lokalise.removeIOSPlatform(forKey: key.raw)
        case "q", "quit":
            log("Skipping remaining keys.")
            return
        default:
            log("Skipped '\(key.raw)'")
        }
    }
}

// MARK: - Main

func main() {
    guard let apiToken = ProcessInfo.processInfo.environment["LOKALISE_API_TOKEN"], !apiToken.isEmpty else {
        log("LOKALISE_API_TOKEN environment variable is not set. Token can be found on https://app.lokalise.com/profile#apitokens . Use write one")
        return
    }

    guard CommandLine.arguments.count > 1,
          let project = LokaliseProject(rawValue: CommandLine.arguments[1])
    else {
        log("Usage: swift scripts/find_unused_localization_keys.swift <app|appTest>")
        return
    }

    let lokalise = LokaliseService(apiToken: apiToken, project: project)

    log("Step 1: Extracting localization keys\n")

    let allKeys = extractAllKeys()

    log("Found \(allKeys.count) total keys.\n")

    log("Step 2: Searching for unused keys\n")

    let unusedKeys = findUnusedKeys(from: allKeys)
    guard !unusedKeys.isEmpty else {
        log("No unused keys found.")
        return
    }

    log("Total: \(allKeys.count), Unused: \(unusedKeys.count)\n")

    log("Step 3: Verifying \(unusedKeys.count) keys by building\n")

    removeKeysFromStringsFile(unusedKeys)
    removeKeysFromStringsdictFile(unusedKeys)

    let buildResult = buildProject()

    log("Reverting source file changes")
    revertChanges()

    guard buildResult.exitCode == 0 else {
        log("BUILD FAILED\n")
        if !buildResult.output.isEmpty {
            log("--- Build log ---\n\(buildResult.output)\n--- End of build log ---\n")
        } else {
            log(
                "No output was captured (fastlane may have suppressed logs). Run manually:\n" +
                    "  cd '\(projectDir)' && PATH=\"$HOME/.rbenv/shims:$HOME/.rbenv/bin:$PATH\" bundle exec fastlane verify_tangem_build_no_sign\n"
            )
        }
        return
    }

    log("BUILD SUCCEEDED: All \(unusedKeys.count) keys are confirmed unused.\n")
    for key in unusedKeys {
        print(key.camel)
    }

    log("\nStep 4: Remove iOS platform from Lokalise (\(project.rawValue)) for unused keys")
    askToRemoveIOSPlatform(forKeys: unusedKeys, lokalise: lokalise)
}

main()
