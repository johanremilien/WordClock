/**************************************************************************************************
**  Copyright (c) Kokleeko S.L. (https://github.com/kokleeko) and contributors.
**  All rights reserved.
**  Licensed under the MIT license. See LICENSE file in the project root for
**  details.
**  Author: Johan, Axel REMILIEN (https://github.com/johanremilien)
**************************************************************************************************/
#import <Foundation/NSNotification.h>
#import <StoreKit/StoreKit.h>
#import <UIKit/UIKit.h>

#import "DeviceAccess.h"

Q_LOGGING_CATEGORY(lc, "Device")

using namespace kokleeko::device;

@interface QIOSViewController
@end

@interface QIOSViewController (ViewController)
- (UIStatusBarStyle)preferredStatusBarStyle;
- (void)viewDidLoad;
@end

@implementation QIOSViewController (ViewController)
- (UIStatusBarStyle)preferredStatusBarStyle {
  return DeviceAccess::instance().isStatusBarHidden() ? UIStatusBarStyleLightContent
                                                      : UIStatusBarStyleDefault;
}
- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
  emit DeviceAccess::instance().orientationChanged();
}

- (void)viewDidLoad {
  UIDevice *device = [UIDevice currentDevice];
  [device setBatteryMonitoringEnabled:YES];
  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(receiveBatteryStateDidChangeNotification:)
             name:UIDeviceBatteryStateDidChangeNotification
           object:device];
  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(receiveBatteryLevelDidChangeNotification:)
             name:UIDeviceBatteryLevelDidChangeNotification
           object:device];
  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(receiveBrightnessDidChangeNotification:)
             name:UIScreenBrightnessDidChangeNotification
           object:device];
}

- (void)receiveBatteryStateDidChangeNotification:(NSNotification *)notification {
  auto batteryState = [[notification object] batteryState];
  bool isPlugged =
      (batteryState == UIDeviceBatteryStateCharging || batteryState == UIDeviceBatteryStateFull);
  DeviceAccess::instance().updateIsPlugged(isPlugged);
}

- (void)receiveBatteryLevelDidChangeNotification:(NSNotification *)notification {
  auto batteryLevel = [[notification object] batteryLevel];
  DeviceAccess::instance().updateBatteryLevel(batteryLevel);
}

- (void)receiveBrightnessDidChangeNotification:(NSNotification *)notification {
  auto brightness = [[notification object] brightness];
  DeviceAccess::instance().updateBrightness(brightness);
}
@end

void DeviceAccess::enableGuidedAccessSession(bool enable) {
  UIAccessibilityRequestGuidedAccessSession(enable, ^(BOOL didSucceed) {
    qCDebug(lc) << "Request guided access " << (didSucceed ? "succeed" : "failed");
    if (didSucceed) {
      m_isGuidedAccessEnabled = enable;
      isGuidedAccessEnabledChanged();
    }
  });
}

void DeviceAccess::setBrightness(float brightness) {
  qCDebug(lc) << "W brightness:" << brightness;
  m_settings.setValue("BatterySaving/battery", [UIScreen mainScreen].brightness = brightness);
  brightnessRequestedChanged();
}

void DeviceAccess::disableAutoLock(bool disable) {
  qCDebug(lc) << "W autoLock" << !disable;
  [UIApplication sharedApplication].idleTimerDisabled = disable;
  m_isAutoLockDisabled = [UIApplication sharedApplication].isIdleTimerDisabled;
  qCDebug(lc) << "R autoLock" << m_isAutoLockDisabled;
  if (m_isAutoLockDisabled) {
    if (m_isGuidedAccessRequested && !m_isGuidedAccessEnabled) enableGuidedAccessSession(true);
  } else if (m_isGuidedAccessEnabled) {
    enableGuidedAccessSession(false);
  }
}

void DeviceAccess::batterySaving() {
  if (!m_isAutoLockRequested && (m_isPlugged || m_batteryLevel > m_minimumBatteryLevel)) {
    if (!m_isAutoLockDisabled) {
      disableAutoLock(true);
    }
  } else if (m_isAutoLockDisabled) {
    disableAutoLock(false);
  }
}

void DeviceAccess::security() {
  if (m_isAutoLockDisabled) enableGuidedAccessSession(m_isGuidedAccessRequested);
}

void DeviceAccess::requestReview() {
  if (@available(iOS 14.0, *)) {
    auto windowScene = [[[UIApplication sharedApplication] keyWindow] windowScene];
    [SKStoreReviewController requestReviewInScene:windowScene];
  } else if (@available(iOS 10.3, *)) {
    [SKStoreReviewController requestReview];
  }
}
