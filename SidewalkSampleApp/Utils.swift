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

extension RegistrationDetail {
    var message: String {
        switch self {
        case .alreadyRegistered:
            return "Device already registered"
        case .registrationSucceeded:
            return "Device registered successfully"
        @unknown default:
            assertionFailure("Warning: Unhandled case in RegistrationDetail")
            return "Device registration succeeded"
        }
    }
}

struct AlertModel {
    let alertTitle: String
    let alertText: String
    let buttonText: String
    let buttonAction: (() -> Void)?

    init(alertTitle: String, alertText: String, buttonText: String, buttonAction: (() -> Void)? = nil) {
        self.alertTitle = alertTitle
        self.alertText = alertText
        self.buttonText = buttonText
        self.buttonAction = buttonAction
    }
}
