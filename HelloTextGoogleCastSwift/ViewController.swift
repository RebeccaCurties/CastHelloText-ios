// Copyright 2015 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit

@objc(HGCViewController)
class ViewController: UIViewController, GCKDeviceScannerListener, GCKDeviceManagerDelegate,
    GCKMediaControlChannelDelegate, UIActionSheetDelegate {
  fileprivate let kCancelTitle = "Cancel"
  fileprivate let kDisconnectTitle = "Disconnect"
  // Publicly available receiver to demonstrate sending messages - replace this with your
  // own custom app ID.
  fileprivate let kReceiverAppID = "794B7BBF"
  fileprivate lazy var btnImage:UIImage = {
    return UIImage(named: "icon-cast-identified.png")!
  }()
  fileprivate lazy var btnImageselected:UIImage = {
    return UIImage(named: "icon-cast-connected.png")!
  }()
  fileprivate lazy var textChannel:TextChannel = {
    return TextChannel(namespace: "urn:x-cast:com.google.cast.sample.helloworld")
  }()
  fileprivate var deviceScanner:GCKDeviceScanner?
  fileprivate var deviceManager:GCKDeviceManager?
  fileprivate var mediaInformation:GCKMediaInformation?
  fileprivate var selectedDevice:GCKDevice?
  @IBOutlet var messageTextField: UITextField!
  @IBOutlet var googleCastButton: UIBarButtonItem!

  override func viewDidLoad() {
    super.viewDidLoad()

    // Initially hide the Cast button.
    navigationItem.rightBarButtonItems = []

    // [START device-scanner]
    // Establish filter criteria.
    let filterCriteria = GCKFilterCriteria(forAvailableApplicationWithID: kReceiverAppID)

    // Initialize device scanner.
    deviceScanner = GCKDeviceScanner(filterCriteria: filterCriteria)
    if let deviceScanner = deviceScanner {
      deviceScanner.add(self)
      deviceScanner.startScan()
      deviceScanner.passiveScan = true
    }
    // [END device-scanner]
  }

  func updateButtonStates() {
    if (deviceScanner!.devices.count > 0) {
      // Show the Cast button.
      navigationItem.rightBarButtonItems = [googleCastButton!]
      if (deviceManager != nil && deviceManager?.connectionState == GCKConnectionState.connected) {
        // Show the Cast button in the enabled state.
        googleCastButton!.tintColor = UIColor.blue
      } else {
        // Show the Cast button in the disabled state.
        googleCastButton!.tintColor = UIColor.gray
      }
    } else{
      // Don't show Cast button.
      navigationItem.rightBarButtonItems = []
    }
  }

  func connectToDevice() {
    if (selectedDevice == nil) {
      return
    }
    // [START device-selection]
    let identifier = Bundle.main.bundleIdentifier
    deviceManager = GCKDeviceManager(device: selectedDevice, clientPackageName: identifier)
    deviceManager!.delegate = self
    deviceManager!.connect()
    // [END device-selection]
  }

  func deviceDisconnected() {
    selectedDevice = nil
    deviceManager = nil
  }

  func showError(_ error: NSError) {
    let alert = UIAlertController(title: "Error", message: error.description,
                         preferredStyle: UIAlertControllerStyle.alert);
    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
    self.present(alert, animated: true, completion: nil)
  }

  func chooseDevice(_ sender:AnyObject) {
    if (selectedDevice == nil) {
      // [START showing-devices]
      let sheet : UIActionSheet = // [START_EXCLUDE]
      UIActionSheet(title: "Connect to Device",
        delegate: self,
        cancelButtonTitle: nil,
        destructiveButtonTitle: nil)
      // [END_EXCLUDE]
      if let deviceScanner = deviceScanner {
        deviceScanner.passiveScan = false
        for device in deviceScanner.devices  {
          sheet.addButton(withTitle: (device as AnyObject).friendlyName)
        }
      }
      // [START_EXCLUDE]
      // Add the cancel button at the end so the indices of the titles map to the array indices.
      sheet.addButton(withTitle: kCancelTitle);
      sheet.cancelButtonIndex = sheet.numberOfButtons - 1;
      // [END_EXCLUDE]

      sheet.show(in: self.view)
      // [END showing-devices]

    } else {
      let friendlyName = "Casting to \(selectedDevice!.friendlyName)";

      let sheet : UIActionSheet = UIActionSheet(title: friendlyName,
          delegate: self, cancelButtonTitle: nil,
          destructiveButtonTitle: nil);
      var buttonIndex = 0;

      if let info = mediaInformation {
        sheet.addButton(withTitle: (info.metadata.object(forKey: kGCKMetadataKeyTitle) as! String));
        buttonIndex += 1;
      }

      // Offer disconnect option.
      sheet.addButton(withTitle: kDisconnectTitle);
      sheet.addButton(withTitle: kCancelTitle);
      sheet.destructiveButtonIndex = buttonIndex+1;
      sheet.cancelButtonIndex = buttonIndex;

      sheet.show(in: self.view);
    }
  }


  @IBAction func sendText(_ sender: AnyObject?) {
    if let messageField = self.messageTextField {
      print("Sending text \(messageField.text!)")
      if (!(self.deviceManager?.connectionState == GCKConnectionState.connected)) {
        let alert = UIAlertController(title: "Not Connected",
          message: "Please connect to a Cast device.",
          preferredStyle: UIAlertControllerStyle.alert);
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        return;
      }
      // [START custom-channel-2]
      let textChannel = // [START_EXCLUDE]
        self.textChannel
        // [END_EXCLUDE]
      let textMessage = // [START_EXCLUDE silent]
        messageField.text
      // [END_EXCLUDE]
      // a String
      
      textChannel.sendTextMessage(textMessage)
      // [END custom-channel-2]
    }
  }

  // [START device-scanner-listener]
  // MARK: GCKDeviceScannerListener

  func deviceDidComeOnline(_ device: GCKDevice!) {
    print("Device found: \(device.friendlyName)");
    updateButtonStates();
  }

  func deviceDidGoOffline(_ device: GCKDevice!) {
    print("Device went away: \(device.friendlyName)");
    updateButtonStates();
  }
  // [END device-scanner-listener]

  // MARK: UIActionSheetDelegate
  func actionSheet(_ actionSheet: UIActionSheet, clickedButtonAt buttonIndex: Int) {
    if let deviceScanner = deviceScanner {
      deviceScanner.passiveScan = true
      if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
      } else if (selectedDevice == nil) {
        if (buttonIndex < deviceScanner.devices.count) {
          selectedDevice = deviceScanner.devices[buttonIndex] as? GCKDevice;
          print("Selected device: \(selectedDevice!.friendlyName)");
          connectToDevice();
        }
      } else if (actionSheet.buttonTitle(at: buttonIndex) == kDisconnectTitle) {
        // Disconnect button.
        deviceManager!.leaveApplication();
        deviceManager!.disconnect();
        deviceDisconnected();
        updateButtonStates();
      }
    }
  }

  // [START launch-application]
  // MARK: GCKDeviceManagerDelegate
  func deviceManagerDidConnect(_ deviceManager: GCKDeviceManager!) {
    print("Connected.");
    
    // [START_EXCLUDE silent]
    updateButtonStates();
    // [END_EXCLUDE]
    deviceManager.launchApplication(kReceiverAppID);
  }
  // [END launch-application]

  func deviceManager(_ deviceManager: GCKDeviceManager!,
    didConnectToCastApplication
    applicationMetadata: GCKApplicationMetadata!,
    sessionID: String!,
    launchedApplication: Bool) {
      print("Application has launched.");
      deviceManager.add(self.textChannel)
  }

  func deviceManager(_ deviceManager: GCKDeviceManager!,
    didFailToConnectToApplicationWithError error: Error!) {
      print("Received notification that device failed to connect to application.");

      showError(error! as NSError);
      deviceDisconnected();
      updateButtonStates();
  }

  func deviceManager(_ deviceManager: GCKDeviceManager!,
    didFailToConnectWithError error: Error!) {
      print("Received notification that device failed to connect.");

      showError(error! as NSError);
      deviceDisconnected();
      updateButtonStates();
  }

  func deviceManager(_ deviceManager: GCKDeviceManager!,
    didDisconnectWithError error: Error!) {
      print("Received notification that device disconnected.");

      if (error != nil) {
        showError(error! as NSError)
      }

      deviceDisconnected();
      updateButtonStates();
  }

}
