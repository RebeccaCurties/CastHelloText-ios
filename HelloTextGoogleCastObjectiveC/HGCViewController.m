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

static NSString *const kReceiverAppID = @"794B7BBF"; //Update to your app id to host your own receiver

@interface HGCViewController () {
  UIImage *_btnImage;
  UIImage *_btnImageSelected;
  IBOutlet UITextField *messageTextField;
}

@property GCKApplicationMetadata *applicationMetadata;
@property GCKDevice *selectedDevice;
@property HGCTextChannel *textChannel;

@end

@implementation HGCViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  //Create cast button
  _btnImage = [UIImage imageNamed:@"icon-cast-identified.png"];
  _btnImageSelected = [UIImage imageNamed:@"icon-cast-connected.png"];

  _chromecastButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  [_chromecastButton addTarget:self
                        action:@selector(chooseDevice:)
              forControlEvents:UIControlEventTouchDown];
  _chromecastButton.frame = CGRectMake(0, 0, _btnImage.size.width, _btnImage.size.height);
  [_chromecastButton setImage:nil forState:UIControlStateNormal];
  _chromecastButton.hidden = YES;

  //add cast button to navigation bar
  self.navigationItem.rightBarButtonItem =
      [[UIBarButtonItem alloc] initWithCustomView:_chromecastButton];

  // [START device-scanner]
  //Establish filter criteria
  GCKFilterCriteria *filterCriteria = [GCKFilterCriteria criteriaForAvailableApplicationWithID:kReceiverAppID];

  //Initialize device scanner
  self.deviceScanner = [[GCKDeviceScanner alloc] initWithFilterCriteria:filterCriteria];
  [self.deviceScanner addListener:self];
  [self.deviceScanner startScan];
  // [END device-scanner]
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)chooseDevice:(id)sender {
  //Choose device
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
    
    for (GCKDevice *device in self.deviceScanner.devices) {
      [sheet addButtonWithTitle:device.friendlyName];
    }

    // [START_EXCLUDE silent]
    [sheet addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    sheet.cancelButtonIndex = sheet.numberOfButtons - 1;
    // [END_EXCLUDE]
    
    [sheet showInView:_chromecastButton];
    // [END showing-devices]
  } else {
    //Already connected information
    NSString *mediaTitle = [self.mediaInformation.metadata stringForKey:kGCKMetadataKeyTitle];

    UIActionSheet *sheet = [[UIActionSheet alloc] init];
    sheet.title = self.selectedDevice.friendlyName;
    sheet.delegate = self;
    if (mediaTitle != nil) {
      [sheet addButtonWithTitle:mediaTitle];
    }
    [sheet addButtonWithTitle:@"Disconnect"];
    [sheet addButtonWithTitle:@"Cancel"];
    sheet.destructiveButtonIndex = (mediaTitle != nil ? 1 : 0);
    sheet.cancelButtonIndex = (mediaTitle != nil ? 2 : 1);

    [sheet showInView:_chromecastButton];
  }
}

- (void)connectToDevice {
  if (self.selectedDevice == nil)
    return;
  
  // [START device-selection]
  GCKDevice *selectedDevice = // [START_EXCLUDE]
                              self.selectedDevice;
                              // [END_EXCLUDE]
  
  NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
  self.deviceManager =
      [[GCKDeviceManager alloc] initWithDevice:selectedDevice
                             clientPackageName:[info objectForKey:@"CFBundleIdentifier"]];
  self.deviceManager.delegate = self;
  [self.deviceManager connect];
  // [END device-selection]
}

- (void)deviceDisconnected {
  self.textChannel = nil;
  self.deviceManager = nil;
  self.selectedDevice = nil;
  NSLog(@"Device disconnected");
}

- (void)updateButtonStates {
  if (self.deviceScanner.devices.count == 0) {
    //Hide the cast button
    [_chromecastButton setImage:_btnImage forState:UIControlStateNormal];
    _chromecastButton.hidden = YES;
  } else {
    if (self.deviceManager && self.deviceManager.connectionState == GCKConnectionStateConnected) {
      //Enabled state for cast button
      [_chromecastButton setImage:_btnImageSelected forState:UIControlStateNormal];
      [_chromecastButton setTintColor:[UIColor blueColor]];
      _chromecastButton.hidden = NO;
    } else {
      //Disabled state for cast button
      [_chromecastButton setImage:_btnImage forState:UIControlStateNormal];
      [_chromecastButton setTintColor:[UIColor grayColor]];
      _chromecastButton.hidden = NO;
    }
  }

}
- (IBAction)sendText:(id)sender {
  NSLog(@"sending text %@", [messageTextField text]);

  //Show alert if not connected
  if (!self.deviceManager || !(self.deviceManager.connectionState == GCKConnectionStateConnected)) {
    UIAlertView *alert =
        [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Not Connected", nil)
                                   message:NSLocalizedString(@"Please connect to Cast device", nil)
                                  delegate:nil
                         cancelButtonTitle:NSLocalizedString(@"OK", nil)
                         otherButtonTitles:nil];
    [alert show];
    return;
  }
  
  // [START custom-channel-2]
  HGCTextChannel *textChannel = // [START_EXCXLUDE]
                                self.textChannel;
                                // [END_EXCLUDE]
  NSString *textMessage = // [START_EXCXLUDE]
                                [messageTextField text];
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
  if (self.selectedDevice == nil) {
    if (buttonIndex < self.deviceScanner.devices.count) {
      self.selectedDevice = self.deviceScanner.devices[buttonIndex];
      NSLog(@"Selecting device:%@", self.selectedDevice.friendlyName);
      [self connectToDevice];
    }
  } else {
    if (buttonIndex == 0) {  //Disconnect button
      NSLog(@"Disconnecting device:%@", self.selectedDevice.friendlyName);
      // New way of doing things: We're not going to stop the applicaton. We're just going
      // to leave it.
      [self.deviceManager leaveApplication];
      // If you want to force application to stop, uncomment below
      //[self.deviceManager stopApplicationWithSessionID:self.applicationMetadata.sessionID];
      [self.deviceManager disconnect];

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
  NSLog(@"connected!!");

  [self updateButtonStates];

  //launch application after getting connectted
  [self.deviceManager launchApplication:kReceiverAppID];
}
// [END launch-application]

- (void)deviceManager:(GCKDeviceManager *)deviceManager
    didConnectToCastApplication:(GCKApplicationMetadata *)applicationMetadata
                      sessionID:(NSString *)sessionID
            launchedApplication:(BOOL)launchedApplication {
  if(launchedApplication){
    NSLog(@"application has launched");
  }
  else{
    NSLog(@"application has not launched");
  }

  self.textChannel =
      [[HGCTextChannel alloc] initWithNamespace:@"urn:x-cast:com.google.cast.sample.helloworld"];
  [self.deviceManager addChannel:self.textChannel];
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
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                  message:NSLocalizedString(error.description, nil)
                                                 delegate:nil
                                        cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                        otherButtonTitles:nil];
  [alert show];
}

@end
