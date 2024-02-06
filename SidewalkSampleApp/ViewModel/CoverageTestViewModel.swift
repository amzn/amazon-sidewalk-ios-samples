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
import Combine

enum CoverageTestDisplayState {
    case start
    case progress
    case report
}

final class CoverageTestViewModel: ObservableObject {

    //Input values to Start Coverage Test
    @Published var pingIntervalString = "\(SidewalkCoverageTestOption.defaultPingInterval)"
    @Published var testDurationString = "\(SidewalkCoverageTestOption.defaultTestDuration)"

    let pingIntervalSubTitle = "Enter value from \(SidewalkCoverageTestOption.minPingInterval) to \(SidewalkCoverageTestOption.maxPingInterval) (seconds)"
    var testDurationSubTitle: String {
        return "Enter value from \(pingIntervalString) to \(UInt16.max) (seconds)"
    }

    @Published var formIsValid: Bool = false
    @Published var shouldClose: Bool = false
    @Published var report: SidewalkCoverageTestReport?

    @Published var coverageTestDisplayState: CoverageTestDisplayState = .start
    @Published var alertModel = AlertModel(alertTitle: "", alertText: "", buttonText: "")
    @Published var showAlert = false
    @Published var showSpinner = false

    private var publishers = Set<AnyCancellable>()
    private let sidewalk: Sidewalk
    private let device: SidewalkDevice
    private var state: State = .setup {
        didSet {
            switch state {
            case .setup, .connecting, .starting:
                coverageTestDisplayState = .start
            case .inProgress:
                coverageTestDisplayState = .progress
            case .report:
                coverageTestDisplayState = .report
            case .dismissed:
                shouldClose = true
            }
        }
    }

    private enum State {
        case setup
        case connecting(SidewalkCancellable)
        case starting(SidewalkCancellable, SidewalkConnection)
        case inProgress(SidewalkCancellable, SidewalkConnection)
        case report(SidewalkCancellable, SidewalkConnection)
        case dismissed
    }

    /// Sidewalk instance is injected and shared across Sidewalk Sample App.
    required init(sidewalk: Sidewalk, device: SidewalkDevice) {
        self.sidewalk = sidewalk
        self.device = device

        isStartCoverageTestValidPublisher
            .receive(on: RunLoop.main)
            .assign(to: \.formIsValid, on: self)
            .store(in: &publishers)
    }

    func connectAndStartTest() {
        secureConnect(device: device)
    }

    func stopAndShowReport() {
        guard case let .inProgress(task, _) = state else { return }
        task.cancel()
        showSpinner = true //"Stopping..."
        // Will show report view when SDK sends event `collectingReport`.
    }

    func exit() {
        navigateToRootViewController()
    }

    private func secureConnect(device: SidewalkDevice) {
        guard case .setup = state else {
            return
        }
        showSpinner = true
        // secureConnect returns a SidewalkCancellable, which must be held in memory. If released, it will automatically cancel the operation.
        let operation = sidewalk.secureConnect(device: device) { [weak self] result in
            DispatchQueue.main.async {
                guard let strongSelf = self else { return }
                strongSelf.showSpinner = false
                switch result {
                case .success(let connection):
                    strongSelf.startTest(connection: connection)
                case .failure(let error):
                    strongSelf.handlerError(error)
                }
            }
        }
        state = .connecting(operation)
    }

    private func startTest(connection: SidewalkConnection) {
        guard case .connecting = state,
              let pingIntervalInt = pingIntervalString.toUInt16,
              let testDurationInt = testDurationString.toUInt16 else { return }
        showSpinner = true

        let option = SidewalkCoverageTestOption(pingInterval: pingIntervalInt,
                                                testDuration: testDurationInt,
                                                shouldReceivePingPongProgress: true)

        let task = connection.startCoverageTest(option: option,
                                                onProgressUpdated: { [weak self] event in
            DispatchQueue.main.async {
                guard let strongSelf = self else { return }
                strongSelf.handleOnProgressUpdate(for: event)
            }
        },
                                                completion: { [weak self] result in
            DispatchQueue.main.async {
                guard let strongSelf = self else { return }
                strongSelf.handleCompletion(for: result)
            }
        })

        state = .starting(task, connection)
    }

