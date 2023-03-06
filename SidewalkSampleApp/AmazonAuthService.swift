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

import SidewalkSDK
import LoginWithAmazon
import os.log

/// Helper class for Login with Amazon.
final class AmazonAuthService {

    /// Enum storing the current authentication status.
    enum AuthState {
        case none
        case authenticated
    }

    struct AuthError: Error {}

    init() {
        updateAuthState()
    }

    @Published var authState: AuthState = .none

    /// Updates the internal auth status using a authroization request
    func updateAuthState() {
        let request: AMZNAuthorizeRequest = AMZNAuthorizeRequest()
        request.interactiveStrategy = .never

        lwaAuthorize(request: request)
    }

    /// Creates a request to authenticate that pops up a login page if the user is not already logged in.
    func login() {
        let request: AMZNAuthorizeRequest = AMZNAuthorizeRequest()
        request.scopes = [AMZNScopeFactory.scope(withName: "sidewalk::manage_endpoint")]

        lwaAuthorize(request: request)
    }

    /// Logs the user out
    func logout() {
        AMZNAuthorizationManager.shared().signOut { error in
            if let error = error {
                os_log(.error, "%@", "Error found when calling LWA sign out: \(error)")
                self.updateAuthState()
            } else {
                self.authState = .none
            }
        }
    }

    private func lwaAuthorize(request: AMZNAuthorizeRequest,
                              completion: ((Result<String, Error>) -> Void)? = nil) {
        AMZNAuthorizationManager.shared().authorize(request) { (result, _, error) in
            if let accessToken = result?.token {
                self.authState = .authenticated
                completion?(.success(accessToken))
            } else {
                self.authState = .none
                let authError = error ?? AuthError()
                os_log(.error, "%@", "Failed to get token. error: \(authError)")
                completion?(.failure(authError))
            }
        }
    }
}

extension AmazonAuthService: SidewalkAuthProviding {

    /// Provides the Login with Amazon token to the Sidewalk Mobile SDK upon request.
    ///
    /// You should never cache the Login with Amazon token, instead prefer to pass the request directly to the Login with Amazon SDK.
    func getToken(completion: @escaping (Result<String, Error>) -> Void) {
        let request: AMZNAuthorizeRequest = AMZNAuthorizeRequest()
        request.interactiveStrategy = .never

        lwaAuthorize(request: request, completion: completion)
    }
}
