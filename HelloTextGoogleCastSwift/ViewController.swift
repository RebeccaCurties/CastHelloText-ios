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
  private let kCancelTitle = "Cancel"
  private let kDisconnectTitle = "Disconnect"
  // Publicly available receiver to demonstrate sending messages - replace this with your
  // own custom app ID.
  private let kReceiverAppID = "794B7BBF"
  private lazy var btnImage:UIImage = {
    return UIImage(named: "icon-cast-identified.png")!
  }()
  private lazy var btnImageselected:UIImage = {
    return UIImage(named: "icon-cast-connected.png")!
  }()
  private lazy var chromecastButton:UIButton = {
    //Create cast button
    var button:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
    button.addTarget(self, action: "chooseDevice:", forControlEvents: UIControlEvents.TouchUpInside)
    button.frame = CGRectMake(0, 0, self.btnImage.size.width, self.btnImage.size.height)
    button.hidden = true;
    return button;
  }()
  private lazy var textChannel:TextChannel = {
    return TextChannel(namespace: "urn:x-cast:com.google.cast.sample.helloworld")
  }()
  private var deviceScanner:GCKDeviceScanner?
  private var deviceManager:GCKDeviceManager?
  private var mediaInformation:GCKMediaInformation?
  private var selectedDevice:GCKDevice?
  @IBOutlet var messageTextField: UITextField!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.

    self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView:self.chromecastButton)

    // [START device-scanner]
    // Establish filter criteria
    let filterCriteria = GCKFilterCriteria(forAvailableApplicationWithID: kReceiverAppID)

    //initialize device scanner
    deviceScanner = GCKDeviceScanner(filterCriteria: filterCriteria)
    if let deviceScanner = deviceScanner {
      deviceScanner.addListener(self)
      deviceScanner.startScan()
    }
    // [END device-scanner]
  }

  func updateButtonStates() {
    if (deviceScanner != nil && deviceScanner!.devices.count == 0) {
      //Hide the cast button
      chromecastButton.hidden = true;
    } else {
      //Show cast button
      chromecastButton.hidden = false;

      if self.deviceManager?.applicationConnectionState == GCKConnectionState.Connected {
        chromecastButton.setImage(btnImageselected, forState: UIControlState.Normal);
      } else {
        chromecastButton.setImage(btnImage, forState: UIControlState.Normal);
      }
    }
  }

  func connectToDevice() {
    if (selectedDevice == nil) {
      return
    }
    // [START device-selection]
    let identifier = NSBundle.mainBundle().infoDictionary?["CFBundleIdentifier"] as! String
    deviceManager = GCKDeviceManager(device: selectedDevice, clientPackageName: identifier)
    deviceManager!.delegate = self
    deviceManager!.connect()
    // [END device-selection]
  }

  func deviceDisconnected() {
    selectedDevice = nil
    deviceManager = nil
  }

  func showError(error: NSError) {
    var alert = UIAlertController(title: "Error", message: error.description, preferredStyle: UIAlertControllerStyle.Alert);
    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
    self.presentViewController(alert, animated: true, completion: nil)
  }

  func chooseDevice(sender:AnyObject) {
    if (selectedDevice == nil) {
      // [START showing-devices]
      var sheet : UIActionSheet = // [START_EXCLUDE]
        UIActionSheet(title: "Connect to Device",
        delegate: self,
        cancelButtonTitle: nil,
        destructiveButtonTitle: nil)
      // [END_EXCLUDE]

      if let deviceScanner = deviceScanner {
        for device in deviceScanner.devices  {
          sheet.addButtonWithTitle(device.friendlyName)
        }
      }

      // [START_EXCLUDE]
      // Add the cancel button at the end so that indexes of the titles map to the array index.
      sheet.addButtonWithTitle(kCancelTitle);
      sheet.cancelButtonIndex = sheet.numberOfButtons - 1;
      // [END_EXCLUDE]

      sheet.showInView(chromecastButton)
      // [END showing-devices]

    } else {
      let friendlyName = "Casting to \(selectedDevice!.friendlyName)";

      var sheet : UIActionSheet = UIActionSheet(title: friendlyName,
          delegate: self, cancelButtonTitle: nil,
          destructiveButtonTitle: nil);
      var buttonIndex = 0;

      if let info = mediaInformation {
        sheet.addButtonWithTitle(info.metadata.objectForKey(kGCKMetadataKeyTitle) as! String);
        buttonIndex++;
      }

      // Offer disconnect option.
      sheet.addButtonWithTitle(kDisconnectTitle);
      sheet.addButtonWithTitle(kCancelTitle);
      sheet.destructiveButtonIndex = buttonIndex++;
      sheet.cancelButtonIndex = buttonIndex;

      sheet.showInView(chromecastButton);
    }
  }


  @IBAction func sendText(sender: AnyObject?) {
    if let messageField = self.messageTextField {
      println("Sending text \(messageField.text)")
      if (!(self.deviceManager?.applicationConnectionState == GCKConnectionState.Connected)) {
        var alert = UIAlertController(title: "Not Connected",
          message: "Please connect to a Cast device.",
          preferredStyle: UIAlertControllerStyle.Alert);
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
        return;
      }
      // [START custom-channel-2]
      let textChannel = // [START_EXCLUDE]
        self.textChannel
        // [END_EXCLUDE]
      // a String
      let textMessage = // [START_EXCLUDE]
        messageField.text
      // [END_EXCLUDE]
      
      textChannel.sendTextMessage(textMessage)
      // [END custom-channel-2]
    }
  }

  // [START device-scanner-listener]
  // MARK: GCKDeviceScannerListener

  func deviceDidComeOnline(device: GCKDevice!) {
    println("Device found: \(device.friendlyName)");
    updateButtonStates();
  }

  func deviceDidGoOffline(device: GCKDevice!) {
    println("Device went away: \(device.friendlyName)");
    updateButtonStates();
  }
  // [END device-scanner-listener]

  // MARK: UIActionSheetDelegate
  func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
      return;
    } else if (selectedDevice == nil) {
      if let deviceScanner = deviceScanner {
        if (buttonIndex < deviceScanner.devices.count) {
          selectedDevice = deviceScanner.devices[buttonIndex] as? GCKDevice;
          println("Selected device: \(selectedDevice!.friendlyName)");
          connectToDevice();
        }
      }
    } else if (actionSheet.buttonTitleAtIndex(buttonIndex) == kDisconnectTitle) {
      // Disconnect button.
      deviceManager!.leaveApplication();
      deviceManager!.disconnect();
      deviceDisconnected();
      updateButtonStates();
    }
  }

  // [START launch-application]
  // MARK: GCKDeviceManagerDelegate
  func deviceManagerDidConnect(deviceManager: GCKDeviceManager!) {
    println("Connected.");
    
    // [START_EXCLUDE silent]
    updateButtonStates();
    // [END_EXCLUDE silent]
    deviceManager.launchApplication(kReceiverAppID);
  }
  // [END launch-application]

  func deviceManager(deviceManager: GCKDeviceManager!,
    didConnectToCastApplication
    applicationMetadata: GCKApplicationMetadata!,
    sessionID: String!,
    launchedApplication: Bool) {
      println("Application has launched.");
      deviceManager.addChannel(self.textChannel)
  }

  func deviceManager(deviceManager: GCKDeviceManager!,
    didFailToConnectToApplicationWithError error: NSError!) {
      println("Received notification that device failed to connect to application.");

      showError(error);
      deviceDisconnected();
      updateButtonStates();
  }

  func deviceManager(deviceManager: GCKDeviceManager!,
    didFailToConnectWithError error: NSError!) {
      println("Received notification that device failed to connect.");

      showError(error);
      deviceDisconnected();
      updateButtonStates();
  }

  func deviceManager(deviceManager: GCKDeviceManager!,
    didDisconnectWithError error: NSError!) {
      println("Received notification that device disconnected.");

      if (error != nil) {
        showError(error)
      }

      deviceDisconnected();
      updateButtonStates();
  }

}