    private func handleCompletion(for result: Result<SidewalkCoverageTestReport, SidewalkError>) {
        showSpinner = false

        switch result {
        case .success(let report):
            handlerReport(report)
        case .failure(let error):
            handlerError(error)
        }
    }

    private func handlerReport(_ report: SidewalkCoverageTestReport) {
        guard case .report = state else { return }
        self.report = report
    }

    private func handlerError(_ error: SidewalkError) {
        switch state {
        case .setup,
             .dismissed:
            break
        case .connecting, .starting, .inProgress, .report:
            displayErrorAndNavigateToRoot(error: error)
        }
    }

    private func displayErrorAndNavigateToRoot(error: SidewalkError) {
        alertModel = AlertModel(alertTitle: "Failure",
                                alertText: "Error Detail: \(error.localizedDescription)",
                                buttonText: "OK", buttonAction: { [weak self] in
            self?.navigateToRootViewController()
        })
        showAlert = true
    }

    private func navigateToRootViewController() {
        switch state {
        case .dismissed:
            break
        case .setup,
             .connecting,
             .starting,
             .inProgress,
             .report:
            state = .dismissed
        }
    }

    private func handleOnProgressUpdate(for event: SidewalkCoverageTestEvent) {
        switch event {
        case .testStart:
            guard case let .starting(task, connection) = state else { return }
            showSpinner = false
            state = .inProgress(task, connection)
        case let .pingEvent(id, linkType, timestamp, outputPower):
            guard case .inProgress = state else { return }
            print( "pingEvent\n id:\(id), linkType:\(linkType), timestamp:\(timestamp), outputPower:\(outputPower)")
        case let .pongEvent(id, linkType, timestamp, latency, rssi, snr):
            guard case .inProgress = state else { return }
            print("pongEvent \n id: \(id), linkType: \(linkType), timestamp: \(timestamp), latency:\(String(describing: latency)) rssi: \(rssi), snr: \(snr) ")
        case let .missedPongEvent(id, timestamp):
            guard case .inProgress = state else { return }
            print( "missedPongEvent \n id: \(id), timestamp: \(timestamp)")
        case .collectingReport:
            guard case let .inProgress(task, connection) = state else { return }
            showSpinner = true // "Reading report..."
            state = .report(task, connection)
        @unknown default:
            let message = "Warning: Received unexpected event \(event)."
            assertionFailure(message)
        }
    }
}

// MARK: - Setup validations

private extension CoverageTestViewModel {

    var isValidPingInterval: AnyPublisher<Bool, Never> {
        $pingIntervalString
            .map { pingIntervalString in
                guard let value = pingIntervalString.toUInt16 else { return false }
                return (SidewalkCoverageTestOption.minPingInterval...SidewalkCoverageTestOption.maxPingInterval).contains(value)
            }
            .eraseToAnyPublisher()
    }

    var isValidTestDuration: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest($pingIntervalString, $testDurationString)
            .map { pingIntervalString, testDurationString  in
                guard let pingIntervalInt = pingIntervalString.toUInt16, let testDurationInt = testDurationString.toUInt16 else { return false }
                return pingIntervalInt <= testDurationInt
            }
            .eraseToAnyPublisher()
    }

    var isStartCoverageTestValidPublisher: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest(isValidPingInterval, isValidTestDuration)
            .map { isValidPingInterval, isValidTestDuration in
                return isValidPingInterval && isValidTestDuration
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - String extension to convert to UInt16
extension String {
    var toUInt16: UInt16? {
        return UInt16(self)
    }
}
