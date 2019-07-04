//
//  Scanner.swift
//  OpenTHC
//
//  Created by Theodore Newell on 4/29/17.
//  Copyright © 2017 OpenTHC. All rights reserved.
//

import Foundation
import AVFoundation
import QRCodeReader

class Scanner {

    private struct Constants {
        static let codeTypes: [AVMetadataObject.ObjectType] = [.qr, .pdf417, .code128]
    }

    private lazy var readerVC: QRCodeReaderViewController = {
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader = QRCodeReader(metadataObjectTypes: Constants.codeTypes, captureDevicePosition: AVCaptureDevice.Position.back)
        }
        let controller = QRCodeReaderViewController(builder: builder)
        controller.modalPresentationStyle = .formSheet
        controller.delegate = self
        return controller
    }()

    func present(from source: UIViewController, completion: @escaping ((String?) -> Void)) {

        guard QRCodeReader.isAvailable() else {
            print("QR Code Reader is not available")
            if Platform.isSimulator {
                completion("https://weedtraqr.com/benefits")
            } else {
                completion(nil)
            }
            return
        }
        
        readerVC.completionBlock = { result in
            guard let result = result else {
                completion(nil)
                return
            }
            completion(result.value)
        }
        source.present(readerVC, animated: true, completion: nil)
    }
}

extension Scanner: QRCodeReaderViewControllerDelegate {

    func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
        stopAndDismissScanner(reader)
    }
    
    func readerDidCancel(_ reader: QRCodeReaderViewController) {
        stopAndDismissScanner(reader)
    }

    private func stopAndDismissScanner(_ reader: QRCodeReaderViewController) {
        reader.stopScanning()
        reader.dismiss(animated: true, completion: nil)
    }
}
