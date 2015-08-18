// Copyright 2014 Google Inc. All Rights Reserved.
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

#import "HGCViewController.h"
#import "HGCTextChannel.h"
#import <GoogleCast/GoogleCast.h>

static NSString *const kReceiverAppID = @"794B7BBF"; // Update to your app id
                                                     // to host your own receiver.

@interface HGCViewController () <GCKDeviceScannerListener,
                                 GCKDeviceManagerDelegate,
                                 GCKMediaControlChannelDelegate,
                                 UIActionSheetDelegate> {

}

@property(nonatomic, strong) GCKApplicationMetadata *applicationMetadata;
@property(nonatomic, strong) GCKDevice *selectedDevice;
@property(nonatomic, strong) HGCTextChannel *textChannel;
@property(nonatomic, strong) UIImage *btnImage;
@property(nonatomic, strong) UIImage *btnImageSelected;
@property(nonatomic, strong) IBOutlet UITextField *messageTextField;
@property(nonatomic, strong) GCKDeviceScanner* deviceScanner;
@property(nonatomic, strong) IBOutlet UIBarButtonItem *googleCastButton;
@property(nonatomic, strong) GCKDeviceManager* deviceManager;
@property(nonatomic, strong) GCKMediaInformation* mediaInformation;


@end

@implementation HGCViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  // Create cast button.
  self.btnImage = [UIImage imageNamed:@"icon-cast-identified.png"];
  self.btnImageSelected = [UIImage imageNamed:@"icon-cast-connected.png"];

  // Initially hide Cast button.
  self.navigationItem.rightBarButtonItems = @[];

  // [START device-scanner]
  // Establish filter criteria.
  GCKFilterCriteria *filterCriteria =
      [GCKFilterCriteria criteriaForAvailableApplicationWithID:kReceiverAppID];

  // Initialize device scanner.
  self.deviceScanner = [[GCKDeviceScanner alloc] initWithFilterCriteria:filterCriteria];
  [_deviceScanner addListener:self];
  [_deviceScanner startScan];
  // [END device-scanner]
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (IBAction)chooseDevice:(id)sender {
  // Choose device.
  if (self.selectedDevice == nil) {
    // [START showing-devices]
    //Device Selection List
    UIActionSheet *sheet =
    // [START_EXCLUDE]
        [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Connect to device", nil)
                                    delegate:self
                           cancelButtonTitle:nil
                      destructiveButtonTitle:nil
                           otherButtonTitles:nil];
    // [END_EXCLUDE]

    for (GCKDevice *device in _deviceScanner.devices) {
      [sheet addButtonWithTitle:device.friendlyName];
    }

    // [START_EXCLUDE silent]
    [sheet addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    sheet.cancelButtonIndex = sheet.numberOfButtons - 1;
    // [END_EXCLUDE]

    [sheet showInView:self.view];
    // [END showing-devices]
  } else {
    // Show already connected information.
    NSString *mediaTitle = [self.mediaInformation.metadata stringForKey:kGCKMetadataKeyTitle];

    UIActionSheet *sheet = [[UIActionSheet alloc] init];
    sheet.title = _selectedDevice.friendlyName;
    sheet.delegate = self;
    if (mediaTitle != nil) {
      [sheet addButtonWithTitle:mediaTitle];
    }
    [sheet addButtonWithTitle:@"Disconnect"];
    [sheet addButtonWithTitle:@"Cancel"];
    sheet.destructiveButtonIndex = (mediaTitle != nil ? 1 : 0);
    sheet.cancelButtonIndex = (mediaTitle != nil ? 2 : 1);

    [sheet showInView:self.view];
  }
}

- (void)connectToDevice {
  if (_selectedDevice == nil) {
    return;
  }

  // [START device-selection]
  GCKDevice *selectedDevice = // [START_EXCLUDE]
                              _selectedDevice;
                              // [END_EXCLUDE]

  NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
  self.deviceManager =
      [[GCKDeviceManager alloc] initWithDevice:selectedDevice
                             clientPackageName:[info objectForKey:@"CFBundleIdentifier"]];
  self.deviceManager.delegate = self;
  [_deviceManager connect];
  // [END device-selection]
}

- (void)deviceDisconnected {
  self.textChannel = nil;
  self.deviceManager = nil;
  self.selectedDevice = nil;
  NSLog(@"Device disconnected");
}

- (void)updateButtonStates {
  if (_deviceScanner && _deviceScanner.devices.count > 0) {
    // Show the Cast button.
    self.navigationItem.rightBarButtonItems = @[_googleCastButton];
    if (_deviceManager && _deviceManager.connectionState == GCKConnectionStateConnected) {
      // Show the Cast button in the enabled state.
      [_googleCastButton setTintColor:[UIColor blueColor]];
    } else {
      // Show the Cast button in the disabled state.
      [_googleCastButton setTintColor:[UIColor grayColor]];
    }
  } else {
    //Don't show cast button.
    self.navigationItem.rightBarButtonItems = @[];
  }
}

- (IBAction)sendText:(id)sender {
  NSLog(@"sending text %@", [_messageTextField text]);

  // Show alert if not connected.
  if (!_deviceManager || !(_deviceManager.connectionState == GCKConnectionStateConnected)) {
    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"Not Connected"
                                            message:@"Please connect to Cast device"
                                     preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alert animated:YES completion:nil];
    return;
  }
  
  // [START custom-channel-2]
  HGCTextChannel *textChannel = // [START_EXCXLUDE]
                                _textChannel;
                                // [END_EXCLUDE]
  NSString *textMessage = // [START_EXCXLUDE]
                                [_messageTextField text];
                                // [END_EXCLUDE]
  
  [textChannel sendTextMessage:textMessage];
  // [END custom-channel-2]
}

