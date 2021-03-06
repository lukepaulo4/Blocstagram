//
//  MediaTableViewCell.m
//  Blocstagram
//
//  Created by Luke Paulo on 7/2/16.
//  Copyright © 2016 Bloc. All rights reserved.
//

#import "MediaTableViewCell.h"
#import "Media.h"
#import "Comment.h"
#import "User.h"
#import "LikeButton.h"
#import "ComposeCommentView.h"

@interface MediaTableViewCell () <UIGestureRecognizerDelegate, ComposeCommentViewDelegate>

@property (nonatomic, strong) UIImageView *mediaImageView;
@property (nonatomic, strong) UILabel *usernameAndCaptionLabel;
@property (nonatomic, strong) UILabel *commentLabel;

//only need to add a property for constraints that you'll want to change later.
@property (nonatomic, strong) NSLayoutConstraint *imageHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *usernameAndCaptionLabelHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *commentLabelHeightConstraint;

@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;

//Create property for LikeButton
@property (nonatomic, strong) LikeButton *likeButton;
@property (nonatomic, strong) ComposeCommentView *commentView;

@property (nonatomic, strong) NSArray *horizontallyRegularConstraints;
@property (nonatomic, strong) NSArray *horizontallyCompactConstraints;

@end

static UIFont *lightFont;
static UIFont *boldFont;
static UIColor *usernameLabelGray;
static UIColor *commentLabelGray;
static UIColor *linkColor;
static NSParagraphStyle *paragraphStyle;

@implementation MediaTableViewCell

//load is a special method which is called once and only once per class. Any class may implement load. If it does, when the class is first used the method will be executed before anything else happens.
//The + instead of the - to start the method indicates a class method, not an instance method.
+ (void)load {
    lightFont = [UIFont fontWithName:@"HelveticaNeue-Thin" size:11];
    boldFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:11];
    usernameLabelGray = [UIColor colorWithRed:0.933 green:0.933 blue:0.933 alpha:1]; /*#eeeeee*/
    commentLabelGray = [UIColor colorWithRed:0.898 green:0.898 blue:0.898 alpha:1]; /*#e5e5e5*/
    linkColor = [UIColor colorWithRed:0.345 green:0.314 blue:0.427 alpha:1]; /*58506d*/
    
    NSMutableParagraphStyle *mutableParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    mutableParagraphStyle.headIndent = 20.0;
    mutableParagraphStyle.firstLineHeadIndent = 20.0;
    mutableParagraphStyle.tailIndent = -20.0;
    mutableParagraphStyle.paragraphSpacingBefore = 5;
    
    paragraphStyle = mutableParagraphStyle;
}

- (NSAttributedString *) usernameAndCaptionString {
    //#1
    CGFloat usernameFontSize = 15;
    
    //#2 - String that says "username caption"
    NSString *baseString = [NSString stringWithFormat:@"%@ %@", self.mediaItem.user.userName, self.mediaItem.caption];
    
    //#3 - Make attributed string, with 'username' bold
    NSMutableAttributedString *mutableUsernameAndCaptionString = [[NSMutableAttributedString alloc] initWithString:baseString attributes:@{NSFontAttributeName : [lightFont fontWithSize:usernameFontSize], NSParagraphStyleAttributeName : paragraphStyle}];
    //#4
    NSRange usernameRange = [baseString rangeOfString:self.mediaItem.user.userName];
    [mutableUsernameAndCaptionString addAttribute:NSFontAttributeName value:[boldFont fontWithSize:usernameFontSize] range:usernameRange];
    [mutableUsernameAndCaptionString addAttribute:NSForegroundColorAttributeName value:linkColor range:usernameRange];
    
    return mutableUsernameAndCaptionString;
}

