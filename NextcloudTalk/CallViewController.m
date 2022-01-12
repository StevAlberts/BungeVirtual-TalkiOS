/**
 * @copyright Copyright (c) 2020 Ivan Sein <ivan@nextcloud.com>
 *
 * @author Ivan Sein <ivan@nextcloud.com>
 *
 * @license GNU GPL version 3 or any later version
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#import "CallViewController.h"

#import <WebRTC/RTCCameraVideoCapturer.h>
#import <WebRTC/RTCMediaStream.h>
#import <WebRTC/RTCEAGLVideoView.h>
#import <WebRTC/RTCVideoTrack.h>

#import "ARDCaptureController.h"
#import "DBImageColorPicker.h"
#import "PulsingHaloLayer.h"
#import "UIImageView+AFNetworking.h"
#import "UIView+Toast.h"

#import "CallKitManager.h"
#import "CallParticipantViewCell.h"
#import "NBMPeersFlowLayout.h"
#import "NCAPIController.h"
#import "NCAudioController.h"
#import "NCCallController.h"
#import "NCDatabaseManager.h"
#import "NCImageSessionManager.h"
#import "NCRoomsManager.h"
#import "NCSettingsController.h"
#import "NCSignalingMessage.h"
#import "NCUtils.h"

#import "NCNavigationController.h"
#import "NextcloudTalk-Swift.h"

typedef NS_ENUM(NSInteger, CallState) {
    CallStateJoining,
    CallStateWaitingParticipants,
    CallStateReconnecting,
    CallStateInCall
};

@interface CallViewController () <NCCallControllerDelegate, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, RTCVideoViewDelegate, CallParticipantViewCellDelegate, UIGestureRecognizerDelegate>
{
    CallState _callState;
    NSMutableArray *_peersInCall;
    NSMutableDictionary *_videoRenderersDict;
    NSMutableDictionary *_screenRenderersDict;
    NCCallController *_callController;
    NCChatViewController *_chatViewController;
    UINavigationController *_chatNavigationController;
    ARDCaptureController *_captureController;
    UIView <RTCVideoRenderer> *_screenView;
    CGSize _screensharingSize;
    UITapGestureRecognizer *_tapGestureForDetailedView;
    NSTimer *_detailedViewTimer;
    NSString *_displayName;
    BOOL _isAudioOnly;
    BOOL _isDetailedViewVisible;
    BOOL _userDisabledVideo;
    BOOL _videoCallUpgrade;
    BOOL _hangingUp;
    BOOL _pushToTalkActive;
    BOOL _speakRequest;
    BOOL _interveneRequest;
    BOOL _raisedHand;
    BOOL _approvedSpeak;
    BOOL _approvedIntervene;
    BOOL _isRequest;
//    BOOL _requestedSpeak;
//    BOOL _requestedIntervene;

    
    NCKActivity * _speakActivity;
    NCKActivity * _interveneActivity;
    
    NCVote * _votePoll;

    PulsingHaloLayer *_halo;
    PulsingHaloLayer *_haloPushToTalk;
    UIImpactFeedbackGenerator *_buttonFeedbackGenerator;
    CGPoint _localVideoDragStartingPosition;
    CGPoint _localVideoOriginPosition;
}

@property (nonatomic, strong) TalkAccount *account;

@property (nonatomic, strong) IBOutlet UIView *buttonsContainerView;
@property (nonatomic, strong) IBOutlet UIButton *audioMuteButton;
@property (nonatomic, strong) IBOutlet UIButton *speakerButton;
@property (nonatomic, strong) IBOutlet UIButton *videoDisableButton;
@property (nonatomic, strong) IBOutlet UIButton *switchCameraButton;
@property (nonatomic, strong) IBOutlet UIButton *hangUpButton;
@property (nonatomic, strong) IBOutlet UIButton *chatButton;
@property (nonatomic, strong) IBOutlet UIButton *videoCallButton;
@property (nonatomic, strong) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) IBOutlet UICollectionViewFlowLayout *flowLayout;

@property (nonatomic, strong) IBOutlet UIView *requestContainerView;
@property (nonatomic, strong) IBOutlet UIView *raiseHandContainerView;

@property (nonatomic, strong) IBOutlet UIButton *raiseHandButton;
@property (nonatomic, strong) IBOutlet UIButton *speakRequestButton;
@property (nonatomic, strong) IBOutlet UIButton *interveneRequestButton;

@property (nonatomic, strong) IBOutlet UIButton *timerButton;

@property (nonatomic, strong) NSTimer *listenerTimer;

@property (nonatomic, strong) IBOutlet UIButton *voteButton;

@end

@implementation CallViewController

@synthesize delegate = _delegate;

- (instancetype)initCallInRoom:(NCRoom *)room asUser:(NSString *)displayName audioOnly:(BOOL)audioOnly
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.modalPresentationStyle = UIModalPresentationFullScreen;
    
    _room = room;
    _displayName = displayName;
    _isAudioOnly = audioOnly;
    _peersInCall = [[NSMutableArray alloc] init];
    _videoRenderersDict = [[NSMutableDictionary alloc] init];
    _screenRenderersDict = [[NSMutableDictionary alloc] init];
    _buttonFeedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:(UIImpactFeedbackStyleLight)];
    
    // init account
    _account = [[NCDatabaseManager sharedInstance] activeAccount];
    
    // Use image downloader without cache so I can get 200 or 201 from the avatar requests.
    [AvatarBackgroundImageView setSharedImageDownloader:[[NCAPIController sharedInstance] imageDownloaderNoCache]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didJoinRoom:) name:NCRoomsManagerDidJoinRoomNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(providerDidEndCall:) name:CallKitManagerDidEndCallNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(providerDidChangeAudioMute:) name:CallKitManagerDidChangeAudioMuteNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(providerWantsToUpgradeToVideoCall:) name:CallKitManagerWantsToUpgradeToVideoCall object:nil];
    
    return self;
}

- (void)startCallWithSessionId:(NSString *)sessionId
{
    _callController = [[NCCallController alloc] initWithDelegate:self inRoom:_room forAudioOnlyCall:_isAudioOnly withSessionId:sessionId];
    _callController.userDisplayName = _displayName;
    _callController.disableVideoAtStart = _videoDisabledAtStart;
    
    [_callController startCall];
    
    // handle talk controls
    [self handleTalkControls];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setCallState:CallStateJoining];
    
    _tapGestureForDetailedView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showDetailedViewWithTimer)];
    [_tapGestureForDetailedView setNumberOfTapsRequired:1];
    
    
    UILongPressGestureRecognizer *pushToTalkRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handlePushToTalk:)];
    pushToTalkRecognizer.delegate = self;
    [self.audioMuteButton addGestureRecognizer:pushToTalkRecognizer];
    
    [_screensharingView setHidden:YES];
    
    [self.audioMuteButton.layer setCornerRadius:30.0f];
    [self.speakerButton.layer setCornerRadius:30.0f];
    [self.videoDisableButton.layer setCornerRadius:30.0f];
    [self.hangUpButton.layer setCornerRadius:30.0f];
    [self.videoCallButton.layer setCornerRadius:30.0f];
    [self.toggleChatButton.layer setCornerRadius:30.0f];
    [self.raiseHandButton.layer setCornerRadius:30.0f];
    [self.closeScreensharingButton.layer setCornerRadius:16.0f];
        
    self.audioMuteButton.accessibilityLabel = NSLocalizedString(@"Microphone", nil);
    self.audioMuteButton.accessibilityValue = NSLocalizedString(@"Microphone enabled", nil);
    self.audioMuteButton.accessibilityHint = NSLocalizedString(@"Double tap to enable or disable the microphone", nil);
    self.speakerButton.accessibilityLabel = NSLocalizedString(@"Speaker", nil);
    self.speakerButton.accessibilityValue = NSLocalizedString(@"Speaker disabled", nil);
    self.speakerButton.accessibilityHint = NSLocalizedString(@"Double tap to enable or disable the speaker", nil);
    self.videoDisableButton.accessibilityLabel = NSLocalizedString(@"Camera", nil);
    self.videoDisableButton.accessibilityValue = NSLocalizedString(@"Camera enabled", nil);
    self.videoDisableButton.accessibilityHint = NSLocalizedString(@"Double tap to enable or disable the camera", nil);
    self.hangUpButton.accessibilityLabel = NSLocalizedString(@"Hang up", nil);
    self.hangUpButton.accessibilityHint = NSLocalizedString(@"Double tap to hang up the call", nil);
    self.videoCallButton.accessibilityLabel = NSLocalizedString(@"Camera", nil);
    self.videoCallButton.accessibilityHint = NSLocalizedString(@"Double tap to upgrade this voice call to a video call", nil);
    self.toggleChatButton.accessibilityLabel = NSLocalizedString(@"Chat", nil);
    self.toggleChatButton.accessibilityHint = NSLocalizedString(@"Double tap to show or hide chat view", nil);
    
    [self adjustButtonsConainer];
    [self showButtonsContainerAnimated:NO];
    [self showChatToggleButtonAnimated:NO];
    
    self.collectionView.delegate = self;
    
    [self createWaitingScreen];
    
    // We disableLocalVideo here even if the call controller has not been created just to show the video button as disabled
    // also we set _userDisabledVideo = YES so the proximity sensor doesn't enable it.
    if (_videoDisabledAtStart) {
        _userDisabledVideo = YES;
        [self disableLocalVideo];
    }
    
    [self.collectionView registerNib:[UINib nibWithNibName:kCallParticipantCellNibName bundle:nil] forCellWithReuseIdentifier:kCallParticipantCellIdentifier];
    
    if (@available(iOS 11.0, *)) {
        [self.collectionView setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
    }
    
    
    
    UIPanGestureRecognizer *localVideoDragGesturure = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(localVideoDragged:)];
    [self.localVideoView addGestureRecognizer:localVideoDragGesturure];
        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sensorStateChange:)
                                                 name:UIDeviceProximityStateDidChangeNotification object:nil];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [self.collectionView.collectionViewLayout invalidateLayout];
    [_halo setHidden:YES];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self setLocalVideoRect];
        for (UICollectionViewCell *cell in self->_collectionView.visibleCells) {
            CallParticipantViewCell * participantCell = (CallParticipantViewCell *) cell;
            [participantCell resizeRemoteVideoView];
        }
        [self resizeScreensharingView];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self setHaloToToggleChatButton];
        // Workaround to move buttons to correct position (visible/not visible) so there is always an animation
        if (self->_isDetailedViewVisible) {
            [self showButtonsContainerAnimated:NO];
            [self showChatToggleButtonAnimated:NO];
        } else {
            [self hideButtonsContainerAnimated:NO];
            [self hideChatToggleButtonAnimated:NO];
        }
    }];
}

- (void)viewSafeAreaInsetsDidChange
{
    [super viewSafeAreaInsetsDidChange];
    [self setLocalVideoRect];
    // Workaround to move buttons to correct position (visible/not visible) so there is always an animation
    if (_isDetailedViewVisible) {
        [self showButtonsContainerAnimated:NO];
        [self showChatToggleButtonAnimated:NO];
    } else {
        [self hideButtonsContainerAnimated:NO];
        [self hideChatToggleButtonAnimated:NO];
    }
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [self setLocalVideoRect];
    
    // Fix missing hallo after the view controller disappears
    // e.g. when presenting file preview
    if (_chatNavigationController) {
        [self setHaloToToggleChatButton];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
    [UIApplication sharedApplication].idleTimerDisabled = YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)pressesBegan:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event
{
    // No push-to-talk while in chat
    if (!_chatNavigationController) {
        for (UIPress* press in presses) {
            if (press.key.keyCode == UIKeyboardHIDUsageKeyboardSpacebar) {
                [self pushToTalkStart];
                
                return;
            }
        }
    }
    
    [super pressesBegan:presses withEvent:event];
}

- (void)pressesEnded:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event
{
    // No push-to-talk while in chat
    if (!_chatNavigationController) {
        for (UIPress* press in presses) {
            if (press.key.keyCode == UIKeyboardHIDUsageKeyboardSpacebar) {
                [self pushToTalkEnd];
                
                return;
            }
        }
    }
    
    [super pressesEnded:presses withEvent:event];
}

#pragma mark - Rooms manager notifications

- (void)didJoinRoom:(NSNotification *)notification
{
    NSString *token = [notification.userInfo objectForKey:@"token"];
    if (![token isEqualToString:_room.token]) {
        return;
    }
    
    NSError *error = [notification.userInfo objectForKey:@"error"];
    if (error) {
        [self presentJoinError:[notification.userInfo objectForKey:@"errorReason"]];
        return;
    }
    
    NCRoomController *roomController = [notification.userInfo objectForKey:@"roomController"];
    if (!_callController) {
        [self startCallWithSessionId:roomController.userSessionId];
    }
    
    // listen to kikao utilities
    [self requestListener];
}


- (void)providerDidChangeAudioMute:(NSNotification *)notification
{
    NSString *roomToken = [notification.userInfo objectForKey:@"roomToken"];
    if (![roomToken isEqualToString:_room.token]) {
        return;
    }
    
    BOOL isMuted = [[notification.userInfo objectForKey:@"isMuted"] boolValue];
    if (isMuted) {
        [self muteAudio];
    } else {
        [self unmuteAudio];
    }
}

- (void)providerDidEndCall:(NSNotification *)notification
{
    NSString *roomToken = [notification.userInfo objectForKey:@"roomToken"];
    if (![roomToken isEqualToString:_room.token]) {
        return;
    }
    
    [self hangup];
}

- (void)providerWantsToUpgradeToVideoCall:(NSNotification *)notification
{
    NSString *roomToken = [notification.userInfo objectForKey:@"roomToken"];
    if (![roomToken isEqualToString:_room.token]) {
        return;
    }
    
    if (_isAudioOnly) {
        [self showUpgradeToVideoCallDialog];
    }
}

#pragma mark - Local video

- (void)setLocalVideoRect
{
    CGSize localVideoSize = CGSizeMake(0, 0);
    
    CGFloat width = [UIScreen mainScreen].bounds.size.width / 6;
    CGFloat height = [UIScreen mainScreen].bounds.size.height / 6;
    
    NSString *videoResolution = [[[NCSettingsController sharedInstance] videoSettingsModel] currentVideoResolutionSettingFromStore];
    NSString *localVideoRes = [[[NCSettingsController sharedInstance] videoSettingsModel] readableResolution:videoResolution];
    
    if ([localVideoRes isEqualToString:@"Low"] || [localVideoRes isEqualToString:@"Normal"]) {
        if (width < height) {
            localVideoSize = CGSizeMake(height * 3/4, height);
        } else {
            localVideoSize = CGSizeMake(width, width * 3/4);
        }
    } else {
        if (width < height) {
            localVideoSize = CGSizeMake(height * 9/16, height);
        } else {
            localVideoSize = CGSizeMake(width, width * 9/16);
        }
    }
    
    _localVideoOriginPosition = CGPointMake(16, 60);
    if (@available(iOS 11.0, *)) {
        UIEdgeInsets safeAreaInsets = self.view.safeAreaInsets;
        _localVideoOriginPosition = CGPointMake(16 + safeAreaInsets.left, 60 + safeAreaInsets.top);
    }
    
    CGRect localVideoRect = CGRectMake(_localVideoOriginPosition.x, _localVideoOriginPosition.y, localVideoSize.width, localVideoSize.height);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_localVideoView.frame = localVideoRect;
        self->_localVideoView.layer.cornerRadius = 4.0f;
        self->_localVideoView.layer.masksToBounds = YES;
    });
}

#pragma mark - Proximity sensor

- (void)sensorStateChange:(NSNotificationCenter *)notification
{
    if (!_isAudioOnly) {
        if ([[UIDevice currentDevice] proximityState] == YES) {
            [self disableLocalVideo];
            [[NCAudioController sharedInstance] setAudioSessionToVoiceChatMode];
        } else {
            // Only enable video if it was not disabled by the user.
//            if (!_userDisabledVideo) {
//                [self enableLocalVideo];
//            }
            [[NCAudioController sharedInstance] setAudioSessionToVideoChatMode];
        }
    }
    
    [self pushToTalkEnd];
}

#pragma mark - User Interface

- (void)setCallState:(CallState)state
{
    _callState = state;
    switch (state) {
        case CallStateJoining:
        case CallStateWaitingParticipants:
        case CallStateReconnecting:
        {
            [self showWaitingScreen];
            [self invalidateDetailedViewTimer];
            [self showDetailedView];
            [self removeTapGestureForDetailedView];
        }
            break;
            
        case CallStateInCall:
        {
            [self hideWaitingScreen];
            if (!_isAudioOnly) {
                [self addTapGestureForDetailedView];
                [self showDetailedViewWithTimer];
            }
        }
            break;
            
        default:
            break;
    }
}

- (void)setCallStateForPeersInCall
{
    if ([_peersInCall count] > 0) {
        if (_callState != CallStateInCall) {
            [self setCallState:CallStateInCall];
        }
    } else {
        if (_callState == CallStateInCall) {
            [self setCallState:CallStateWaitingParticipants];
        }
    }
}

- (void)createWaitingScreen
{
    if (_room.type == kNCRoomTypeOneToOne) {
        __weak AvatarBackgroundImageView *weakBGView = self.avatarBackgroundImageView;
        [self.avatarBackgroundImageView setImageWithURLRequest:[[NCAPIController sharedInstance] createAvatarRequestForUser:_room.name andSize:96 usingAccount:[[NCDatabaseManager sharedInstance] activeAccount]]
                                              placeholderImage:nil success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull image) {
                                                  NSDictionary *headers = [response allHeaderFields];
                                                  id customAvatarHeader = [headers objectForKey:@"X-NC-IsCustomAvatar"];
                                                  BOOL shouldShowBlurBackground = YES;
                                                  if (customAvatarHeader) {
                                                      shouldShowBlurBackground = [customAvatarHeader boolValue];
                                                  } else if ([response statusCode] == 201) {
                                                      shouldShowBlurBackground = NO;
                                                  }
                                                  
                                                  if (shouldShowBlurBackground) {
                                                      UIImage *blurImage = [NCUtils blurImageFromImage:image];
                                                      [weakBGView setImage:blurImage];
                                                      weakBGView.contentMode = UIViewContentModeScaleAspectFill;
                                                  } else {
                                                      DBImageColorPicker *colorPicker = [[DBImageColorPicker alloc] initFromImage:image withBackgroundType:DBImageColorPickerBackgroundTypeDefault];
                                                      [weakBGView setBackgroundColor:colorPicker.backgroundColor];
                                                      weakBGView.backgroundColor = [weakBGView.backgroundColor colorWithAlphaComponent:0.8];
                                                  }
                                              } failure:nil];
    } else {
        self.avatarBackgroundImageView.backgroundColor = [UIColor colorWithWhite:0.5 alpha:1];
    }
    
    [self setWaitingScreenText];
}

- (void)setWaitingScreenText
{
    NSString *waitingMessage = NSLocalizedString(@"Waiting for others to join …", nil);
    if (_room.type == kNCRoomTypeOneToOne) {
        waitingMessage = [NSString stringWithFormat:NSLocalizedString(@"Waiting for %@ to join …", nil), _room.displayName];
    }
    
    if (_callState == CallStateReconnecting) {
        waitingMessage = NSLocalizedString(@"Connecting to the meeting …", nil);
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.waitingLabel.text = waitingMessage;
    });
}

- (void)showWaitingScreen
{
    [self setWaitingScreenText];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.collectionView.backgroundView = self.waitingView;
    });
}

- (void)hideWaitingScreen
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.collectionView.backgroundView = nil;
    });
}

- (void)addTapGestureForDetailedView
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view addGestureRecognizer:self->_tapGestureForDetailedView];
    });
}

- (void)removeTapGestureForDetailedView
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view removeGestureRecognizer:self->_tapGestureForDetailedView];
    });
}

- (void)showDetailedView
{
    _isDetailedViewVisible = YES;
    [self showButtonsContainerAnimated:YES];
    [self showChatToggleButtonAnimated:YES];
    [self showPeersInfo];
}

- (void)showDetailedViewWithTimer
{
    if (_isDetailedViewVisible) {
        [self hideDetailedView];
    } else {
        [self showDetailedView];
        [self setDetailedViewTimer];
    }
}

- (void)hideDetailedView
{
    // Keep detailed view visible while push to talk is active
    if (_pushToTalkActive) {
        [self setDetailedViewTimer];
        return;
    }
    
    _isDetailedViewVisible = NO;
    [self hideButtonsContainerAnimated:YES];
    [self hideChatToggleButtonAnimated:YES];
    [self hidePeersInfo];
    [self invalidateDetailedViewTimer];
}

- (void)hideAudioMuteButton
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.3f animations:^{
            [self.audioMuteButton setAlpha:0.0f];
            [self.view layoutIfNeeded];
        }];
    });
}

- (void)showAudioMuteButton
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.3f animations:^{
            [self.audioMuteButton setAlpha:1.0f];
            [self.view layoutIfNeeded];
        }];
    });
}

- (void)showButtonsContainerAnimated:(BOOL)animated
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.buttonsContainerView setAlpha:1.0f];
        CGFloat duration = animated ? 0.3 : 0.0;
        [UIView animateWithDuration:duration animations:^{
            CGRect buttonsFrame = self.buttonsContainerView.frame;
            buttonsFrame.origin.y = self.view.frame.size.height - buttonsFrame.size.height - 16;
            if (@available(iOS 11.0, *)) {
                buttonsFrame.origin.y -= self.view.safeAreaInsets.bottom;
            }
            self.buttonsContainerView.frame = buttonsFrame;
        } completion:^(BOOL finished) {
            [self adjustLocalVideoPositionFromOriginPosition:self->_localVideoOriginPosition];
        }];
        [UIView animateWithDuration:0.3f animations:^{
            [self.switchCameraButton setAlpha:1.0f];
            [self.closeScreensharingButton setAlpha:1.0f];
            [self.view layoutIfNeeded];
        }];
    });
}

- (void)hideButtonsContainerAnimated:(BOOL)animated
{
    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat duration = animated ? 0.3 : 0.0;
        [UIView animateWithDuration:duration animations:^{
            CGRect buttonsFrame = self.buttonsContainerView.frame;
            buttonsFrame.origin.y = self.view.frame.size.height;
            self.buttonsContainerView.frame = buttonsFrame;
        } completion:^(BOOL finished) {
            [self adjustLocalVideoPositionFromOriginPosition:self->_localVideoOriginPosition];
            [self.buttonsContainerView setAlpha:0.0f];
        }];
        [UIView animateWithDuration:0.3f animations:^{
            [self.switchCameraButton setAlpha:0.0f];
            [self.closeScreensharingButton setAlpha:0.0f];
            [self.view layoutIfNeeded];
        }];
    });
}

- (void)showChatToggleButtonAnimated:(BOOL)animated
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.toggleChatButton setAlpha:1.0f];
        CGFloat duration = animated ? 0.3 : 0.0;
        [UIView animateWithDuration:duration animations:^{
            CGRect buttonFrame = self.toggleChatButton.frame;
            buttonFrame.origin.x = self.view.frame.size.width - buttonFrame.size.width - 16;
            buttonFrame.origin.y = 60;
            if (@available(iOS 11.0, *)) {
                buttonFrame.origin.x -= self.view.safeAreaInsets.right;
                buttonFrame.origin.y = self.view.safeAreaInsets.top + 60;
            }
            self.toggleChatButton.frame = buttonFrame;
        }];
    });
}

- (void)hideChatToggleButtonAnimated:(BOOL)animated
{
    if (!_chatNavigationController) {
        dispatch_async(dispatch_get_main_queue(), ^{
            CGFloat duration = animated ? 0.3 : 0.0;
            [UIView animateWithDuration:duration animations:^{
                CGRect buttonFrame = self.toggleChatButton.frame;
                buttonFrame.origin.x = self.view.frame.size.width;
                buttonFrame.origin.y = 60;
                if (@available(iOS 11.0, *)) {
                    buttonFrame.origin.y = self.view.safeAreaInsets.top + 60;
                }
                self.toggleChatButton.frame = buttonFrame;
            } completion:^(BOOL finished) {
                [self.toggleChatButton setAlpha:0.0f];
            }];
        });
    }
}

- (void)adjustButtonsConainer
{
    if (_isAudioOnly) {
        _videoDisableButton.hidden = YES;
        _switchCameraButton.hidden = YES;
        _videoCallButton.hidden = NO;
    } else {
        _speakerButton.hidden = YES;
        _videoCallButton.hidden = YES;
//         Center chat - audio - video - hang up buttons
        CGRect chatButtonFrame = _chatButton.frame;
        chatButtonFrame.origin.x = 0;
        _chatButton.frame = chatButtonFrame;

        CGRect audioButtonFrame = _audioMuteButton.frame;
        audioButtonFrame.origin.x = 85;
        _audioMuteButton.frame = audioButtonFrame;

        CGRect videoButtonFrame = _videoDisableButton.frame;
        videoButtonFrame.origin.x = 175;
        _videoDisableButton.frame = videoButtonFrame;

        CGRect hangUpButtonFrame = _hangUpButton.frame;
        hangUpButtonFrame.origin.x = 250;
        _hangUpButton.frame = hangUpButtonFrame;
    }
    
    // Only show speaker button in iPhones
//    if(![[UIDevice currentDevice].model isEqualToString:@"iPhone"] && _isAudioOnly) {
//        _speakerButton.hidden = YES;
//        // Center audio - video - hang up buttons
//        CGRect audioButtonFrame = _audioMuteButton.frame;
//        audioButtonFrame.origin.x = 40;
//        _audioMuteButton.frame = audioButtonFrame;
//        CGRect videoButtonFrame = _videoCallButton.frame;
//        videoButtonFrame.origin.x = 130;
//        _videoCallButton.frame = videoButtonFrame;
//        CGRect hangUpButtonFrame = _hangUpButton.frame;
//        hangUpButtonFrame.origin.x = 220;
//        _hangUpButton.frame = hangUpButtonFrame;
//    }
}

- (void)setDetailedViewTimer
{
    [self invalidateDetailedViewTimer];
    _detailedViewTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(hideDetailedView) userInfo:nil repeats:NO];
}

- (void)invalidateDetailedViewTimer
{
    [_detailedViewTimer invalidate];
    _detailedViewTimer = nil;
}

- (void)presentJoinError:(NSString *)alertMessage
{
    NSString *alertTitle = [NSString stringWithFormat:NSLocalizedString(@"Could not join %@ call", nil), _room.displayName];
    if (_room.type == kNCRoomTypeOneToOne) {
        alertTitle = [NSString stringWithFormat:NSLocalizedString(@"Could not join call with %@", nil), _room.displayName];
    }
    
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                                    message:alertMessage
                                                             preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* okButton = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * _Nonnull action) {
                                                         [self hangup];
                                                     }];
    [alert addAction:okButton];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:alert animated:YES completion:nil];
    });
}

- (void)adjustLocalVideoPositionFromOriginPosition:(CGPoint)position
{
    UIEdgeInsets edgeInsets = UIEdgeInsetsMake(16, 16, 16, 16);
    if (@available(iOS 11.0, *)) {
        UIEdgeInsets safeAreaInsets = _localVideoView.superview.safeAreaInsets;
        edgeInsets = UIEdgeInsetsMake(16 + safeAreaInsets.top, 16 + safeAreaInsets.left,16 + safeAreaInsets.bottom,16 + safeAreaInsets.right);
    }

    CGSize parentSize = _localVideoView.superview.bounds.size;
    CGSize viewSize = _localVideoView.bounds.size;

    // Adjust left
    if (position.x < edgeInsets.left) {
        position = CGPointMake(edgeInsets.left, position.y);
    }
    // Adjust top
    if (position.y < edgeInsets.top) {
        position = CGPointMake(position.x, edgeInsets.top);
    }
    // Adjust right
    BOOL isChatButtonVisible = _toggleChatButton.frame.origin.x < parentSize.width;
    if (isChatButtonVisible && position.x > _toggleChatButton.frame.origin.x - viewSize.height - edgeInsets.right) {
        position = CGPointMake(_toggleChatButton.frame.origin.x - viewSize.width - edgeInsets.right, position.y);
    } else if (position.x > parentSize.width - viewSize.width - edgeInsets.right) {
        position = CGPointMake(parentSize.width - viewSize.width - edgeInsets.right, position.y);
    }
    // Adjust bottom
    if (_isDetailedViewVisible && position.y > _buttonsContainerView.frame.origin.y - viewSize.height - edgeInsets.bottom) {
        position = CGPointMake(position.x, _buttonsContainerView.frame.origin.y - viewSize.height - edgeInsets.bottom);
    } else if (position.y > parentSize.height - viewSize.height - edgeInsets.bottom) {
        position = CGPointMake(position.x, parentSize.height - viewSize.height - edgeInsets.bottom);
    }
    CGRect frame = _localVideoView.frame;
    frame.origin.x = position.x;
    frame.origin.y = position.y;

    [UIView animateWithDuration:0.3 animations:^{
        self->_localVideoView.frame = frame;
    }];
}

- (void)localVideoDragged:(UIPanGestureRecognizer *)gesture
{
    if (gesture.view == _localVideoView) {
        if (gesture.state == UIGestureRecognizerStateBegan) {
            _localVideoDragStartingPosition = gesture.view.center;
        } else if (gesture.state == UIGestureRecognizerStateChanged) {
            CGPoint translation = [gesture translationInView:gesture.view];
            _localVideoView.center = CGPointMake(_localVideoDragStartingPosition.x + translation.x, _localVideoDragStartingPosition.y + translation.y);
        } else if (gesture.state == UIGestureRecognizerStateEnded) {
            _localVideoOriginPosition = gesture.view.frame.origin;
            [self adjustLocalVideoPositionFromOriginPosition:_localVideoOriginPosition];
        }
    }
}

#pragma mark - Talk Request actions

// roomTypes
/*
 ROOM TYPES
 1      - one to one
 2,3    - staff
 22     - group committee
 33     - public committee
 222    - group plenary
 333    - public plenary
 20     - breakout
 */
