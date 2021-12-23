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

#import "ChatMessageTableViewCell.h"

#import "MaterialActivityIndicator.h"
#import "SLKUIConstants.h"
#import "UIImageView+AFNetworking.h"
#import "UIImageView+Letters.h"

#import "NCAPIController.h"
#import "NCAppBranding.h"
#import "NCDatabaseManager.h"
#import "NCUtils.h"
#import "QuotedMessageView.h"

@interface ChatMessageTableViewCell ()
@property (nonatomic, strong) UIView *quoteContainerView;
@property (nonatomic, strong) NCChatMessage *message;
@end

@implementation ChatMessageTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [NCAppBranding backgroundColor];
        [self configureSubviews];
    }
    return self;
}

- (void)configureSubviews
{
    _avatarView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, kChatMessageCellAvatarHeight, kChatMessageCellAvatarHeight)];
    _avatarView.translatesAutoresizingMaskIntoConstraints = NO;
    _avatarView.userInteractionEnabled = NO;
    _avatarView.backgroundColor = [NCAppBranding placeholderColor];
    _avatarView.layer.cornerRadius = kChatMessageCellAvatarHeight/2.0;
    _avatarView.layer.masksToBounds = YES;
    _avatarView.contentMode = UIViewContentModeScaleToFill;
    [self.contentView addSubview:_avatarView];
    
    _statusView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kChatCellStatusViewHeight, kChatCellStatusViewHeight)];
    _statusView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_statusView];
    
    _userStatusImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 12, 12)];
    _userStatusImageView.translatesAutoresizingMaskIntoConstraints = NO;
    _userStatusImageView.userInteractionEnabled = NO;
    [self.contentView addSubview:_userStatusImageView];
    
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.dateLabel];
    [self.contentView addSubview:self.bodyTextView];
    
    if ([self.reuseIdentifier isEqualToString:ReplyMessageCellIdentifier]) {
        [self.contentView addSubview:self.quoteContainerView];
        [_quoteContainerView addSubview:self.quotedMessageView];
        
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(quoteTapped:)];
        [self.quoteContainerView addGestureRecognizer:tapRecognizer];
    }
    
    NSDictionary *views = @{@"avatarView": self.avatarView,
                            @"userStatusImageView": self.userStatusImageView,
                            @"statusView": self.statusView,
                            @"titleLabel": self.titleLabel,
                            @"dateLabel": self.dateLabel,
                            @"bodyTextView": self.bodyTextView,
                            @"quoteContainerView": self.quoteContainerView,
                            @"quotedMessageView": self.quotedMessageView
                            };
    
    NSDictionary *metrics = @{@"avatarSize": @(kChatMessageCellAvatarHeight),
                              @"statusSize": @(kChatCellStatusViewHeight),
                              @"padding": @15,
                              @"right": @10,
                              @"left": @5
                              };
    
    if ([self.reuseIdentifier isEqualToString:ChatMessageCellIdentifier]) {
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-right-[avatarView(avatarSize)]-right-[titleLabel]-[dateLabel(40)]-right-|" options:0 metrics:metrics views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-right-[avatarView(avatarSize)]-right-[bodyTextView(>=0)]-right-|" options:0 metrics:metrics views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-padding-[statusView(statusSize)]-padding-[bodyTextView(>=0)]-right-|" options:0 metrics:metrics views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-right-[titleLabel(28)]-left-[bodyTextView(>=0@999)]-left-|" options:0 metrics:metrics views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-right-[dateLabel(28)]-left-[bodyTextView(>=0@999)]-left-|" options:0 metrics:metrics views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-right-[titleLabel(28)]-left-[statusView(statusSize)]-(>=0)-|" options:0 metrics:metrics views:views]];
    } else if ([self.reuseIdentifier isEqualToString:ReplyMessageCellIdentifier]) {
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-right-[avatarView(avatarSize)]-right-[titleLabel]-[dateLabel(40)]-right-|" options:0 metrics:metrics views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-right-[avatarView(avatarSize)]-right-[bodyTextView(>=0)]-right-|" options:0 metrics:metrics views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-padding-[statusView(statusSize)]-padding-[bodyTextView(>=0)]-right-|" options:0 metrics:metrics views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-right-[avatarView(avatarSize)]-right-[quoteContainerView(bodyTextView)]-right-|" options:0 metrics:metrics views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[quotedMessageView(quoteContainerView)]|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-right-[titleLabel(28)]-left-[quoteContainerView]-left-[bodyTextView(>=0@999)]-left-|" options:0 metrics:metrics views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-right-[dateLabel(28)]-left-[quoteContainerView]-left-[bodyTextView(>=0@999)]-left-|" options:0 metrics:metrics views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[quotedMessageView(quoteContainerView)]|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-right-[titleLabel(28)]-left-[quoteContainerView]-left-[statusView(statusSize)]-(>=0)-|" options:0 metrics:metrics views:views]];
    } else if ([self.reuseIdentifier isEqualToString:AutoCompletionCellIdentifier]) {
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-right-[avatarView(avatarSize)]-right-[titleLabel]-right-|" options:0 metrics:metrics views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[titleLabel]|" options:0 metrics:metrics views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-32-[userStatusImageView(12)]-(>=0)-|" options:0 metrics:metrics views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-32-[userStatusImageView(12)]-(>=0)-|" options:0 metrics:metrics views:views]];
        self.backgroundColor = [UIColor groupTableViewBackgroundColor];
        self.titleLabel.textColor = [UIColor darkTextColor];
        
        if (@available(iOS 13.0, *)) {
            self.backgroundColor = [UIColor secondarySystemBackgroundColor];
            self.titleLabel.textColor = [UIColor labelColor];
        }
    }
    
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-right-[avatarView(avatarSize)]-(>=0)-|" options:0 metrics:metrics views:views]];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    CGFloat pointSize = [ChatMessageTableViewCell defaultFontSize];
    
    self.titleLabel.font = [UIFont systemFontOfSize:pointSize];
    self.bodyTextView.font = [UIFont systemFontOfSize:pointSize];
    
    self.titleLabel.text = @"";
    self.bodyTextView.text = @"";
    self.dateLabel.text = @"";
    
    self.quotedMessageView.actorLabel.text = @"";
    self.quotedMessageView.messageLabel.text = @"";
    
    [self.avatarView cancelImageDownloadTask];
    self.avatarView.image = nil;
    self.avatarView.contentMode = UIViewContentModeScaleToFill;
    
    self.userStatusImageView.image = nil;
    self.userStatusImageView.backgroundColor = [UIColor clearColor];
    
    self.message = nil;
    
    self.statusView.hidden = NO;
    [self.statusView.subviews makeObjectsPerformSelector: @selector(removeFromSuperview)];
}

