import Foundation
import TangemFoundation

// MARK: - Simple Usage Examples

class SimpleIPhoneModelUsage {
    // MARK: - 1. Basic Device Detection

    func getCurrentDevice() {
        if let currentModel = IPhoneModel() {
            print("Current device: \(currentModel.name)")
        } else {
            print("Could not determine iPhone model")
        }
    }

    // MARK: - 2. Check for iPhone 7/7+ Limitations

    func isIPhone7OrPlus() -> Bool {
        guard let currentModel = IPhoneModel() else { return false }

        switch currentModel {
        case .iPhone7, .iPhone7Plus:
            return true
        default:
            return false
        }
    }

    // MARK: - 3. Feature Availability Check

    func canUseBackup() -> Bool {
        guard let currentModel = IPhoneModel() else { return false }

        switch currentModel {
        case .iPhone7, .iPhone7Plus:
            return false // iPhone 7/7+ cannot create backups
        default:
            return true
        }
    }

    // MARK: - 4. Transaction Size Limit

    func getMaxTransactionSize() -> Int {
        guard let currentModel = IPhoneModel() else { return 944 }

        switch currentModel {
        case .iPhone7, .iPhone7Plus:
            return 150 // iPhone 7 limitation
        default:
            return 944 // Standard limit
        }
    }

    // MARK: - 5. BLS Signing Support

    func supportsBLSSigning() -> Bool {
        guard let currentModel = IPhoneModel() else { return false }

        switch currentModel {
        case .iPhone7, .iPhone7Plus:
            return false // iPhone 7/7+ doesn't support BLS signing
        default:
            return true
        }
    }

    // MARK: - 6. Show Warnings for iPhone 7/7+

    func getWarningsForCurrentDevice() -> [String] {
        guard let currentModel = IPhoneModel() else { return [] }

        var warnings: [String] = []

        switch currentModel {
        case .iPhone7, .iPhone7Plus:
            warnings.append("Backup functionality not available")
            warnings.append("BLS signing not supported")
            warnings.append("Transaction size limited to 150 bytes")
            warnings.append("NFC issues possible during certain operations")
        default:
            break
        }

        return warnings
    }

    // MARK: - 7. Device-Specific Configuration

    func configureForCurrentDevice() {
        guard let currentModel = IPhoneModel() else {
            print("Using default configuration")
            return
        }

        switch currentModel {
        case .iPhone7, .iPhone7Plus:
            print("Configuring for iPhone 7/7+ with limitations")
            // - Disable backup features
            // - Limit transaction sizes
            // - Show NFC warnings
            // - Disable BLS signing

        case .iPhoneX, .iPhoneXS, .iPhoneXSMax, .iPhoneXR:
            print("Configuring for iPhone X series")
            // - Enable all features
            // - Adjust for notch display

        case .iPhone11, .iPhone11Pro, .iPhone11ProMax:
            print("Configuring for iPhone 11 series")
            // - Enable all features

        case .iPhone12, .iPhone12Mini, .iPhone12Pro, .iPhone12ProMax:
            print("Configuring for iPhone 12 series")
            // - Enable all features

        case .iPhone13, .iPhone13Mini, .iPhone13Pro, .iPhone13ProMax:
            print("Configuring for iPhone 13 series")
            // - Enable all features

        case .iPhone14, .iPhone14Plus, .iPhone14Pro, .iPhone14ProMax:
            print("Configuring for iPhone 14 series")
            // - Enable all features

        case .iPhone15, .iPhone15Plus, .iPhone15Pro, .iPhone15ProMax:
            print("Configuring for iPhone 15 series")
            // - Enable all features

        case .iPhone16, .iPhone16Plus, .iPhone16Pro, .iPhone16ProMax:
            print("Configuring for iPhone 16 series")
            // - Enable all features

        default:
            print("Using default configuration for \(currentModel.name)")
        }
    }
}

// MARK: - Usage Example

extension SimpleIPhoneModelUsage {
    func demonstrateUsage() {
        print("=== Simple iPhone Model Usage ===\n")

        // 1. Get current device
        getCurrentDevice()

        // 2. Check for iPhone 7/7+
        let isIPhone7 = isIPhone7OrPlus()
        print("\nIs iPhone 7/7+: \(isIPhone7)")

        // 3. Check backup availability
        let canBackup = canUseBackup()
        print("Can use backup: \(canBackup)")

        // 4. Get transaction size limit
        let maxSize = getMaxTransactionSize()
        print("Max transaction size: \(maxSize) bytes")

        // 5. Check BLS signing support
        let supportsBLS = supportsBLSSigning()
        print("Supports BLS signing: \(supportsBLS)")

        // 6. Get warnings
        let warnings = getWarningsForCurrentDevice()
        if !warnings.isEmpty {
            print("\n⚠️ Warnings for current device:")
            warnings.forEach { warning in
                print("  - \(warning)")
            }
        }

        // 7. Configure for current device
        print("\n")
        configureForCurrentDevice()
    }
}

// MARK: - Real-world Example: Transaction Builder

class TransactionBuilder {
    func buildTransaction(data: Data) -> TransactionResult {
        guard let currentModel = IPhoneModel() else {
            return .error("Could not determine device model")
        }

        // Check transaction size limit
        let maxSize = getMaxTransactionSize(for: currentModel)
        if data.count > maxSize {
            return .error("Transaction too large for \(currentModel.name). Max size: \(maxSize) bytes")
        }

        // Check BLS signing support if needed
        if needsBLSSigning(for: data), !supportsBLSSigning(for: currentModel) {
            return .error("BLS signing not supported on \(currentModel.name)")
        }

        return .success(transaction: data)
    }

    private func getMaxTransactionSize(for model: IPhoneModel) -> Int {
        switch model {
        case .iPhone7, .iPhone7Plus:
            return 150
        default:
            return 944
        }
    }

    private func supportsBLSSigning(for model: IPhoneModel) -> Bool {
        switch model {
        case .iPhone7, .iPhone7Plus:
            return false
        default:
            return true
        }
    }

    private func needsBLSSigning(for data: Data) -> Bool {
        // Logic to determine if BLS signing is needed
        return false // Simplified for example
    }
}

enum TransactionResult {
    case success(transaction: Data)
    case error(String)
}