- (void)handleTalkControls
{
    NSLog(@"CALLVIEWROOM: %ld", (long)_room.type);
    // Set room image
    switch ((int)_room.type) {
        // staff
        case 2:
        case 3:
        {
            NSLog(@"SHOW RAISE HAND");
            [self.raiseHandContainerView setHidden:NO];
        }
            break;
        // committee
        case 22:
        case 33:
        // plenary
        case 222:
        case 333:
        // breakout
//        case 20:
        {
            NSLog(@"SHOW REQ CONTROLS");
            [self.requestContainerView setHidden:NO];
            
            [self muteAudio];
            [self disableLocalVideo];
            
            if(_callController){
                NSLog(@"_callController.....YES");
                [self.audioMuteButton setHidden:YES];
                [self.videoCallButton setHidden:YES];
                [self.videoDisableButton setHidden:YES];
            }else{
                NSLog(@"_callController.....NO");
            }

        }
            break;
            
        default:
            break;
    }
}

#pragma mark - Call actions

-(void)handlePushToTalk:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [self pushToTalkStart];
    } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        [self pushToTalkEnd];
    }
}

- (void)pushToTalkStart
{
    if (_callController && ![_callController isAudioEnabled]) {
        [self unmuteAudio];
        
        [self setHaloToAudioMuteButton];
        [_buttonFeedbackGenerator impactOccurred];
        _pushToTalkActive = YES;
    }
}

