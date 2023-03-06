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

/// Custom popup view handling the deregister use case.
struct DeregisterView<Content>: View where Content: View {
    @ViewBuilder var content: () -> Content
    @ObservedObject var viewModel: DeregisterViewModel

    init(viewModel: DeregisterViewModel,
         content: @escaping () -> Content) {
        self.viewModel = viewModel
        self.content = content
    }

    var body: some View {
        GeometryReader { (deviceSize: GeometryProxy) in
            ZStack(alignment: .center) {
                if case .hidden = viewModel.state {
                    content()
                } else {
                    content().disabled(true)
                        .blur(radius: 3)

                    PopupView(deviceSize: deviceSize) {
                        switch viewModel.state {
                        case .hidden:
                            EmptyView()
                        case .input:
                            InputView(state: $viewModel.state,
                                      sidewalkId: $viewModel.sidewalkId,
                                      deregisterAction: viewModel.deregister)
                        case .loading:
                            LoadingView()
                        case .confirmation(let result):
                            switch result {
                            case.success(let description):
                                ConfirmationView(state: $viewModel.state,
                                                 title: "Success",
                                                 description: description)
                            case .failure(let error):
                                ConfirmationView(state: $viewModel.state,
                                                 title: "Failure",
                                                 description: "Deregistration failed with error: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
        }
    }

    private struct InputView: View {
        @Binding var state: DeregisterViewModel.State
        @Binding var sidewalkId: String
        let deregisterAction: () -> Void

        var body: some View {
            VStack {
                Text("Deregister").font(.title)
                TextField("Sidewalk ID", text: $sidewalkId).textFieldStyle(.roundedBorder)
                Divider()
                HStack {
                    Spacer()
                    Button("Deregister") {
                        deregisterAction()
                    }.foregroundColor(.red)
                    Spacer()
                    Button("Cancel") {
                        withAnimation {
                            self.state = .hidden
                        }
                    }
                    Spacer()
                }
            }
        }
    }

    private struct LoadingView: View {
        var body: some View {
            VStack {
                Text("Deregister").font(.title)
                Divider()
                HStack {
                    ProgressView().padding()
                    Text("Please wait")
                    Spacer()
                }
            }
        }
    }

    private struct ConfirmationView: View {
        @Binding var state: DeregisterViewModel.State
        let title: String
        let description: String

        var body: some View {
            VStack {
                Text(title).font(.title)
                Text(description)
                Divider()
                Button("OK") {
                    withAnimation {
                        self.state = .hidden
                    }
                }
            }
        }
    }

    private struct PopupView<Content>: View where Content: View {
        let deviceSize: GeometryProxy
        @ViewBuilder var content: () -> Content

        var body: some View {
            content().padding()
                .background(Color.white)
                .cornerRadius(15)
                .frame(
                    width: deviceSize.size.width*0.7,
                    height: deviceSize.size.height*0.7
                )
        }
    }

}