//This method will generate our comment attributed string
- (NSAttributedString *) commentString {
    NSMutableAttributedString *commentString = [[NSMutableAttributedString alloc] init];
    
    for (Comment *comment in self.mediaItem.comments) {
        //Make string that says "username comment" followed by a line break
        NSString *baseString = [NSString stringWithFormat:@"%@ %@\n", comment.from.userName, comment.text];
        
        //Make atributed string with 'username' bold
        NSMutableAttributedString *oneCommentString = [[NSMutableAttributedString alloc] initWithString:baseString attributes:@{NSFontAttributeName : lightFont, NSParagraphStyleAttributeName : paragraphStyle}];
        
        NSRange usernameRange = [baseString rangeOfString:comment.from.userName];
        [oneCommentString addAttribute:NSFontAttributeName value:boldFont range:usernameRange];
        [oneCommentString addAttribute:NSForegroundColorAttributeName value:linkColor range:usernameRange];
        
        [commentString appendAttributedString:oneCommentString];
        
    }
    return commentString;
}

- (void) layoutSubviews {
    [super layoutSubviews];
    
    if (!self.mediaItem) {
        return;
    }
    
    //Before layout, calculatethe intrinsic size of the labels (the size they 'want' to be), and add 20 to the height for some vertical padding.
    CGSize maxSize = CGSizeMake(CGRectGetWidth(self.bounds), CGFLOAT_MAX);
    CGSize usernameLabelSize = [self.usernameAndCaptionLabel sizeThatFits:maxSize];
    CGSize commentLabelSize = [self.commentLabel sizeThatFits:maxSize];
    
    //Set the height constraints to that intrinsic number set above. This overwrites the previous 100 value set in the lower method that didn't use visual format string. If we didn't add the height constraints to the labels, the intrinsic height without the padding would automatically be used instead.
    self.usernameAndCaptionLabelHeightConstraint.constant = usernameLabelSize.height == 0 ? 0 : usernameLabelSize.height + 20;
    self.commentLabelHeightConstraint.constant = commentLabelSize.height == 0 ? 0 : commentLabelSize.height + 20;
    
    //need to add this, becasue if self.mediaItem.image.size.width is zero, the calc will casue a divide-by-zero, which is illegal and will cause a crash
    if (self.mediaItem.image.size.width > 0 && CGRectGetWidth(self.contentView.bounds) > 0) {
        
        //Update the image height appropriately
        if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
            //It's compact
            self.imageHeightConstraint.constant = self.mediaItem.image.size.height / self.mediaItem.image.size.width * CGRectGetWidth(self.contentView.bounds);
        } else if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
            //It's regular
            self.imageHeightConstraint.constant = 320;
        }
        
        
    } else {
        self.imageHeightConstraint.constant = 0;
    }
    
    //Hide the line between cells
    self.separatorInset = UIEdgeInsetsMake(0, CGRectGetWidth(self.bounds)/2.0, 0, CGRectGetWidth(self.bounds)/2.0);
}

//Update the constraints if the user rotates the device
- (void) traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
        //It's compact
        [self.contentView removeConstraints:self.horizontallyRegularConstraints];
        [self.contentView addConstraints:self.horizontallyCompactConstraints];
    } else if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
        //It's regular
        [self.contentView removeConstraints:self.horizontallyCompactConstraints];
        [self.contentView addConstraints:self.horizontallyRegularConstraints];
    }
}
//We switch which constraint array is used depending on the device orientation. 


