import Foundation
import TangemFoundation

// MARK: - Basic Usage Examples

class IPhoneModelUsageExamples {
    
    // MARK: - 1. Basic Device Detection
    
    func getCurrentDeviceInfo() {
        // Get the current iPhone model
        if let currentModel = IPhoneModel() {
            print("Current device: \(currentModel.name)")
            
            // Check for specific models
            switch currentModel {
            case .iPhone7, .iPhone7Plus:
                print("⚠️ iPhone 7/7+ detected - limited functionality available")
            case .iPhoneX, .iPhoneXS, .iPhoneXSMax, .iPhoneXR:
                print("📱 iPhone X series detected")
            case .iPhone11, .iPhone11Pro, .iPhone11ProMax:
                print("📱 iPhone 11 series detected")
            default:
                print("📱 Other iPhone model: \(currentModel.name)")
            }
        } else {
            print("❌ Could not determine iPhone model")
        }
    }
    
    // MARK: - 2. Feature Availability Checks
    
    func checkFeatureAvailability() -> FeatureAvailability {
        guard let currentModel = IPhoneModel() else {
            return .unknown
        }
        
        switch currentModel {
        case .iPhone7, .iPhone7Plus:
            return .limited(restrictions: [
                "Backup functionality not available",
                "BLS signing not supported",
                "Transaction size limited to 150 bytes",
                "NFC issues possible"
            ])
        case .iPhone8, .iPhone8Plus, .iPhoneX, .iPhoneXS, .iPhoneXSMax, .iPhoneXR:
            return .full
        case .iPhone11, .iPhone11Pro, .iPhone11ProMax:
            return .full
        case .iPhone12, .iPhone12Mini, .iPhone12Pro, .iPhone12ProMax:
            return .full
        case .iPhone13, .iPhone13Mini, .iPhone13Pro, .iPhone13ProMax:
            return .full
        case .iPhone14, .iPhone14Plus, .iPhone14Pro, .iPhone14ProMax:
            return .full
        case .iPhone15, .iPhone15Plus, .iPhone15Pro, .iPhone15ProMax:
            return .full
        case .iPhone16, .iPhone16Plus, .iPhone16Pro, .iPhone16ProMax:
            return .full
        default:
            return .unknown
        }
    }
    
    // MARK: - 3. Transaction Size Validation
    
    func validateTransactionSize(_ data: Data) -> TransactionValidationResult {
        guard let currentModel = IPhoneModel() else {
            return .unknown
        }
        
        let maxSize: Int
        switch currentModel {
        case .iPhone7, .iPhone7Plus:
            maxSize = 150 // iPhone 7 limitation
        default:
            maxSize = 944 // Standard limit for newer devices
        }
        
        if data.count <= maxSize {
            return .valid
        } else {
            return .invalid(
                reason: "Transaction size (\(data.count) bytes) exceeds limit (\(maxSize) bytes) for \(currentModel.name)"
            )
        }
    }
    
    // MARK: - 4. Backup Functionality Check
    
    func canPerformBackup() -> BackupAvailability {
        guard let currentModel = IPhoneModel() else {
            return .unknown
        }
        
        switch currentModel {
        case .iPhone7, .iPhone7Plus:
            return .notAvailable(
                reason: "iPhone 7/7+ is not able to create a backup for Tangem Wallet due to some system limitations. Please use another phone to perform this operation."
            )
        default:
            return .available
        }
    }
    
    // MARK: - 5. BLS Signing Support
    
    func supportsBLSSigning() -> BLSSupport {
        guard let currentModel = IPhoneModel() else {
            return .unknown
        }
        
        switch currentModel {
        case .iPhone7, .iPhone7Plus:
            return .notSupported(
                reason: "iPhone 7/7+ doesn't support BLS signing due to hardware limitations"
            )
        default:
            return .supported
        }
    }
    
    // MARK: - 6. NFC Operation Check
    
    func checkNFCOperation() -> NFCOperationResult {
        guard let currentModel = IPhoneModel() else {
            return .unknown
        }
        
        switch currentModel {
        case .iPhone7, .iPhone7Plus:
            return .warning(
                message: "Some iPhone 7/7+ models may have NFC issues during certain operations."
            )
        default:
            return .normal
        }
    }
    
    // MARK: - 7. Device-Specific UI Adjustments
    
    func getUIAdjustments() -> UIAdjustments {
        guard let currentModel = IPhoneModel() else {
            return UIAdjustments()
        }
        
        var adjustments = UIAdjustments()
        
        switch currentModel {
        case .iPhone7, .iPhone7Plus:
            adjustments.maxTransactionInputs = 15
            adjustments.showBackupWarning = true
            adjustments.showNFCIssueWarning = true
        case .iPhoneX, .iPhoneXS, .iPhoneXSMax, .iPhoneXR:
            adjustments.safeAreaInsets = UIEdgeInsets(top: 44, left: 0, bottom: 34, right: 0)
        case .iPhone12Mini:
            adjustments.compactLayout = true
        default:
            break
        }
        
        return adjustments
    }
    
    // MARK: - 8. Device Grouping
    
