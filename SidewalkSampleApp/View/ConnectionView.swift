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

/// View showcasing a secure connection, and handling interactions with the connection.
struct ConnectionView: View {
    @ObservedObject var viewModel: ConnectionViewModel
    @State private var payload: String = ""

    init(viewModel: ConnectionViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        LoadingView(show: $viewModel.showSpinner) {
            VStack {
                Text(getSubscriptionStatus())
                List($viewModel.messages) { message in
                    MessageRow(message: message)
                }
                VStack {
                    RegisterButton(viewModel: viewModel)
                    PayloadView(_viewModel: viewModel, _payload: payload)
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
            }.navigationTitle("Connection View")
                .navigationBarTitleDisplayMode(.inline)
        }
    }

    /// - Returns: String messages, if the connection is subscribed to write/subscribe messages or not.
    private func getSubscriptionStatus() -> String {
        if viewModel.subscriptionStatus {
            return "Subscribed messages from \(viewModel.deviceID)"
        } else {
            return  "Not Subscribed"
        }
    }
}

// Register button view
struct RegisterButton: View {
    @ObservedObject var viewModel: ConnectionViewModel

    var body: some View {
        Button(action: {
            viewModel.register()
        }, label: {
            Text("Register")
                .foregroundColor(.white)
                .frame(width: 200, height: 40)
                .background(viewModel.iRegistered ? Color.gray : Color.blue)
                .cornerRadius(15)
                .padding()
        }).disabled(viewModel.iRegistered)
    }
}

// Payload view
struct PayloadView: View {
    @ObservedObject var viewModel: ConnectionViewModel
    @State private var payload: String = ""

    init(_viewModel: ConnectionViewModel, _payload: String) {
        self.viewModel = _viewModel
        self.payload = _payload
    }

    var body: some View {
        HStack {
            Spacer()
            TextField("ASCII Payload", text: $payload)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disableAutocorrection(true)
            Button(action: {
                viewModel.write(id: "nil", type: .notify, payload: payload)
            }, label: {
                Text("Write")
                    .foregroundColor(.white)
                    .frame(width: 100, height: 40)
                    .background(Color.blue)
                    .cornerRadius(15)
                    .padding()
            })
        }
    }
}

// A struct to store exactly one Message.
struct Message: Identifiable {
    let id = UUID()
    let title: String
}

// A view that shows the data for one Message.
struct MessageRow: View {
    @Binding var message: Message

    var body: some View {
        Text(message.title)
    }
}