- (void)pushToTalkEnd
{
    if (_pushToTalkActive) {
        [self muteAudio];
        
        [self removeHaloFromAudioMuteButton];
        _pushToTalkActive = NO;
    }
}

- (IBAction)audioButtonPressed:(id)sender
{
    if (!_callController) {return;}
    
    if ([_callController isAudioEnabled]) {
        if ([CallKitManager isCallKitAvailable]) {
            [[CallKitManager sharedInstance] reportAudioMuted:YES forCall:_room.token];
        } else {
            [self muteAudio];
        }
    } else {
        if ([CallKitManager isCallKitAvailable]) {
            [[CallKitManager sharedInstance] reportAudioMuted:NO forCall:_room.token];
        } else {
            [self unmuteAudio];
        }
        
        if ((!_isAudioOnly && _callState == CallStateInCall) || _screenView) {
            // Audio was disabled -> make sure the permanent visible audio button is hidden again
            [self showDetailedViewWithTimer];
        }
    }
}

// Requesting to speak (0)
-(void)handleSpeakRequest
{
    if (_callController) {
        if (!_speakRequest) {
            NSLog(@"handleSpeakRequest ......");
            
            _speakRequest = YES;

            [_callController requestToSpeak];
            
            NSString *speakReqString = NSLocalizedString(@"Requested to speak", nil);
            self->_speakRequestButton.accessibilityValue = speakReqString;
            [self.view makeToast:speakReqString duration:1.5 position:CSToastPositionCenter];
            
            _speakRequestButton.backgroundColor = [UIColor systemRedColor];
            [_speakRequestButton setTitle:@"Cancel" forState: UIControlStateNormal];
            
        }else{
            [self handleCancelSpeak];
        }
    }
}

