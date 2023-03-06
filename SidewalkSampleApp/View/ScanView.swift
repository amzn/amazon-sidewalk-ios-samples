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

/// View that handles scanning Sidewalk devices, displaying scanned devices, and interactions with scanned devices.
struct ScanView: View {
    let sidewalkEnvironment: SidewalkEnvironment
    @ObservedObject var viewModel: ScanViewModel
    @State private var showingMenu = false

    init(sidewalkEnvironment: SidewalkEnvironment) {
        self.sidewalkEnvironment = sidewalkEnvironment
        viewModel = ScanViewModel(sidewalkEnvironment: sidewalkEnvironment)
    }

    var body: some View {
        LoadingView(show: $viewModel.showSpinner) {
            NavigationView {
                VStack {
                    // A non-visible navigation link to the Menu view
                    NavigationLink(isActive: self.$showingMenu) {
                        MenuView(sidewalkEnvironment: sidewalkEnvironment).onAppear {
                            viewModel.stopOperation()
                        }
                    } label: {
                        EmptyView()
                    }

                    // A non-visible navigation link to the Covearge Test View
                    NavigationLink(isActive: $viewModel.showCoverageTest) {
                        if let device = viewModel.selectedDevice {
                            let coverageTestViewModel = CoverageTestViewModel(sidewalk: sidewalkEnvironment.sidewalk, device: device)
                            CoverageTestView(viewModel: coverageTestViewModel).onAppear {
                                viewModel.stopOperation()
                            }
                        } else {
                            EmptyView()
                        }
                    } label: {
                        EmptyView()
                    }

                    // A non-visible navigation link to the Connection view
                    NavigationLink(isActive: $viewModel.showConnection) {
                        if let connection = viewModel.connection {
                            let connectionViewModel = ConnectionViewModel(sidewalkEnvironment: sidewalkEnvironment,
                                                                          sidewalkConnection: connection,
                                                                          deviceID: viewModel.connectionDeviceID,
                                                                          showSelf: $viewModel.showConnection,
                                                                          iRegistered: viewModel.connectionDeviceIsRegistered)
                            ConnectionView(viewModel: connectionViewModel).onAppear {
                                viewModel.stopOperation()
                            }
                        } else {
                            EmptyView()
                        }
                    } label: {
                        EmptyView()
                    }

                    // Complete list of scanned devices
                    let devices = viewModel.devices.map { $0.value }
                    // List of devices in Out-of-box experience mode
                    let oobeDevices = devices.filter { $0.beaconInfo.deviceMode == .oobe }
                    // List of devices not in Out-of-box experience mode
                    let registeredDevices = devices.filter { $0.beaconInfo.deviceMode != .oobe }

                    List {
                        if !oobeDevices.isEmpty {
                            Section(header: Text("UNREGISTERED DEVICES")) {
                                ForEach(oobeDevices, id: \.endpointID) { device in
                                    SidewalkDeviceRow(device: device, viewModel: viewModel)
                                }
                            }
                        }
                        if !registeredDevices.isEmpty {
                            Section(header: Text("REGISTERED DEVICES")) {
                                ForEach(registeredDevices, id: \.endpointID) { device in
                                    SidewalkDeviceRow(device: device, viewModel: viewModel)
                                }
                            }
                        }
                    }.listStyle(InsetGroupedListStyle())

                    Spacer()

                    Text(viewModel.scanState.description)

                }.onAppear {
                    // Scans for devices automatically upon displaying this view
                    viewModel.scanForDevices()
                }.navigationTitle("Scan")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Menu") {
                                showingMenu = true
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                viewModel.scanForDevices()
                            }, label: {
                                Image(systemName: "arrow.clockwise")
                            })
                        }
                    }.alert(isPresented: $viewModel.showAlert) {
                        let buttonAction = {
                            viewModel.showAlert = false
                            viewModel.alertModel.buttonAction?()
                        }
                        return Alert(title: Text(viewModel.alertModel.alertTitle),
                              message: Text(viewModel.alertModel.alertText),
                              dismissButton: .default(Text(viewModel.alertModel.buttonText),
                                                      action: buttonAction))
                    }
            }
        }
    }
}

struct SidewalkDeviceRow: View {
    let device: SidewalkDevice
    let viewModel: ScanViewModel

    var body: some View {
        HStack {
            Text(device.name ?? "Unknown")
            Text(device.endpointID)
            Text("\(device.rssi)" )
        }.contextMenu {
            // Allow registration when the device is in Out-of-box experience mode
            if device.beaconInfo.deviceMode == .oobe {
                Button("Register") {
                    self.viewModel.register(device: device)
                }
            } else {
                Button("Coverage Test") {
                    self.viewModel.showCoverageTest = true
                    self.viewModel.selectedDevice = device
                }
            }
            // Create secure BLE connection with the device
            Button("Secure Connect") {
                self.viewModel.secureConnect(device: device)
            }
        }
    }
}
