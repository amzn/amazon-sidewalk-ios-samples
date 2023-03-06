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

/// View Model for Menu View.
final class MenuViewModel: ObservableObject {

    /// Object controlling how the Login with Amazon section is displayed.
    struct AuthDisplay {
        let statusLabel: String
        let buttonLabel: String
        let buttonFuction: () -> Void
    }

    @Published var authDisplay: AuthDisplay

    init(sidewalkEnvironment: SidewalkEnvironment) {
        self.authDisplay = AuthDisplay(statusLabel: "Initializing",
                                       buttonLabel: "Initializing",
                                       buttonFuction: {})
        sidewalkEnvironment.authService.$authState.map {
            AuthDisplay(state: $0,
                        login: sidewalkEnvironment.authService.login,
                        logout: {
                sidewalkEnvironment.authService.logout()
                sidewalkEnvironment.sidewalk.clearAccountCache { _ in }
            })
        }
        .receive(on: DispatchQueue.main)
        .assign(to: &$authDisplay)
    }
}

extension MenuViewModel.AuthDisplay {
    init(state: AmazonAuthService.AuthState, login: @escaping () -> Void, logout: @escaping () -> Void) {
        switch state {
        case .authenticated:
            statusLabel = "Status: Logged In"
            buttonLabel = "Sign Out"
            buttonFuction = logout
        case .none:
            statusLabel = "Status: Logged Out"
            buttonLabel = "Sign In"
            buttonFuction = login
        }
    }
}