#pragma mark - Getters

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.userInteractionEnabled = NO;
        _titleLabel.numberOfLines = 0;
        _titleLabel.textColor = [UIColor lightGrayColor];
        _titleLabel.font = [UIFont systemFontOfSize:[ChatMessageTableViewCell defaultFontSize]];
        
        if (@available(iOS 13.0, *)) {
            _titleLabel.textColor = [UIColor secondaryLabelColor];
        }
    }
    return _titleLabel;
}

- (UILabel *)dateLabel
{
    if (!_dateLabel) {
        _dateLabel = [UILabel new];
        _dateLabel.textAlignment = NSTextAlignmentRight;
        _dateLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _dateLabel.backgroundColor = [UIColor clearColor];
        _dateLabel.userInteractionEnabled = NO;
        _dateLabel.numberOfLines = 0;
        _dateLabel.textColor = [UIColor lightGrayColor];
        _dateLabel.font = [UIFont systemFontOfSize:12.0];
        
        if (@available(iOS 13.0, *)) {
            _dateLabel.textColor = [UIColor secondaryLabelColor];
        }
    }
    return _dateLabel;
}

- (UIView *)quoteContainerView
{
    if (!_quoteContainerView) {
        _quoteContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
        _quoteContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _quoteContainerView;
}


- (QuotedMessageView *)quotedMessageView
{
    if (!_quotedMessageView) {
        _quotedMessageView = [[QuotedMessageView alloc] init];
        _quotedMessageView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _quotedMessageView;
}

- (MessageBodyTextView *)bodyTextView
{
    if (!_bodyTextView) {
        _bodyTextView = [MessageBodyTextView new];
        _bodyTextView.font = [UIFont systemFontOfSize:[ChatMessageTableViewCell defaultFontSize]];
    }
    return _bodyTextView;
}

- (void)setupForMessage:(NCChatMessage *)message withLastCommonReadMessage:(NSInteger)lastCommonRead
{
    self.titleLabel.text = message.actorDisplayName;
    self.bodyTextView.attributedText = message.parsedMessage;
    self.messageId = message.messageId;
    NSDate *date = [[NSDate alloc] initWithTimeIntervalSince1970:message.timestamp];
    self.dateLabel.text = [NCUtils getTimeFromDate:date];
    TalkAccount *activeAccount = [[NCDatabaseManager sharedInstance] activeAccount];
    ServerCapabilities *serverCapabilities = [[NCDatabaseManager sharedInstance] serverCapabilitiesForAccountId:activeAccount.accountId];
    BOOL shouldShowDeliveryStatus = [[NCDatabaseManager sharedInstance] serverHasTalkCapability:kCapabilityChatReadStatus forAccountId:activeAccount.accountId];
    BOOL shouldShowReadStatus = !serverCapabilities.readStatusPrivacy;
    
    if ([message.actorType isEqualToString:@"guests"]) {
        self.titleLabel.text = ([message.actorDisplayName isEqualToString:@""]) ? NSLocalizedString(@"Guest", nil) : message.actorDisplayName;
        [self setGuestAvatar:message.actorDisplayName];
    } else if ([message.actorType isEqualToString:@"bots"]) {
        if ([message.actorId isEqualToString:@"changelog"]) {
            [self setChangelogAvatar];
        } else {
            [self setBotAvatar];
        }
    } else {
        [self.avatarView setImageWithURLRequest:[[NCAPIController sharedInstance] createAvatarRequestForUser:message.actorId
                                                                                                     andSize:96
                                                                                                usingAccount:activeAccount]
                               placeholderImage:nil success:nil failure:nil];
    }
    
    // This check is just a workaround to fix the issue with the deleted parents returned by the API.
    NCChatMessage *parent = message.parent;
    if (parent.message) {
        self.quotedMessageView.actorLabel.text = ([parent.actorDisplayName isEqualToString:@""]) ? NSLocalizedString(@"Guest", nil) : parent.actorDisplayName;
        self.quotedMessageView.messageLabel.text = parent.parsedMessage.string;
        self.quotedMessageView.highlighted = [parent isMessageFromUser:activeAccount.userId];
    }
    
    if (message.isDeleting) {
        [self setDeliveryState:ChatMessageDeliveryStateDeleting];
    } else if (message.sendingFailed) {
        [self setDeliveryState:ChatMessageDeliveryStateFailed];
    } else if (message.isTemporary){
        [self setDeliveryState:ChatMessageDeliveryStateSending];
    } else if ([message isMessageFromUser:activeAccount.userId] && shouldShowDeliveryStatus) {
        if (lastCommonRead >= message.messageId && shouldShowReadStatus) {
            [self setDeliveryState:ChatMessageDeliveryStateRead];
        } else {
            [self setDeliveryState:ChatMessageDeliveryStateSent];
        }
    }
    
    if ([message.messageType isEqualToString:kMessageTypeCommentDeleted]) {
        self.statusView.hidden = YES;
        self.bodyTextView.textColor = [UIColor colorWithWhite:0 alpha:0.3];
        if (@available(iOS 13.0, *)) {
            self.bodyTextView.textColor = [UIColor tertiaryLabelColor];
        }
    }
    
    self.message = message;
}

- (void)setGuestAvatar:(NSString *)displayName
{
    UIColor *guestAvatarColor = [NCAppBranding placeholderColor];
    NSString *name = ([displayName isEqualToString:@""]) ? @"?" : displayName;
    [_avatarView setImageWithString:name color:guestAvatarColor circular:true];
}

- (void)setBotAvatar
{
    UIColor *guestAvatarColor = [UIColor colorWithRed:0.21 green:0.21 blue:0.21 alpha:1.0]; /*#363636*/
    [_avatarView setImageWithString:@">" color:guestAvatarColor circular:true];
}

- (void)setChangelogAvatar
{
    [_avatarView setImage:[UIImage imageNamed:@"changelog"]];
}

- (void)setDeliveryState:(ChatMessageDeliveryState)state
{
    [self.statusView.subviews makeObjectsPerformSelector: @selector(removeFromSuperview)];
    
    if (state == ChatMessageDeliveryStateSending || state == ChatMessageDeliveryStateDeleting) {
        MDCActivityIndicator *activityIndicator = [[MDCActivityIndicator alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
        activityIndicator.radius = 7.0f;
        activityIndicator.cycleColors = @[UIColor.lightGrayColor];
        [activityIndicator startAnimating];
        [self.statusView addSubview:activityIndicator];
    } else if (state == ChatMessageDeliveryStateFailed) {
        UIImageView *errorView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
        [errorView setImage:[UIImage imageNamed:@"error"]];
        [self.statusView addSubview:errorView];
    } else if (state == ChatMessageDeliveryStateSent) {
        UIImageView *checkView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
        [checkView setImage:[UIImage imageNamed:@"check"]];
        checkView.image = [checkView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [checkView setTintColor:[UIColor lightGrayColor]];
        [self.statusView addSubview:checkView];
    } else if (state == ChatMessageDeliveryStateRead) {
        UIImageView *checkAllView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
        [checkAllView setImage:[UIImage imageNamed:@"check-all"]];
        checkAllView.image = [checkAllView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [checkAllView setTintColor:[UIColor lightGrayColor]];
        [self.statusView addSubview:checkAllView];
    }
}

- (void)setUserStatus:(NSString *)userStatus
{
    UIImage *statusImage = nil;
    if ([userStatus isEqualToString:@"online"]) {
        statusImage = [UIImage imageNamed:@"user-status-online-10"];
    } else if ([userStatus isEqualToString:@"away"]) {
        statusImage = [UIImage imageNamed:@"user-status-away-10"];
    } else if ([userStatus isEqualToString:@"dnd"]) {
        statusImage = [UIImage imageNamed:@"user-status-dnd-10"];
    }
    
    if (statusImage) {
        [_userStatusImageView setImage:statusImage];
        _userStatusImageView.contentMode = UIViewContentModeCenter;
        _userStatusImageView.layer.cornerRadius = 6;
        _userStatusImageView.clipsToBounds = YES;
        _userStatusImageView.backgroundColor = self.backgroundColor;
        if (@available(iOS 14.0, *)) {
            // When a background color is set directly to the cell it seems that there is no background configuration.
            // In this class, even when no background color is set, the background configuration is nil.
            _userStatusImageView.backgroundColor = (self.backgroundColor) ? self.backgroundColor : [[self backgroundConfiguration] backgroundColor];
        }
    }
}

- (void)quoteTapped:(UIGestureRecognizer *)gestureRecognizer {
    if (self.delegate && self.message && self.message.parent) {
        [self.delegate cellWantsToScrollToMessage:self.message.parent];
    }
}

+ (CGFloat)defaultFontSize
{
    CGFloat pointSize = 16.0;
    
//    NSString *contentSizeCategory = [[UIApplication sharedApplication] preferredContentSizeCategory];
//    pointSize += SLKPointSizeDifferenceForCategory(contentSizeCategory);
    
    return pointSize;
}


@end
