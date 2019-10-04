//
//  CommandApdu.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//

public struct CommandApdu {
    private let isoCLA: UInt8 = 0x00
    private let legacyModeTlv = CardTLV(.legacyMode, value: [UInt8(4)])
    
    //MARK: Header
    private let cla: UInt8
    private let ins: UInt8
    private let p1:  UInt8
    private let p2:  UInt8
    
    //MARK: Body
    private let lc: Int
    private let data: [UInt8]
    private let le: UInt8 = 0x00
    
    
    public init(with instruction: Instruction, tlv: [CardTLV]) {
        cla = isoCLA
        ins = instruction.rawValue
        p1 = 0
        p2 = 0
        data = (CommandApdu.needLegacyMode ? tlv + [legacyModeTlv] : tlv).bytes
        lc = data.count
    }
    
    public func buildCommand() -> [UInt8] {
        var length = 4 // CLA, INS, P1, P2
        
        if lc != 0 {
            length += 1 // LC
            if lc >= 256 {
                length += 2;
            }
            length += lc // DATA
        }
        
        var apdu = [UInt8]()
        apdu.reserveCapacity(length)
        
        apdu.append(cla)
        apdu.append(ins)
        apdu.append(p1)
        apdu.append(p2)
        
        if lc != 0 {
            if lc < 256 {
                apdu.append(lc.byte)
            } else {
                apdu.append(0)
                apdu.append(contentsOf: lc.tlvBytes)
            }
            apdu.append(contentsOf: data)
        }
        return apdu
    }
    
    private static var needLegacyMode: Bool {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier == "iPhone9,1" || identifier == "iPhone9,2" || identifier == "iPhone9,3" || identifier == "iPhone9,4"
    }
}
