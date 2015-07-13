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

#import <UIKit/UIKit.h>
#import <GoogleCast/GoogleCast.h>

@interface HTGCViewController : UIViewController<GCKDeviceScannerListener,
                                                 GCKDeviceManagerDelegate,
                                                 GCKMediaControlChannelDelegate,
                                                 UIActionSheetDelegate>

@property(nonatomic, strong) GCKDeviceScanner* deviceScanner;
@property(nonatomic, strong) UIButton* chromecastButton;
@property(nonatomic, strong) GCKDeviceManager* deviceManager;
@property(nonatomic, readonly) GCKMediaInformation* mediaInformation;

@end