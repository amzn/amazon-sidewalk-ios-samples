# amazon-sidewalk-ios-samples

## Building the Sidewalk Sample App
1. Please use the latest version of Xcode and Cocoapods.
2. Run `pod install` and open the SidewalkSampleApp.xcworkspace project file with Xcode.
3. Highlight SidewalkSampleApp, select Signing & Capabilities, and use your team (or create a free personal one) & any available unique bundle identifier. You should probably follow your team's naming convention.
4. Add Login with Amazon dependency.
    a. Follow the Register for Login with Amazon flow documented on [developer.amazon.com](https://developer.amazon.com/docs/login-with-amazon/register-ios.html) to obtain an API Key for your bundle ID and security profile.
    b. Download the Login with Amazon SDK from [developer.amazon.com](https://developer.amazon.com/docs/apps-and-games/sdk-downloads.html), and place the framework file under `<project root>/Frameworks/`, so that the file path is `<project root>/Frameworks/LoginWithAmazon.framework`.
    c. In Xcode, open Info.plist in the SidewalkSampleApp. Replace the APIKey entry with the key you obtained in step 4.
5. Add OpenSSL dependency.
    a. Use your favorite way of importing [OpenSSL](https://www.openssl.org/).
6. Run the app on an iPhone. The simulator will not have bluetooth capabilities.

## Testing with the Sidewalk Sample App
1. The Sidewalk Sample App provides scanning, registration, deregistration, and secure connect capabilities.
2. Scanning will start automatically.
3. Click on Menu -> Login to authenticate, use your Amazon test account. NOTE: The Amazon account is required to be linked with a Ring account for Sidewalk functionalities.
4. Long press a found device in the UNREGISTERED DEVICES section, and click register to go through the Sidewalk registration process.
5. A spinner indicates the registration progress. There will be a pop up with an error or success once the process completes. 
6. Long press a found device in any section, and click Secure Connect to initiate a secure connection. Upon success, this will take you to the secure connection page. You can also register with a secure connection (preferred if you already have one), which is showcased here.
7. Menu -> Deregister allows you to deregister a device. Input the Sidewalk ID which was returned after registration. Sidewalk ID is also the endpoint ID of registered devices.
8. Logs may be viewed in Xcode Debugger as well as the Device Console. In Xcode, go to Window → Devices and Simulators → Click on your phone in right panel → Open Console. Search for "process:SidewalkSampleApp".

## Security
See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License
This library is licensed under the MIT-0 License. See the [LICENSE](LICENSE) file.

