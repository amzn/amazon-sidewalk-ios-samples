//
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this
// software and associated documentation files (the "Software"), to deal in the Software
// without restriction, including without limitation the rights to use, copy, modify,
// merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
// PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import SwiftUI
import SidewalkSDK

/// View Model for Connection View.
final class ConnectionViewModel: ObservableObject {
    let sidewalk: Sidewalk
    let sidewalkConnection: SidewalkConnection
    var operation: SidewalkCancellable? = nil
    var operationSubscribe: SidewalkCancellable? = nil
    var deviceID: String = ""
    var iRegistered = false

    @Published var alertModel = AlertModel(alertTitle: "", alertText: "", buttonText: "")
    @Published var showAlert = false
    @Published var showSpinner = false
    @Binding var showSelf: Bool
    @Published var messages: [Message] = []
    @Published var subscriptionStatus: Bool = false

    init(sidewalkEnvironment: SidewalkEnvironment,
         sidewalkConnection: SidewalkConnection,
         deviceID: String,
         showSelf: Binding<Bool>,
         iRegistered: Bool) {
        self.sidewalkConnection = sidewalkConnection
        sidewalk = sidewalkEnvironment.sidewalk
        _showSelf = showSelf
        self.deviceID = deviceID
        self.iRegistered = iRegistered
        subscribeMessages()
    }

    /// Register a Sidewalk device that is already securely connected.
    ///
    /// Prefer using `registerDevice(connection:completion:)` over `registerDevice(smsn:completion:)` for
    /// securely connected devices.
    func register() {
        operation?.cancel()
        operation = sidewalk.registerDevice(connection: sidewalkConnection) { [weak self] result in
            DispatchQueue.main.async {
                guard let strongSelf = self else { return }
                switch result {
                case .success(let detail):
                    strongSelf.alertModel = AlertModel(alertTitle: "Success",
                                                       alertText: "\(strongSelf.deviceID) \(detail.message)",
                                                       buttonText: "OK") {
                        strongSelf.showSelf = false
                    }
                case .failure(let error):
                    strongSelf.alertModel = AlertModel(alertTitle: "Failure",
                                                       alertText: "Registration failed with error: \(error.localizedDescription)",
                                                       buttonText: "OK")
                }
                strongSelf.showSpinner = false
                strongSelf.showAlert = true
            }
        }
        showSpinner = true
    }

    /// Writes a message to a Sidewalk device.
    /// - Parameters:
    ///   - idRaw: Optional 14 bit id associated with a message, must be between 0 and 16383 (0x3FFF).
    ///   - type: The message type.
    ///   - payloadRaw: The message payload.
    func write(id idRaw: String, type: SidewalkMessage.MessageType, payload payloadRaw: String) {
        let id: UInt16? = UInt16(idRaw)
        let payloadNoSpace = payloadRaw.filter { !$0.isWhitespace }
        let payload = Data(asciiEncoded: payloadNoSpace)
        let message = SidewalkMessage(id: id, type: type, message: payload)
        operation = sidewalkConnection.write(message: message, completion: { [weak self] result in
            DispatchQueue.main.async {
                guard let strongSelf = self else { return }
                switch result {
                case .success:
                    let str = message.message.asciiEncodedString()
                    let timestamp = strongSelf.getTimestamp()
                    strongSelf.messages.append(Message(title: "\(timestamp) Write- \(str)"))
                case .failure(let error):
                    strongSelf.alertModel = AlertModel(alertTitle: "Write failed",
                                                       alertText: "Write failed with error: \(error.localizedDescription)",
                                                       buttonText: "OK")
                    strongSelf.showAlert = true
                }
            }
        })
    }

    /// Listen for messages and connection status from Sidewalk device.
    func subscribeMessages() {
        subscriptionStatus = true
        operationSubscribe = sidewalkConnection.subscribe(onMessageReceived: { [weak self] message in
            DispatchQueue.main.async {
                guard let strongSelf = self else { return }

                let str = message.message.asciiEncodedString()
                let timestamp = strongSelf.getTimestamp()
                strongSelf.messages.append(Message(title: "\(timestamp) Read- \(str)"))
            }
        }, completion: { [weak self] result in
            guard let strongSelf = self else { return }

            let alertTitle: String = "Subscription terminated"
            var alertDescription: String = ""

            if case .failure(let error) = result {
                alertDescription = "\(error.localizedDescription)"
            }

            DispatchQueue.main.async {
                strongSelf.subscriptionStatus = false
                strongSelf.alertModel = AlertModel(alertTitle: alertTitle,
                                                   alertText: alertDescription,
                                                   buttonText: "OK")
                strongSelf.showAlert = true
            }
        })
    }

    private func getTimestamp() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        let date = Date()
        let timeString = dateFormatter.string(from: date)
        return timeString
    }
}

extension Data {
     init(asciiEncoded string: String) {
         let asciiValues: [UInt8] = string.map { $0.asciiValue ?? 0 }
         self.init(asciiValues)
     }

     func asciiEncodedString() -> String {
         return String(bytes: self, encoding: .ascii) ?? ""
     }
 }