    func getDeviceGroup() -> DeviceGroup {
        guard let currentModel = IPhoneModel() else {
            return .unknown
        }
        
        switch currentModel {
        case .iPhone6S, .iPhone6SPlus, .iPhoneSE, .iPhone7, .iPhone7Plus, .iPhone8, .iPhone8Plus:
            return .legacy
        case .iPhoneX, .iPhoneXS, .iPhoneXSMax, .iPhoneXR:
            return .modern
        case .iPhone11, .iPhone11Pro, .iPhone11ProMax:
            return .modern
        case .iPhone12, .iPhone12Mini, .iPhone12Pro, .iPhone12ProMax:
            return .modern
        case .iPhone13, .iPhone13Mini, .iPhone13Pro, .iPhone13ProMax:
            return .modern
        case .iPhone14, .iPhone14Plus, .iPhone14Pro, .iPhone14ProMax:
            return .modern
        case .iPhone15, .iPhone15Plus, .iPhone15Pro, .iPhone15ProMax:
            return .modern
        case .iPhone16, .iPhone16Plus, .iPhone16Pro, .iPhone16ProMax:
            return .modern
        }
    }
}

// MARK: - Supporting Types

enum FeatureAvailability {
    case full
    case limited(restrictions: [String])
    case unknown
}

enum TransactionValidationResult {
    case valid
    case invalid(reason: String)
    case unknown
}

enum BackupAvailability {
    case available
    case notAvailable(reason: String)
    case unknown
}

enum BLSSupport {
    case supported
    case notSupported(reason: String)
    case unknown
}

enum NFCOperationResult {
    case normal
    case warning(message: String)
    case unknown
}

enum DeviceGroup {
    case legacy
    case modern
    case unknown
}

struct UIAdjustments {
    var maxTransactionInputs: Int = 100
    var showBackupWarning: Bool = false
    var showNFCIssueWarning: Bool = false
    var safeAreaInsets: UIEdgeInsets = .zero
    var compactLayout: Bool = false
}

// MARK: - Usage Examples

extension IPhoneModelUsageExamples {
    
    func demonstrateUsage() {
        print("=== iPhone Model Usage Examples ===\n")
        
        // 1. Basic device detection
        getCurrentDeviceInfo()
        
        // 2. Feature availability
        let featureAvailability = checkFeatureAvailability()
        print("\nFeature Availability: \(featureAvailability)")
        
        // 3. Transaction validation
        let sampleData = Data(repeating: 0, count: 200)
        let validation = validateTransactionSize(sampleData)
        print("\nTransaction Validation: \(validation)")
        
        // 4. Backup check
        let backupAvailability = canPerformBackup()
        print("\nBackup Availability: \(backupAvailability)")
        
        // 5. BLS signing check
        let blsSupport = supportsBLSSigning()
        print("\nBLS Support: \(blsSupport)")
        
        // 6. NFC operation check
        let nfcResult = checkNFCOperation()
        print("\nNFC Operation: \(nfcResult)")
        
        // 7. UI adjustments
        let uiAdjustments = getUIAdjustments()
        print("\nUI Adjustments: \(uiAdjustments)")
        
        // 8. Device grouping
        let deviceGroup = getDeviceGroup()
        print("\nDevice Group: \(deviceGroup)")
    }
}

// MARK: - Real-world Implementation Example

class DeviceSpecificFeatureManager {
    
    func configureFeaturesForCurrentDevice() {
        guard let currentModel = IPhoneModel() else {
            // Fallback to default configuration
            configureDefaultFeatures()
            return
        }
        
        switch currentModel {
        case .iPhone7, .iPhone7Plus:
            configureLegacyFeatures()
        case .iPhone8, .iPhone8Plus, .iPhoneX, .iPhoneXS, .iPhoneXSMax, .iPhoneXR:
            configureModernFeatures()
        case .iPhone11, .iPhone11Pro, .iPhone11ProMax:
            configureModernFeatures()
        case .iPhone12, .iPhone12Mini, .iPhone12Pro, .iPhone12ProMax:
            configureModernFeatures()
        case .iPhone13, .iPhone13Mini, .iPhone13Pro, .iPhone13ProMax:
            configureModernFeatures()
        case .iPhone14, .iPhone14Plus, .iPhone14Pro, .iPhone14ProMax:
            configureModernFeatures()
        case .iPhone15, .iPhone15Plus, .iPhone15Pro, .iPhone15ProMax:
            configureModernFeatures()
        case .iPhone16, .iPhone16Plus, .iPhone16Pro, .iPhone16ProMax:
            configureModernFeatures()
        default:
            configureDefaultFeatures()
        }
    }
    
    private func configureLegacyFeatures() {
        // Configure features for iPhone 7/7+ and older devices
        print("Configuring legacy features for iPhone 7/7+")
        // - Disable backup functionality
        // - Limit transaction sizes
        // - Show NFC warnings
        // - Disable BLS signing
    }
    
    private func configureModernFeatures() {
        // Configure features for modern devices
        print("Configuring modern features")
        // - Enable all features
        // - Full transaction support
        // - Full backup support
    }
    
    private func configureDefaultFeatures() {
        // Fallback configuration
        print("Configuring default features")
    }
} 