// requesting to intervene (1)
-(void)handleInterveneRequest
{
    if (_callController) {
        if (!_interveneRequest) {
            NSLog(@"handleInterveneRequest ......");
            
            _interveneRequest = YES;
            
            [_callController requestToIntervene];
            
            NSString *speakReqString = NSLocalizedString(@"Requested to intervene", nil);
            self->_interveneRequestButton.accessibilityValue = speakReqString;
            [self.view makeToast:speakReqString duration:1.0 position:CSToastPositionCenter];
            
            _interveneRequestButton.backgroundColor = [UIColor systemRedColor];
            [_interveneRequestButton setTitle:@"Cancel" forState: UIControlStateNormal];
            
        }else{
            [self handleCancelIntervene];
        }
    }
}

- (void) requestListener
{
    //Start playing an audio file.
    NSLog(@"start timer........");
    //NSTimer calling Method B, as long the audio file is playing, every 5 seconds.
    [NSTimer scheduledTimerWithTimeInterval:1.0f
    target:self selector:@selector(handleRequests:) userInfo:nil repeats:YES];
}

- (void) handleRequests:(NSTimer *)timer
{
    
//    NSLog(@"methodB..listening.......");
//    _requestedSpeak = [_callController requestedSpeak];
//    _requestedIntervene = [_callController requestedIntervene];

//    NSLog(@"_requestedSpeak...:%id", _requestedSpeak);
//    NSLog(@"_requestedIntervene...:%id", _requestedIntervene);

    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSInteger * speakId = [defaults integerForKey:@"speakId"];
    NSInteger * interveneId = [defaults integerForKey:@"interveneId"];

    if(speakId!=nil){
//        NSLog(@"handleSpeakRequest...:%ld", speakId);
        _speakRequest = YES;
        _speakRequestButton.backgroundColor = [UIColor systemRedColor];
        [_speakRequestButton setTitle:@"Cancel" forState: UIControlStateNormal];
    }
    
    if(interveneId!=nil){
//        NSLog(@"handleInterveneRequest...:%ld", interveneId);
        _interveneRequest = YES;
        _interveneRequestButton.backgroundColor = [UIColor systemRedColor];
        [_interveneRequestButton setTitle:@"Cancel" forState: UIControlStateNormal];
    }
    
//    NSInteger * speakId = [_callController speakId];
//    NSInteger * interveneId = [_callController interveneId];
    
    _responses = [_callController allRequests];
    
    _allVotes = [_callController allPollVotes];
    
//    NCVote *vote = [_callController votePoll];
        
    // check if call has a vote
    if(_allVotes.count > 0){
//        NSLog(@"***************************** LETS VOTE  **************************************");
//        NSLog(@"_allVotes......:%ld",(long)_allVotes.firstObject.voteId);
        
        [self.voteButton setHidden:NO];
    }else{
        [self.voteButton setHidden:YES];
    }
    
    // if requested to speak handle speak logic
    if(_speakRequest){
        if(_approvedSpeak && _responses.count == 0){
//                NSLog(@"_approvedSpeak No _responses..............................");
                _approvedSpeak = NO;
                [self handleCancelSpeak];
        }
        
        
        for (NCKActivity *activity in _responses) {
        
                if(activity.activityId == speakId){
                    _speakActivity = activity;

                    if(activity.approved){
                        _approvedSpeak = YES;
                        
//                        NSLog(@"Show controls....");
                        [self showControls];

                        if (activity.started){
//                            NSLog(@"Started.........");
                            [self.timerButton setHidden:NO];
                            if(activity.paused){
//                                NSLog(@"Paused...");
                                [self hideControls];
                            }else{
                                // start timer
                                [self startCount:activity.duration since:activity.talkingSince];
                            }
                        }

                    } else {
//                        NSLog(@"_approvedSpeak NO..............................");
                        if(!_approvedIntervene){
                            [self hideControls];
                        }
                    }
                }

        }
        
        if(_approvedSpeak && ![_responses containsObject:_speakActivity]){
            NSLog(@"Cancel request........._speakActivity....: %id", [_responses containsObject:_speakActivity]);
//            NSLog(@"Cancel request.........._speakActivity......:%ld", (long) _speakActivity.activityId);
//            NSLog(@"Cancel request........................_speakActivity..............................");
            _approvedSpeak = NO;
            [self handleCancelSpeak];
        }
    }
    
    
    // if requested to intervene handle intervene logic
    if(_interveneRequest){
        if(_approvedIntervene && _responses.count == 0){
//                NSLog(@"_approvedIntervene No _responses..............................");
                _approvedIntervene = NO;
                [self handleCancelIntervene];
        }
        
                
        for (NCKActivity *activity in _responses) {

                if(activity.activityId == interveneId){
                    _interveneActivity = activity;

                    if(activity.approved){
                        _approvedIntervene = YES;
                        
//                        NSLog(@"Show controls....");
                        [self showControls];

                        if (activity.started){
//                            NSLog(@"Started.........");
                            [self.timerButton setHidden:NO];
                            if(activity.paused){
//                                NSLog(@"Paused...");
                                [self hideControls];
                            }else{
                                // start timer
                                [self startCount:activity.duration since:activity.talkingSince];
                            }
                        }

                    } else {
//                        NSLog(@"_approvedIntervene NO..............................");
                        if(!_approvedSpeak){
                            [self hideControls];
                        }
                    }
                }

            }
        
        if(_approvedIntervene && ![_responses containsObject:_interveneActivity]){
            NSLog(@"Cancel request........._interveneActivity....: %id", [_responses containsObject:_interveneActivity]);
//            NSLog(@"Cancel request.........._interveneActivity......:%ld", (long) _interveneActivity.activityId);
//            NSLog(@"Cancel request........................_interveneActivity..............................");
            _approvedIntervene = NO;
            [self handleCancelIntervene];
        }
    }
    
}