+ (CGFloat) heightForMediaItem:(Media *)mediaItem width:(CGFloat)width traitCollection:(UITraitCollection *) traitCollection {
    //Make a cell
    MediaTableViewCell *layoutCell = [[MediaTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"layoutCell"];
    
    layoutCell.mediaItem = mediaItem;
    
    layoutCell.frame = CGRectMake(0, 0, width, CGRectGetHeight(layoutCell.frame));
    
    layoutCell.overrideTraitCollection = traitCollection;
    
    [layoutCell setNeedsLayout];
    [layoutCell layoutIfNeeded];
    
    //Get the actual height required for the cell
    return CGRectGetMaxY(layoutCell.commentView.frame);
}

//Override traitCollection to return overrideTraitCollection if it's been set:
- (UITraitCollection *) traitCollection {
    if (self.overrideTraitCollection) {
        return self.overrideTraitCollection;
    }
    
    return [super traitCollection];
}

- (void) setMediaItem:(Media *)mediaItem {
    _mediaItem = mediaItem;
    self.mediaImageView.image = _mediaItem.image;
    self.usernameAndCaptionLabel.attributedText = [self usernameAndCaptionString];
    self.commentLabel.attributedText = [self commentString];
    
    //Display correct state on the button
    self.likeButton.likeButtonState = mediaItem.likeState;
    
    //When the table cell is created or reused, update the text on the comment view
    self.commentView.text = mediaItem.temporaryComment;
}

//Initialize 3 subviews and add them to self.contentView NOTE** One key difference between subclassing UIView and UITableViewCell, in table cell we don't add subviews to self, we add them to self.contentView
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        //initialize code
        self.mediaImageView = [[UIImageView alloc] init];
        self.mediaImageView.userInteractionEnabled = YES;
        
        self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapFired:)];
        self.tapGestureRecognizer.delegate = self;
        [self.mediaImageView addGestureRecognizer:self.tapGestureRecognizer];
        
        self.longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressFired:)];
        self.longPressGestureRecognizer.delegate = self;
        [self.mediaImageView addGestureRecognizer:self.longPressGestureRecognizer];
        
        self.usernameAndCaptionLabel = [[UILabel alloc] init];
        self.usernameAndCaptionLabel.numberOfLines = 0;
        self.usernameAndCaptionLabel.backgroundColor = usernameLabelGray;
        
        self.commentLabel = [[UILabel alloc] init];
        self.commentLabel.numberOfLines = 0;
        self.commentLabel.backgroundColor = commentLabelGray;
        
        //In initializer: create button, add to hierarchy, update the layout constraints with its location
        self.likeButton = [[LikeButton alloc] init];
        [self.likeButton addTarget:self action:@selector(likePressed:) forControlEvents:UIControlEventTouchUpInside];
        self.likeButton.backgroundColor = usernameLabelGray;
        
        self.commentView = [[ComposeCommentView alloc] init];
        self.commentView.delegate = self;
        
        for (UIView *view in @[self.mediaImageView, self.usernameAndCaptionLabel, self.commentLabel, self.likeButton, self.commentView]) {
            [self.contentView addSubview:view];
            //translatesAtuto... below converts auto-resizing mask into constraints. Set to NO when working with auto-layout
            view.translatesAutoresizingMaskIntoConstraints = NO;
        }
        
        //These first contraints use 'visual format string' which lets you 'draw' a rough outline of your views using only the keyboard characters
        NSDictionary *viewDictionary = NSDictionaryOfVariableBindings(_mediaImageView, _usernameAndCaptionLabel, _commentLabel, _likeButton, _commentView);
        
        //each visual format string should begin with H:(horizontal) or V:(vertical). | represents the superview and the [someName] represents one view.    H:|[_mediaImageView]| (and the next two with usernameAnd.. commentLabel)means that _mediaImageView's leading edge is equal to the content view's leading edge. Their trailing edges are equal too.
        
        //Create two new arrays of auto-layout constraints: one for horizontally regular and the other for horizontally compact environments:
        self.horizontallyCompactConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_mediaImageView]|" options:kNilOptions metrics:nil views:viewDictionary];
        
        NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:_mediaImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:320];
        NSLayoutConstraint *centerConstraint = [NSLayoutConstraint constraintWithItem:self.contentView
                                                                            attribute:NSLayoutAttributeCenterX
                                                                            relatedBy:0
                                                                               toItem:_mediaImageView
                                                                            attribute:NSLayoutAttributeCenterX
                                                                           multiplier:1
                                                                              constant:0];
                                                
        self.horizontallyRegularConstraints = @[widthConstraint, centerConstraint];
        
        //Add one of the constraint arrays depending on the current size class:
        if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
            /* It's compact */
            [self.contentView addConstraints:self.horizontallyCompactConstraints];
        } else if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
            /* It's regular */
            [self.contentView addConstraints:self.horizontallyRegularConstraints];
        }
        
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_usernameAndCaptionLabel][_likeButton(==38)]|" options:NSLayoutFormatAlignAllTop | NSLayoutFormatAlignAllBottom metrics:nil views:viewDictionary]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_commentLabel]|" options:kNilOptions metrics:nil views:viewDictionary]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_commentView]|" options:kNilOptions metrics:nil views:viewDictionary]];
        
        //V:|[_media..][_username...][_comment...] means the three views should be stacked vertically, from the top, with no space in between. Notice there is no | at the end to signify the relation to the superview.
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_mediaImageView][_usernameAndCaptionLabel][_commentLabel][_commentView(==100)]" options:kNilOptions metrics:nil views:viewDictionary]];
        
        //now set the height constraint. These will be added WITHOUT the visual format string. Setting identifier is optional. It has no effect on your app, but can make it easier to debug auto-layout constraints.
        self.imageHeightConstraint = [NSLayoutConstraint constraintWithItem:_mediaImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:100];
        //Literally means "_mediaImageView's height is equal tp (nothing * 1) + 100."
        self.imageHeightConstraint.identifier = @"Image height constraint";
        
        self.usernameAndCaptionLabelHeightConstraint = [NSLayoutConstraint constraintWithItem:_usernameAndCaptionLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:100];
        self.usernameAndCaptionLabelHeightConstraint.identifier = @"Username and caption label height constraint";
        
        self.commentLabelHeightConstraint = [NSLayoutConstraint constraintWithItem:_commentLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:100];
        self.commentLabelHeightConstraint.identifier = @"Comment label height constraint";
        
        [self.contentView addConstraints:@[self.imageHeightConstraint, self.usernameAndCaptionLabelHeightConstraint, self.commentLabelHeightConstraint]];
    }
    return self;
}