// [START device-scanner-listener]
#pragma mark - GCKDeviceScannerListener
- (void)deviceDidComeOnline:(GCKDevice *)device {
  NSLog(@"device found!! %@", device.friendlyName);
  [self updateButtonStates];
}

- (void)deviceDidGoOffline:(GCKDevice *)device {
  [self updateButtonStates];
}
// [END device-scanner-listener]

#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (_selectedDevice == nil) {
    if (buttonIndex < self.deviceScanner.devices.count) {
      self.selectedDevice = _deviceScanner.devices[buttonIndex];
      NSLog(@"Selecting device:%@", _selectedDevice.friendlyName);
      [self connectToDevice];
    }
  } else {
    if (buttonIndex == 0) {  //Disconnect button
      NSLog(@"Disconnecting device:%@", self.selectedDevice.friendlyName);
      // New way of doing things: We're not going to stop the applicaton. We're just going
      // to leave it.
      [_deviceManager leaveApplication];
      [_deviceManager disconnect];

      [self deviceDisconnected];
      [self updateButtonStates];
    } else if (buttonIndex == 0) {
      // Join the existing session.

    }
  }
}

#pragma mark - GCKDeviceManagerDelegate

// [START launch-application]
- (void)deviceManagerDidConnect:(GCKDeviceManager *)deviceManager {
  NSLog(@"connected to %@", _selectedDevice.friendlyName);

  [self updateButtonStates];

  // Launch application after getting connected.
  [_deviceManager launchApplication:kReceiverAppID];
}
// [END launch-application]

- (void)deviceManager:(GCKDeviceManager *)deviceManager
    didConnectToCastApplication:(GCKApplicationMetadata *)applicationMetadata
                      sessionID:(NSString *)sessionID
            launchedApplication:(BOOL)launchedApplication {
  if (launchedApplication) {
    NSLog(@"application has launched");
  }
  else{
    NSLog(@"application has not launched");
  }

  self.textChannel =
      [[HGCTextChannel alloc] initWithNamespace:@"urn:x-cast:com.google.cast.sample.helloworld"];
  [_deviceManager addChannel:_textChannel];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager
    didFailToConnectToApplicationWithError:(NSError *)error {
  [self showError:error];

  [self deviceDisconnected];
  [self updateButtonStates];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager
    didFailToConnectWithError:(GCKError *)error {
  [self showError:error];

  [self deviceDisconnected];
  [self updateButtonStates];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager
    didDisconnectWithError:(GCKError *)error {
  NSLog(@"Received notification that device disconnected");

  if (error != nil) {
    [self showError:error];
  }

  [self deviceDisconnected];
  [self updateButtonStates];

}

- (void)deviceManager:(GCKDeviceManager *)deviceManager
    didReceiveStatusForApplication:(GCKApplicationMetadata *)applicationMetadata {
  self.applicationMetadata = applicationMetadata;

  NSLog(@"Received device status: %@", applicationMetadata);
}

#pragma mark - misc
- (void)showError:(NSError *)error {
  UIAlertController *alert =
  [UIAlertController alertControllerWithTitle:@"Error"
                                      message:error.description
                               preferredStyle:UIAlertControllerStyleAlert];
  [self presentViewController:alert animated:YES completion:nil];
}

@end