- (void)startCount:(NSInteger)duration since:(NSInteger)talkingSince
{
//    NSLog(@"----------------------------------------------------------");

//    NSLog(@"duration.....: %ld",(long)duration);
//    NSLog(@"talkingSince.....: %ld",(long)talkingSince);

    
    NSDate *now = [NSDate date]; // current date
    int today = [now timeIntervalSince1970];
    
//    NSLog(@"Now.....%d",today);
    
    long diff = today - talkingSince;

//    NSLog(@"DifferenceSince.....: %ld", diff);
    
    double theMinutes = duration - diff;
    
//    NSLog(@"Difference in theMinutes.....: %f", theMinutes);
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"mm:ss"];

    NSDate *epochNSDate = [[NSDate alloc] initWithTimeIntervalSince1970:theMinutes];
    
//    NSLog(@"epochNSDate.....: %@", epochNSDate);

    
    NSString *time = [dateFormatter stringFromDate:epochNSDate];
//    NSLog (@"Time:- %@", time);
    
    
    if(theMinutes>0){
        [_timerButton setTitle:time forState: UIControlStateNormal];

        if(theMinutes > 60){
            _timerButton.backgroundColor = [UIColor systemGreenColor];
        }else if(theMinutes < 30){
            _timerButton.backgroundColor = [UIColor systemRedColor];
        }else{
            _timerButton.backgroundColor = [UIColor systemOrangeColor];
        }
    }

//    NSLog(@"----------------------------------------------------------");
}

-(void)handleCancelSpeak
{

//    NSLog(@"handleCancelSpeak ......");
    NSString *cancelString = NSLocalizedString(@"Canceled Speak", nil);
    [self.view makeToast:cancelString duration:1.5 position:CSToastPositionCenter];

    // hide controls
    [self hideControls];
    
    // reset timer
    if(!_approvedIntervene)
    [self.timerButton setHidden:YES];
    
    _speakRequest = NO;

    _speakRequestButton.backgroundColor = [UIColor systemGreenColor];

    [_speakRequestButton setTitle:@"Request To Speak" forState: UIControlStateNormal];
    
    //cancel with api
    [_callController cancelSpeak];
    
    // stop listener

}

-(void)handleCancelIntervene
{

//    NSLog(@"handleCancelIntervene ......");
    NSString *cancelString = NSLocalizedString(@"Canceled Intervene", nil);
    [self.view makeToast:cancelString duration:1.5 position:CSToastPositionCenter];

    // hide controls
    [self hideControls];
    
    // reset timer
    if(!_approvedSpeak)
    [self.timerButton setHidden:YES];
    
    _interveneRequest = NO;

    _interveneRequestButton.backgroundColor = [UIColor systemGreenColor];

    [_interveneRequestButton setTitle:@"Request To Intervene" forState: UIControlStateNormal];
    
    //cancel with api
    [_callController cancelIntervene];
    
    // stop listener

}

-(void)showControls
{
//    NSLog(@"showControls ......");
    
    [self.audioMuteButton setHidden:NO];
    [self.videoCallButton setHidden:NO];
    [self.videoDisableButton setHidden:NO];
}

-(void)hideControls
{
//    NSLog(@"hideControls ......");
    
    [self muteAudio];
    [self disableLocalVideo];
    [self.audioMuteButton setHidden:YES];
    [self.videoCallButton setHidden:YES];
    [self.videoDisableButton setHidden:YES];
}

-(void)startTimer
{
//    NSLog(@"startTimer ......");
//    [_callController requestStarted];
    
    if(_approvedSpeak){
//        NSLog(@"_approvedSpeak  startTimer ......");
        [_callController startSpeak];
    }
    
    if(_approvedIntervene){
//        NSLog(@"_approvedIntervene  startTimer ......");
        [_callController startIntervene];
    }
}

//-(void) startSpeakTimer:(NSInteger*)speakID startInterveneTimer:(NSInteger*)interveneID
//{
//    if(speakID != nil){
//        [_callController startSpeak];
//    }
//
//    if(interveneID != nil){
//        [_callController startIntervene];
//    }
//}

#pragma mark - Raise hand actions

// Requesting to raise hand
-(void)handleRaiseHand {
    if(!_raisedHand){
        [self raiseHandUp];
    }else{
        [self raiseHandDown];
    }
}

- (void)raiseHandUp
{
    if (!_raisedHand && _callController) {
//        NSLog(@"raiseHandUp...");
        _raisedHand = YES;

        [self.raiseHandButton setImage:[UIImage imageNamed:@"hand-up"] forState:UIControlStateNormal];
        NSString *raiseUpString = NSLocalizedString(@"Hand raised", nil);
        self->_raiseHandButton.accessibilityValue = raiseUpString;
        [self.view makeToast:raiseUpString duration:1.5 position:CSToastPositionCenter];
//        [_buttonFeedbackGenerator impactOccurred];
        [_callController raiseHand:YES];
    }
    
}

- (void)raiseHandDown
{
    if (_raisedHand && _callController) {
//        NSLog(@"raiseHandDown...");
        _raisedHand = NO;
        
        [self.raiseHandButton setImage:[UIImage imageNamed:@"hand-down"] forState:UIControlStateNormal];
        NSString *raiseDownString = NSLocalizedString(@"Cancelled", nil);
        self->_raiseHandButton.accessibilityValue = raiseDownString;
        [self.view makeToast:raiseDownString duration:1.5 position:CSToastPositionCenter];
//        [_buttonFeedbackGenerator impactOccurred];
//        [_callController raiseHand];
        [_callController raiseHand:NO];

    }
}

