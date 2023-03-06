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

struct CoverageTestView: View {
    @ObservedObject var viewModel: CoverageTestViewModel
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    init(viewModel: CoverageTestViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        LoadingView(show: $viewModel.showSpinner) {
            CoverageTestStagesView(coverageTestDisplayState: $viewModel.coverageTestDisplayState) {
                CoverageTestStartView(viewModel: viewModel)
            } progressContent: {
                CoverageTestProgressView(viewModel: viewModel)
            } reportContent: {
                CoverageTestReportView(viewModel: viewModel)
            }
        }
        .navigationTitle("Sidewalk Coverage Test")
        .onReceive(self.viewModel.$shouldClose) { shouldClose in
            if shouldClose {
                self.presentationMode.wrappedValue.dismiss()
            }
        }
        .alert(isPresented: $viewModel.showAlert) {
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

struct CoverageTestStagesView<Stage1, Stage2, Stage3>: View where Stage1: View, Stage2: View, Stage3: View {
    @Binding var coverageTestDisplayState: CoverageTestDisplayState
    @ViewBuilder var startContent: () -> Stage1
    @ViewBuilder var progressContent: () -> Stage2
    @ViewBuilder var reportContent: () -> Stage3

    var body: some View {
        VStack(alignment: .center) {
            switch coverageTestDisplayState {
            case .start:
                startContent()
            case .progress:
                progressContent()
            case .report:
                reportContent()
            }
        }
    }
}

struct CoverageTestStartView: View {
    @ObservedObject var viewModel: CoverageTestViewModel

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading) {
                    Text("Set Ping Interval")
                    Text(viewModel.pingIntervalSubTitle)
                        .font(.footnote)
                        .foregroundColor(.gray)
                    TextField(viewModel.pingIntervalSubTitle,
                              text: $viewModel.pingIntervalString)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                }

                VStack(alignment: .leading) {
                    Text("Set Test Duration")
                    Text(viewModel.testDurationSubTitle)
                        .font(.footnote)
                        .foregroundColor(.gray)
                    TextField(viewModel.testDurationSubTitle,
                              text: $viewModel.testDurationString)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                }
            }
            Button(" Start") {
                viewModel.connectAndStartTest()
            }
            .padding()
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .cornerRadius(15)
            .opacity(viewModel.formIsValid ? 1 : 0.5)
            .disabled(!viewModel.formIsValid)
        }
    }
}

struct CoverageTestProgressView: View {
    @ObservedObject var viewModel: CoverageTestViewModel

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading) {
                    Text("Performing test")
                        .font(.headline)
                    Text("Keep your phone near the device during this process.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            Section {
                ProgressView {
                    Text("Test Progress")
                }
                .frame(maxWidth: .infinity)
            }
            Button("Stop") {
                viewModel.stopAndShowReport()
            }
            .padding()
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .background(Color.red)
            .cornerRadius(15)
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct CoverageTestReportView: View {
    @ObservedObject var viewModel: CoverageTestViewModel

    var body: some View {
        Form {
            Section {
                Text("Report")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }

            Section {
                if let report = viewModel.report {
                    Text("Total Pings: \(report.totalPings)")
                    Text("Total Received Pongs: \(report.totalReceivedPongs)")
                    Text("Link Type: " + "\(report.linkType)")
                } else {
                    Text("Loading..")
                }
            }
            Button("Done") {
                viewModel.exit()
            }
            .padding()
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .cornerRadius(15)
        }
        .navigationBarBackButtonHidden(true)
    }
}
