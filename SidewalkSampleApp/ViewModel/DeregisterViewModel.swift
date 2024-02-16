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

/// View Model for Deregistration View.
final class DeregisterViewModel: ObservableObject {
    enum State {
        case hidden
        case input
        case loading
        case confirmation(Result<String, Error>)
    }

    let sidewalk: Sidewalk
    @Published var smsn: String = ""
    @Published var state: State
    var operation: SidewalkCancellable? = nil

    init(sidewalkEnvironment: SidewalkEnvironment) {
        sidewalk = sidewalkEnvironment.sidewalk
        state = .hidden
    }

    /// Deregister a Sidewalk device via a SMSN.
    func deregister() {
        // The smsn is expected to be provided by the consuming application.
        operation = sidewalk.deregisterDevice(smsn: smsn, factoryReset: true) { [weak self] result in
            DispatchQueue.main.async {
                guard let strongSelf = self else { return }
                switch result {
                case .success:
                    strongSelf.state = .confirmation(.success("Deregistration for \(strongSelf.smsn) succeeded"))
                case .failure(let error):
                    strongSelf.state = .confirmation(.failure(error))
                }
            }
        }
        state = .loading
    }
}