- (void)forceMuteAudio
{
    NSString *forceMutedString = NSLocalizedString(@"You have been muted by a moderator", nil);
    [self muteAudioWithReason:forceMutedString];
}

-(void)muteAudioWithReason:(NSString*)reason
{
    [_callController enableAudio:NO];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_audioMuteButton setImage:[UIImage imageNamed:@"audio-off"] forState:UIControlStateNormal];
        [self showAudioMuteButton];
        
        NSString *micDisabledString = NSLocalizedString(@"Microphone disabled", nil);
        NSTimeInterval duration = 1.5;
        UIView *toast;
        
        if (reason) {
            // Nextcloud uses a default timeout of 7s for toasts
            duration = 7.0;

            toast = [self.view toastViewForMessage:reason title:micDisabledString image:nil style:nil];
        } else {
            toast = [self.view toastViewForMessage:micDisabledString title:nil image:nil style:nil];
        }
        
//        [self.view showToast:toast duration:duration position:CSToastPositionCenter completion:nil];
    });
}

- (void)muteAudio
{
    [self muteAudioWithReason:nil];
}

- (void)unmuteAudio
{
    [_callController enableAudio:YES];
               
       switch ((int)_room.type) {
           // plenary
           case 222:
           case 333:
           {
               NSLog(@"Start timer ............................................");
               [self startTimer];
           }
               break;

           default:
               break;
       }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_audioMuteButton setImage:[UIImage imageNamed:@"audio"] forState:UIControlStateNormal];
        NSString *micEnabledString = NSLocalizedString(@"Microphone enabled", nil);
        self->_audioMuteButton.accessibilityValue = micEnabledString;
        [self.view makeToast:micEnabledString duration:1.5 position:CSToastPositionCenter];
    });
}

- (IBAction)videoButtonPressed:(id)sender
{
    if (!_callController) {return;}
    
    if ([_callController isVideoEnabled]) {
        [self disableLocalVideo];
        _userDisabledVideo = YES;
    } else {
        [self enableLocalVideo];
        _userDisabledVideo = NO;
    }
}

- (void)disableLocalVideo
{
    NSLog(@"disableLocalVideo...");
    [_callController enableVideo:NO];
    [_captureController stopCapture];
    [_localVideoView setHidden:YES];
    [_videoDisableButton setImage:[UIImage imageNamed:@"video-off"] forState:UIControlStateNormal];
    NSString *cameraDisabledString = NSLocalizedString(@"Camera disabled", nil);
    _videoDisableButton.accessibilityValue = cameraDisabledString;
//    if (!_isAudioOnly) {
//        [self.view makeToast:cameraDisabledString duration:1.5 position:CSToastPositionCenter];
//    }
}

- (void)enableLocalVideo
{
    NSLog(@"enableLocalVideo...");

    [_callController enableVideo:YES];
    [_captureController startCapture];
    [_localVideoView setHidden:NO];
    [_videoDisableButton setImage:[UIImage imageNamed:@"video"] forState:UIControlStateNormal];
    _videoDisableButton.accessibilityValue = NSLocalizedString(@"Camera enabled", nil);
}

- (IBAction)switchCameraButtonPressed:(id)sender
{
    [self switchCamera];
}

- (void)switchCamera
{
    [_captureController switchCamera];
    [self flipLocalVideoView];
}

- (void)flipLocalVideoView
{
    CATransition *animation = [CATransition animation];
    animation.duration = .5f;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.type = @"oglFlip";
    animation.subtype = kCATransitionFromRight;
    
    [self.localVideoView.layer addAnimation:animation forKey:nil];
}

- (IBAction)speakerButtonPressed:(id)sender
{
    if ([[NCAudioController sharedInstance] isSpeakerActive]) {
        [self disableSpeaker];
    } else {
        [self enableSpeaker];
    }
}

- (void)disableSpeaker
{
    [[NCAudioController sharedInstance] setAudioSessionToVoiceChatMode];
    [_speakerButton setImage:[UIImage imageNamed:@"speaker-off"] forState:UIControlStateNormal];
    NSString *speakerDisabledString = NSLocalizedString(@"Speaker disabled", nil);
    _speakerButton.accessibilityValue = speakerDisabledString;
    [self.view makeToast:speakerDisabledString duration:1.5 position:CSToastPositionCenter];
}

- (void)enableSpeaker
{
    [[NCAudioController sharedInstance] setAudioSessionToVideoChatMode];
    [_speakerButton setImage:[UIImage imageNamed:@"speaker"] forState:UIControlStateNormal];
    NSString *speakerEnabledString = NSLocalizedString(@"Speaker enabled", nil);
    _speakerButton.accessibilityValue = speakerEnabledString;
    [self.view makeToast:speakerEnabledString duration:1.5 position:CSToastPositionCenter];
}

- (IBAction)hangupButtonPressed:(id)sender
{
    [self hangup];
}

- (IBAction)raiseHandButtonPressed:(id)sender
{
    [self handleRaiseHand];
}

- (IBAction)speakRequestButtonPressed:(id)sender
{
    [self handleSpeakRequest];
}

- (IBAction)interveneRequestButtonPressed:(id)sender
{
    [self handleInterveneRequest];
}

- (void)hangup
{
    if (!_hangingUp) {
        _hangingUp = YES;
        // Dismiss possible notifications
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        
        [self.delegate callViewControllerWantsToBeDismissed:self];
        
        [_localVideoView.captureSession stopRunning];
        _localVideoView.captureSession = nil;
        [_localVideoView setHidden:YES];
        [_captureController stopCapture];
        _captureController = nil;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            for (NCPeerConnection *peerConnection in self->_peersInCall) {
                // Video renderers
                RTCEAGLVideoView *videoRenderer = [self->_videoRenderersDict objectForKey:peerConnection.peerId];
                [[peerConnection.remoteStream.videoTracks firstObject] removeRenderer:videoRenderer];
                [self->_videoRenderersDict removeObjectForKey:peerConnection.peerId];
                // Screen renderers
                RTCEAGLVideoView *screenRenderer = [self->_screenRenderersDict objectForKey:peerConnection.peerId];
                [[peerConnection.remoteStream.videoTracks firstObject] removeRenderer:screenRenderer];
                [self->_screenRenderersDict removeObjectForKey:peerConnection.peerId];
            }
        });
        
        if (_callController) {
            [_callController leaveCall];
        } else {
            [self finishCall];
        }
    }
}

- (IBAction)videoCallButtonPressed:(id)sender
{
    [self showUpgradeToVideoCallDialog];
}

- (void)showUpgradeToVideoCallDialog
{
    UIAlertController *confirmDialog =
    [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Do you want to enable your camera?", nil)
                                        message:NSLocalizedString(@"If you enable your camera, this call will be interrupted for a few seconds.", nil)
                                 preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Enable", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self upgradeToVideoCall];
    }];
    [confirmDialog addAction:confirmAction];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
    [confirmDialog addAction:cancelAction];
    [self presentViewController:confirmDialog animated:YES completion:nil];
}

- (void)upgradeToVideoCall
{
    _videoCallUpgrade = YES;
    [self hangup];
}

- (IBAction)toggleChatButtonPressed:(id)sender
{
    [self toggleChatView];
}

- (IBAction)toggleVoteButtonPressed:(id)sender
{
    if (@available(iOS 14.0, *)) {
        
//        _allVotes = [_callController allVotes];
        
//        UIViewController *userPolls = [SwiftUIViewWrapper createSwiftUIViewWithVote:_allVotes.firstObject];
//        NCNavigationController *userStatusMessageNC = [[NCNavigationController alloc] initWithRootViewController:userPolls];
//        [self presentViewController:userStatusMessageNC animated:YES completion:nil];
        
        _allVotes = [_callController allPollVotes];
        
        NCVote *vote = [_callController votePoll];
        
        NSLog(@"_callControllerVotePoll........: %@",[_callController votePoll]);

        NSLog(@"VotePrintedCopy........: %@",vote);

        
        for (NCVote *vote in [_callController allPollVotes]) {

            NSLog(@"VotePrinted........: %@",vote);

        }
//
//        for (NCVote *vote in _allVotes) {
//
//            NSLog(@"VotePrinted_allVotes_allVotes........: %@",vote.title);
//
//        }
        
//        NSLog(@"toggleRequestOtpButtonPressed......: %@", vote.title);
        
        
        
        UIViewController *userPolls = [SwiftUIViewWrapper createSwiftUIViewWithVote:vote];
        NCNavigationController *userStatusMessageNC = [[NCNavigationController alloc] initWithRootViewController:userPolls];
        [self presentViewController:userStatusMessageNC animated:YES completion:nil];
    }
}

