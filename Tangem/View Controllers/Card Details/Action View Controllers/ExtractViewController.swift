//
//  ExtractViewController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation
import CoreNFC
import TangemKit

@available(iOS 13.0, *)
class ExtractViewController: ModalActionViewController {
    
    private lazy var session: NFCTagReaderSession? = {
        let readerSession = NFCTagReaderSession(pollingOption: .iso14443, delegate: self)
        readerSession?.alertMessage = "Hold your iPhone near a Tangem card"
        return readerSession
    }()
    
    @IBAction func scanTapped() {
        session?.begin()
    }
}


@available(iOS 13.0, *)
extension ExtractViewController: NFCTagReaderSessionDelegate {
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        print(error)
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        if case let .iso7816(tag7816) = tags.first {
            let nfcTag = tags.first!
            session.connect(to: nfcTag) { error in
                guard error == nil else {
                    session.invalidate(errorMessage: error!.localizedDescription)
                    return                }
                
                //[REDACTED_TODO_COMMENT]
                let commandApdu = CommandApdu(with: .sign, tlv: [])
                
                let apdu = NFCISO7816APDU(data: Data(base64Encoded: "")!)!
                tag7816.sendCommand(apdu: apdu) { (data, sw1, sw2, apduError) in
                    guard apduError == nil else {
                       session.invalidate(errorMessage: error!.localizedDescription)
                        return
                    }
                    
                    guard sw1 == 0x90 && sw2 == 0 else {
                        session.invalidate(errorMessage: "Read error. Code \(sw1) \(sw2)")
                        return
                    }
                    
                    let respApdu = ResponseApdu(with: data, sw1: sw1, sw2: sw2)
                    let sign = respApdu.tlv.first { $0.tag == .signature }
                    //[REDACTED_TODO_COMMENT]
                }
                
            }
        }
    }
    
    
}