#pragma mark = Liking

//When the button is tapped, inform the delegate
- (void) likePressed:(UIButton *)sender {
    [self.delegate cellDidPressLikeButton:self];
}

#pragma mark - Image View

- (void) tapFired:(UITapGestureRecognizer *)sender {
    [self.delegate cell:self didTapImageView:self.mediaImageView];
}

- (void) longPressFired:(UILongPressGestureRecognizer *)sender {
    //If don't check below as shown, the delgate method gets called twice, once when the recognizer begins and again when the user lifts their finger
    if (sender.state == UIGestureRecognizerStateBegan) {
        [self.delegate cell:self didLongPressImageView:self.mediaImageView];
    }
}

#pragma mark - UIGestureRecognizerDelegate

//If the user swipes the cell to show the delete button and then taps on the cell, the expected behavior is to hide the delete button, not to zoom in on the image. To accomplish this, we'll make sure the gesture recognizer only fires while the cell isn't in the editing mode.
- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return self.isEditing == NO;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:NO animated:animated];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:NO animated:animated];

    // Configure the view for the selected state
}

#pragma mark - ComposeCommentViewDelegate

//The cell tells its delegate (the images table controller) that a comment was composed or that the user began editing
- (void) commentViewDidPressCommentButton:(ComposeCommentView *)sender {
    [self.delegate cell:self didComposeComment:self.mediaItem.temporaryComment];
}

//We store the text written so far in temporaryComment. This allows user to scroll up and down the table without losing any partially written comments.
- (void) commentView:(ComposeCommentView *)sender textDidChange:(NSString *)text {
    self.mediaItem.temporaryComment = text;
}

//The cell tells its delegate (the images table controller) that a comment was composed or that the user began editing
- (void) commentViewWillStartEditing:(ComposeCommentView *)sender {
    [self.delegate cellWillStartComposingComment:self];
}

//If another object tells the cell to stopComposingComment, the cell passes that message to the comment view. This will allow the cell's view controller to dismiss the keyboard by passing a message to the comment editor through the cell
- (void) stopComposingComment {
    [self.commentView stopComposingComment];
}

@end