- (void)toggleChatView
{
    if (!_chatNavigationController) {
//        NSLog(@"No_chatNavigationController...........");
        [_toggleChatButton setHidden:NO];
        
        TalkAccount *activeAccount = [[NCDatabaseManager sharedInstance] activeAccount];
        NCRoom *room = [[NCRoomsManager sharedInstance] roomWithToken:_room.token forAccountId:activeAccount.accountId];
        _chatViewController = [[NCChatViewController alloc] initForRoom:room];
        _chatViewController.presentedInCall = YES;
        _chatNavigationController = [[UINavigationController alloc] initWithRootViewController:_chatViewController];
        [self addChildViewController:_chatNavigationController];
        
        [self.view addSubview:_chatNavigationController.view];
        _chatNavigationController.view.frame = self.view.bounds;
        _chatNavigationController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [_chatNavigationController didMoveToParentViewController:self];
        
//        [self setHaloToToggleChatButton];
        
        [self showChatToggleButtonAnimated:NO];
        //green call
//        [_toggleChatButton setImage:[UIImage imageNamed:@"phone"] forState:UIControlStateNormal];
        [_toggleChatButton setTitle:@"Back to meeting"  forState:UIControlStateNormal];
        if (!_isAudioOnly) {
            [self.view bringSubviewToFront:_localVideoView];
        }
        [self.view bringSubviewToFront:_toggleChatButton];
        [self removeTapGestureForDetailedView];
    } else {
//        NSLog(@"BAck to_chatNavigationController...........");
        [_toggleChatButton setHidden:YES];

//        [_toggleChatButton setImage:[UIImage imageNamed:@"chat"] forState:UIControlStateNormal];
        [_halo removeFromSuperlayer];
        
        [self.view bringSubviewToFront:_buttonsContainerView];
        
        [_chatViewController leaveChat];
        _chatViewController = nil;
        
        [_chatNavigationController willMoveToParentViewController:nil];
        [_chatNavigationController.view removeFromSuperview];
        [_chatNavigationController removeFromParentViewController];
        
        _chatNavigationController = nil;
        
        if ((!_isAudioOnly && _callState == CallStateInCall) || _screenView) {
            [self addTapGestureForDetailedView];
            [self showDetailedViewWithTimer];
        }
    }
}

- (void)setHaloToToggleChatButton
{
    [_halo removeFromSuperlayer];
    
    if (_chatNavigationController) {
        _halo = [PulsingHaloLayer layer];
        _halo.position = _toggleChatButton.center;
        UIColor *color = [UIColor colorWithRed:118/255.f green:213/255.f blue:114/255.f alpha:1];
        _halo.backgroundColor = color.CGColor;
        _halo.radius = 40.0;
        _halo.haloLayerNumber = 2;
        _halo.keyTimeForHalfOpacity = 0.75;
        _halo.fromValueForRadius = 0.75;
        [_chatNavigationController.view.layer addSublayer:_halo];
        [_halo start];
    }
}

- (void)setHaloToAudioMuteButton
{
    [_haloPushToTalk removeFromSuperlayer];
    
    if (_buttonsContainerView) {
        _haloPushToTalk = [PulsingHaloLayer layer];
        _haloPushToTalk.position = _audioMuteButton.center;
        UIColor *color = [UIColor colorWithRed:118/255.f green:213/255.f blue:114/255.f alpha:1];
        _haloPushToTalk.backgroundColor = color.CGColor;
        _haloPushToTalk.radius = 40.0;
        _haloPushToTalk.haloLayerNumber = 2;
        _haloPushToTalk.keyTimeForHalfOpacity = 0.75;
        _haloPushToTalk.fromValueForRadius = 0.75;
        [_buttonsContainerView.layer addSublayer:_haloPushToTalk];
        [_haloPushToTalk start];
        
        [_buttonsContainerView bringSubviewToFront:_audioMuteButton];
    }
    
}

- (void)removeHaloFromAudioMuteButton
{
    if (_haloPushToTalk) {
        [_haloPushToTalk removeFromSuperlayer];
    }
}

- (void)finishCall
{
    _callController = nil;
    if (_videoCallUpgrade) {
        _videoCallUpgrade = NO;
        [self.delegate callViewControllerWantsVideoCallUpgrade:self];
    } else {
        [self.delegate callViewControllerDidFinish:self];
    }
}

#pragma mark - CallParticipantViewCell delegate

- (void)cellWantsToPresentScreenSharing:(CallParticipantViewCell *)participantCell
{
    [self showScreenOfPeerId:participantCell.peerId];
}

- (void)cellWantsToChangeZoom:(CallParticipantViewCell *)participantCell showOriginalSize:(BOOL)showOriginalSize
{
    NCPeerConnection *peer = [self peerConnectionForPeerId:participantCell.peerId];
    
    if (peer) {
        [peer setShowRemoteVideoInOriginalSize:showOriginalSize];
    }
}

#pragma mark - UICollectionView Datasource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    [self setCallStateForPeersInCall];
    return [_peersInCall count];
}

- (void)updateParticipantCell:(CallParticipantViewCell *)cell withPeerConnection:(NCPeerConnection *)peerConnection
{
    BOOL isVideoDisabled = peerConnection.isRemoteVideoDisabled;
    
    if (_isAudioOnly || peerConnection.remoteStream == nil) {
        isVideoDisabled = YES;
    }
    
    [cell setVideoView:[_videoRenderersDict objectForKey:peerConnection.peerId]];
    [cell setUserAvatar:[_callController getUserIdFromSessionId:peerConnection.peerId]];
    [cell setDisplayName:peerConnection.peerName];
    [cell setAudioDisabled:peerConnection.isRemoteAudioDisabled];
    [cell setScreenShared:[_screenRenderersDict objectForKey:peerConnection.peerId]];
    [cell setVideoDisabled: isVideoDisabled];
    [cell setShowOriginalSize:peerConnection.showRemoteVideoInOriginalSize];
    [cell.peerNameLabel setAlpha:_isDetailedViewVisible ? 1.0 : 0.0];
    [cell.buttonsContainerView setAlpha:_isDetailedViewVisible ? 1.0 : 0.0];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CallParticipantViewCell *cell = (CallParticipantViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:kCallParticipantCellIdentifier forIndexPath:indexPath];
    NCPeerConnection *peerConnection = [_peersInCall objectAtIndex:indexPath.row];
    
    cell.peerId = peerConnection.peerId;
    cell.actionsDelegate = self;
    [self updateParticipantCell:cell withPeerConnection:peerConnection];
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGRect frame = [NBMPeersFlowLayout frameForWithNumberOfItems:_peersInCall.count
                                                             row:indexPath.row
                                                     contentSize:self.collectionView.frame.size];
    return frame.size;
}

-(void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    CallParticipantViewCell *participantCell = (CallParticipantViewCell *)cell;
    NCPeerConnection *peerConnection = [_peersInCall objectAtIndex:indexPath.row];
    
    [self updateParticipantCell:participantCell withPeerConnection:peerConnection];
}

#pragma mark - Call Controller delegate

- (void)callControllerDidJoinCall:(NCCallController *)callController
{
    [self setCallState:CallStateWaitingParticipants];
}

- (void)callControllerDidFailedJoiningCall:(NCCallController *)callController statusCode:(NSNumber *)statusCode errorReason:(NSString *) errorReason
{
    [self presentJoinError:errorReason];
}

- (void)callControllerDidEndCall:(NCCallController *)callController
{
    [self finishCall];
}

- (void)callController:(NCCallController *)callController peerJoined:(NCPeerConnection *)peer
{
    // Always add a joined peer, even if the peer doesn't publish any streams (yet)
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![self->_peersInCall containsObject:peer]) {
            [self->_peersInCall addObject:peer];
        }
    
        [self.collectionView reloadData];
    });
    
}

- (void)callController:(NCCallController *)callController peerLeft:(NCPeerConnection *)peer
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // Video renderers
        RTCEAGLVideoView *videoRenderer = [self->_videoRenderersDict objectForKey:peer.peerId];
        [[peer.remoteStream.videoTracks firstObject] removeRenderer:videoRenderer];
        [self->_videoRenderersDict removeObjectForKey:peer.peerId];
        // Screen renderers
        RTCEAGLVideoView *screenRenderer = [self->_screenRenderersDict objectForKey:peer.peerId];
        [[peer.remoteStream.videoTracks firstObject] removeRenderer:screenRenderer];
        [self->_screenRenderersDict removeObjectForKey:peer.peerId];
        
        [self->_peersInCall removeObject:peer];
    
        [self.collectionView reloadData];
    });
}

- (void)callController:(NCCallController *)callController didCreateLocalVideoCapturer:(RTCCameraVideoCapturer *)videoCapturer
{
    _localVideoView.captureSession = videoCapturer.captureSession;
    _captureController = [[ARDCaptureController alloc] initWithCapturer:videoCapturer settings:[[NCSettingsController sharedInstance] videoSettingsModel]];
    [_captureController startCapture];
}

- (void)callController:(NCCallController *)callController didAddLocalStream:(RTCMediaStream *)localStream
{
}

- (void)callController:(NCCallController *)callController didRemoveLocalStream:(RTCMediaStream *)localStream
{
}

