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

import Foundation
import SidewalkSDK

/// View Model for Scan View, showcasing how to scan for and interact with scanned objects.
final class ScanViewModel: ObservableObject {

    /// Enum modeling the status of a scan.
    enum ScanState {
        case initial
        /// UUID used to differentiate between different scan requests.
        case scanning(UUID)
        case completed
        case error

        var description: String {
            switch self {
            case .initial:
                return "Not scanning"
            case .scanning:
                return "Scanning"
            case .completed:
                return "Scan completed"
            case .error:
                return "Scan errored out"
            }
        }
    }

    @Published var scanState: ScanState = .initial
    @Published var alertModel = AlertModel(alertTitle: "", alertText: "", buttonText: "")
    @Published var showAlert = false
    @Published var showSpinner = false
    /// Scanned devices are stored in a dictionary, so that updated scan responses of the same SMSN overwrite previous responses.
    @Published var devices: [String: SidewalkDevice]
    @Published var connection: SidewalkConnection? = nil
    var connectionDeviceID: String = ""
    var connectionDeviceIsRegistered: Bool = false

    /// Boolean controlling whether the connection view is shown. When connection view is not shown, disconnect the connection.
    @Published var showConnection: Bool = false {
        didSet {
            if showConnection == false {
                connection?.disconnect()
                connection = nil
            }
        }
    }
    @Published var showCoverageTest: Bool = false
    var selectedDevice: SidewalkDevice?

    let sidewalk: Sidewalk
    var operation: SidewalkCancellable? = nil

    /// Sidewalk instance is injected and shared across Sidewalk Sample App.
    init(sidewalkEnvironment: SidewalkEnvironment) {
        sidewalk = sidewalkEnvironment.sidewalk
        devices = [:]
    }

    /// Scan for devices.
    func scanForDevices() {
        let scanId = UUID()
        stopOperation()
        devices = [:]

        // scan returns a SidewalkCancellable, which must be held in memory. If released, it will automatically cancel the operation.
        operation = sidewalk.scan(onDeviceFound: didDetectDeviceDuringScan) { [weak self] result in
            DispatchQueue.main.async {
                guard let strongSelf = self else { return }
                switch result {
                case .success:
                    if case let .scanning(id) = strongSelf.scanState, id == scanId {
                        strongSelf.scanState = .completed
                    }
                case .failure(let error):
                    if case let .scanning(id) = strongSelf.scanState, id == scanId {
                        strongSelf.scanState = .error
                    }
                    strongSelf.alertModel = AlertModel(alertTitle: "Failure",
                                                       alertText: "Scanning failed with error: \(error.localizedDescription)",
                                                       buttonText: "OK")
                    strongSelf.showAlert = true
                }
            }
        }
        self.scanState = .scanning(scanId)
    }

    /// Stops any current operation.
    func stopOperation() {
        operation?.cancel()
        operation = nil
    }

    /// Registers a scanned device.
    func register(device: SidewalkDevice) {
        stopOperation()

        // register returns a SidewalkCancellable, which must be held in memory. If released, it will automatically cancel the operation.
        operation = sidewalk.registerDevice(smsn: device.truncatedSmsn) { [weak self] result in
            DispatchQueue.main.async {
                guard let strongSelf = self else { return }
                switch result {
                case .success(let detail):
                    strongSelf.alertModel = AlertModel(alertTitle: "Success",
                                                       alertText: "\(device.truncatedSmsn) \(detail.message)",
                                                       buttonText: "OK") {
                        strongSelf.scanForDevices()
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

    /// Securely connect to a scanned device over BLE.
    func secureConnect(device: SidewalkDevice) {
        stopOperation()

        // secureConnect returns a SidewalkCancellable, which must be held in memory. If released, it will automatically cancel the operation.
        operation = sidewalk.secureConnectDevice(smsn: device.truncatedSmsn) { [weak self] result in
            DispatchQueue.main.async {
                guard let strongSelf = self else { return }
                strongSelf.showSpinner = false
                switch result {
                case .success(let connection):
                    strongSelf.connection = connection
                    strongSelf.showConnection = true
                    strongSelf.connectionDeviceID = device.truncatedSmsn
                    strongSelf.connectionDeviceIsRegistered = device.beaconInfo.deviceMode != .oobe

                case .failure(let error):
                    strongSelf.alertModel = AlertModel(alertTitle: "Failure",
                                                       alertText: "Establish Secure Connection failed with error: \(error.localizedDescription)",
                                                       buttonText: "OK")
                    strongSelf.showAlert = true
                }
            }
        }
        showSpinner = true
    }

    /// Scanned device callback.
    private func didDetectDeviceDuringScan(device: SidewalkDevice) {
        DispatchQueue.main.async {
            // We are filtering based off of the device's SMSN value.
            self.devices[device.truncatedSmsn] = device
        }
    }

}
