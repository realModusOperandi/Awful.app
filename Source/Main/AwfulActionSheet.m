//
//  AwfulActionSheet.m
//  Awful
//
//  Created by Nolan Waite on 2012-10-26.
//  Copyright (c) 2012 Regular Berry Software LLC. All rights reserved.
//

#import "AwfulActionSheet.h"

@interface AwfulActionSheet () <UIActionSheetDelegate>

@property (weak, nonatomic) id <UIActionSheetDelegate> actualDelegate;

@property (readonly, nonatomic) NSMutableDictionary *blocks;

@end

@implementation AwfulActionSheet

- (id)initWithTitle:(NSString *)title
{
    self = [super initWithTitle:title
                       delegate:self
              cancelButtonTitle:nil
         destructiveButtonTitle:nil
              otherButtonTitles:nil];
    if (self) [self commonInit];
    return self;
}

- (void)commonInit
{
    self.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    _blocks = [NSMutableDictionary new];
}

- (void)addButtonWithTitle:(NSString *)title block:(void (^)(void))block
{
    NSInteger i = [self addButtonWithTitle:title];
    if (block) self.blocks[@(i)] = [block copy];
}

- (void)addDestructiveButtonWithTitle:(NSString *)title block:(void (^)(void))block
{
    NSInteger i = [self addButtonWithTitle:title];
    self.destructiveButtonIndex = i;
    if (block) self.blocks[@(i)] = [block copy];
}

- (void)addCancelButtonWithTitle:(NSString *)title
{
    NSInteger i = [self addButtonWithTitle:title];
    self.cancelButtonIndex = i;
}

#pragma mark - NSObject

// -initWithTitle:delegate:cancelButtonTitle:destructiveButtonTitle:otherButtonTitles: isn't the
// designated initializer of UIActionSheet, so it doesn't always get called. But we want our
// designated initializer to always get called.
- (id)init
{
    self = [super init];
    if (self) [self commonInit];
    return self;
}

#pragma mark - UIActionSheet

- (id)initWithTitle:(NSString *)title
    delegate:(id <UIActionSheetDelegate>)delegate
    cancelButtonTitle:(NSString *)cancelButtonTitle
    destructiveButtonTitle:(NSString *)destructiveButtonTitle
    otherButtonTitles:(NSString *)otherButtonTitles, ...
{
    self = [self initWithTitle:title];
    self.delegate = delegate;
    return self;
}

- (id <UIActionSheetDelegate>)delegate
{
    return self.actualDelegate;
}

- (void)setDelegate:(id <UIActionSheetDelegate>)delegate
{
    if (delegate == self) {
        [super setDelegate:delegate];
    } else {
        self.actualDelegate = delegate;
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([self.actualDelegate respondsToSelector:_cmd]) {
        [self.actualDelegate actionSheet:actionSheet clickedButtonAtIndex:buttonIndex];
    }
}

- (void)willPresentActionSheet:(UIActionSheet *)actionSheet
{
    if ([self.actualDelegate respondsToSelector:_cmd]) {
        [self.actualDelegate willPresentActionSheet:actionSheet];
    }
}

- (void)didPresentActionSheet:(UIActionSheet *)actionSheet
{
    if ([self.actualDelegate respondsToSelector:_cmd]) {
        [self.actualDelegate didPresentActionSheet:actionSheet];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if ([self.actualDelegate respondsToSelector:_cmd]) {
        [self.actualDelegate actionSheet:actionSheet willDismissWithButtonIndex:buttonIndex];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    void (^block)(void) = self.blocks[@(buttonIndex)];
    if (block) block();
    if ([self.actualDelegate respondsToSelector:_cmd]) {
        [self.actualDelegate actionSheet:actionSheet didDismissWithButtonIndex:buttonIndex];
    }
}

@end