- (void)callController:(NCCallController *)callController didAddStream:(RTCMediaStream *)remoteStream ofPeer:(NCPeerConnection *)remotePeer
{
    dispatch_async(dispatch_get_main_queue(), ^{
        RTCEAGLVideoView *renderView = [[RTCEAGLVideoView alloc] initWithFrame:CGRectZero];
        renderView.delegate = self;
        RTCVideoTrack *remoteVideoTrack = [remotePeer.remoteStream.videoTracks firstObject];
        [remoteVideoTrack addRenderer:renderView];
        
        if ([remotePeer.roomType isEqualToString:kRoomTypeVideo]) {
            [self->_videoRenderersDict setObject:renderView forKey:remotePeer.peerId];
            
            if (![self->_peersInCall containsObject:remotePeer]) {
                [self->_peersInCall addObject:remotePeer];
            }
        } else if ([remotePeer.roomType isEqualToString:kRoomTypeScreen]) {
            [self->_screenRenderersDict setObject:renderView forKey:remotePeer.peerId];
            [self showScreenOfPeerId:remotePeer.peerId];
        }
        
        [self.collectionView reloadData];
    });
}

- (void)callController:(NCCallController *)callController didRemoveStream:(RTCMediaStream *)remoteStream ofPeer:(NCPeerConnection *)remotePeer
{
    
}

- (void)callController:(NCCallController *)callController iceStatusChanged:(RTCIceConnectionState)state ofPeer:(NCPeerConnection *)peer
{
    if (state == RTCIceConnectionStateClosed) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->_peersInCall removeObject:peer];
            [self.collectionView reloadData];
        });
    } else {
        [self updatePeer:peer block:^(CallParticipantViewCell *cell) {
            [cell setConnectionState:state];
        }];
    }
}

- (void)callController:(NCCallController *)callController didAddDataChannel:(RTCDataChannel *)dataChannel
{
}

- (void)callController:(NCCallController *)callController didReceiveDataChannelMessage:(NSString *)message fromPeer:(NCPeerConnection *)peer
{
    if ([message isEqualToString:@"audioOn"] || [message isEqualToString:@"audioOff"]) {
        [self updatePeer:peer block:^(CallParticipantViewCell *cell) {
            [cell setAudioDisabled:peer.isRemoteAudioDisabled];
        }];
    } else if ([message isEqualToString:@"videoOn"] || [message isEqualToString:@"videoOff"]) {
        if (!_isAudioOnly) {
            [self updatePeer:peer block:^(CallParticipantViewCell *cell) {
                [cell setVideoDisabled:peer.isRemoteVideoDisabled];
            }];
        }
    } else if ([message isEqualToString:@"speaking"] || [message isEqualToString:@"stoppedSpeaking"]) {
        if ([_peersInCall count] > 1) {
            [self updatePeer:peer block:^(CallParticipantViewCell *cell) {
                [cell setSpeaking:peer.isPeerSpeaking];
            }];
        }
    }
}

- (void)callController:(NCCallController *)callController didReceiveNick:(NSString *)nick fromPeer:(NCPeerConnection *)peer
{
    [self updatePeer:peer block:^(CallParticipantViewCell *cell) {
        [cell setDisplayName:nick];
    }];
}

- (void)callController:(NCCallController *)callController didReceiveUnshareScreenFromPeer:(NCPeerConnection *)peer
{
    dispatch_async(dispatch_get_main_queue(), ^{
        RTCEAGLVideoView *screenRenderer = [self->_screenRenderersDict objectForKey:peer.peerId];
        [[peer.remoteStream.videoTracks firstObject] removeRenderer:screenRenderer];
        [self->_screenRenderersDict removeObjectForKey:peer.peerId];
        [self closeScreensharingButtonPressed:self];
    
        [self.collectionView reloadData];
    });
}

- (void)callController:(NCCallController *)callController didReceiveForceMuteActionForPeerId:(NSString *)peerId
{
    if ([peerId isEqualToString:callController.userSessionId]) {
        [self forceMuteAudio];
    } else {
        NSLog(@"Peer was force muted: %@", peerId);
    }
}

- (void)callControllerIsReconnectingCall:(NCCallController *)callController
{
    [self setCallState:CallStateReconnecting];
}

- (void)callControllerWantsToHangUpCall:(NCCallController *)callController
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self hangup];
    });
}

#pragma mark - Screensharing

- (void)showScreenOfPeerId:(NSString *)peerId
{
    dispatch_async(dispatch_get_main_queue(), ^{
        RTCEAGLVideoView *renderView = [self->_screenRenderersDict objectForKey:peerId];
        [self->_screenView removeFromSuperview];
        self->_screenView = nil;
        self->_screenView = renderView;
        self->_screensharingSize = renderView.frame.size;
        [self->_screensharingView addSubview:self->_screenView];
        [self->_screensharingView bringSubviewToFront:self->_closeScreensharingButton];
        [UIView transitionWithView:self->_screensharingView duration:0.4
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{self->_screensharingView.hidden = NO;}
                        completion:nil];
        [self resizeScreensharingView];
    });
    // Enable/Disable detailed view with tap gesture
    // in voice only call when screensharing is enabled
    if (_isAudioOnly) {
        [self addTapGestureForDetailedView];
        [self showDetailedViewWithTimer];
    }
}

- (void)resizeScreensharingView {
    CGRect bounds = _screensharingView.bounds;
    CGSize videoSize = _screensharingSize;
    
    if (videoSize.width > 0 && videoSize.height > 0) {
        // Aspect fill remote video into bounds.
        CGRect remoteVideoFrame = AVMakeRectWithAspectRatioInsideRect(videoSize, bounds);
        CGFloat scale = 1;
        remoteVideoFrame.size.height *= scale;
        remoteVideoFrame.size.width *= scale;
        _screenView.frame = remoteVideoFrame;
        _screenView.center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
    } else {
        _screenView.frame = bounds;
    }
}

- (IBAction)closeScreensharingButtonPressed:(id)sender
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_screenView removeFromSuperview];
        self->_screenView = nil;
        [UIView transitionWithView:self->_screensharingView duration:0.4
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{self->_screensharingView.hidden = YES;}
                        completion:nil];
    });
    // Back to normal voice only UI
    if (_isAudioOnly) {
        [self invalidateDetailedViewTimer];
        [self showDetailedView];
        [self removeTapGestureForDetailedView];
    }
}

#pragma mark - RTCVideoViewDelegate

- (void)videoView:(RTCEAGLVideoView*)videoView didChangeVideoSize:(CGSize)size
{
    dispatch_async(dispatch_get_main_queue(), ^{
        for (RTCEAGLVideoView *rendererView in [self->_videoRenderersDict allValues]) {
            if ([videoView isEqual:rendererView]) {
                rendererView.frame = CGRectMake(0, 0, size.width, size.height);
            }
        }
        for (RTCEAGLVideoView *rendererView in [self->_screenRenderersDict allValues]) {
            if ([videoView isEqual:rendererView]) {
                rendererView.frame = CGRectMake(0, 0, size.width, size.height);
                if ([self->_screenView isEqual:rendererView]) {
                    self->_screensharingSize = rendererView.frame.size;
                    [self resizeScreensharingView];
                }
            }
        }
        [self.collectionView reloadData];
    });
}

#pragma mark - Cell updates

- (NSIndexPath *)indexPathOfPeer:(NCPeerConnection *)peer {
    NSUInteger idx = [_peersInCall indexOfObject:peer];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
    
    return indexPath;
}

- (void)updatePeer:(NCPeerConnection *)peer block:(void(^)(CallParticipantViewCell* cell))block {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSIndexPath *indexPath = [self indexPathOfPeer:peer];
        CallParticipantViewCell *cell = (id)[self.collectionView cellForItemAtIndexPath:indexPath];
        block(cell);
    });
}

- (NCPeerConnection *)peerConnectionForPeerId:(NSString *)peerId {
    for (NCPeerConnection *peerConnection in self->_peersInCall) {
        if ([peerConnection.peerId isEqualToString:peerId]) {
            return peerConnection;
        }
    }
    
    return nil;
}

- (void)showPeersInfo
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray *visibleCells = [self->_collectionView visibleCells];
        for (CallParticipantViewCell *cell in visibleCells) {
            [UIView animateWithDuration:0.3f animations:^{
                [cell.peerNameLabel setAlpha:1.0f];
                [cell.buttonsContainerView setAlpha:1.0f];
                [cell layoutIfNeeded];
            }];
        }
    });
}

- (void)hidePeersInfo
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray *visibleCells = [self->_collectionView visibleCells];
        for (CallParticipantViewCell *cell in visibleCells) {
            [UIView animateWithDuration:0.3f animations:^{
                [cell.peerNameLabel setAlpha:0.0f];
                [cell.buttonsContainerView setAlpha:0.0f];
                [cell layoutIfNeeded];
            }];
        }
    });
}

- (IBAction)toggleChatButton:(id)sender {
}
@end
