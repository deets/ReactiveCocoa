//
//  UIBarButtonItem+RACSupport.m
//  ReactiveCocoa
//
//  Created by Kyle LeNeau on 3/27/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "UIBarButtonItem+RACSupport.h"
#import "EXTKeyPathCoding.h"
#import "NSObject+RACPropertySubscribing.h"
#import "RACCommand.h"
#import "RACDisposable.h"
#import "RACSignal+Operations.h"
#import <objc/runtime.h>

@implementation UIBarButtonItem (RACSupport)

- (RACAction *)rac_action {
	return objc_getAssociatedObject(self, @selector(rac_action));
}

- (void)setRac_action:(RACAction *)action {
	objc_setAssociatedObject(self, @selector(rac_action), action, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

	if (action != nil) {
		self.target = action;
		self.action = @selector(execute:);
	}
}

@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

static void *UIControlRACCommandKey = &UIControlRACCommandKey;
static void *UIControlEnabledDisposableKey = &UIControlEnabledDisposableKey;

@implementation UIBarButtonItem (RACSupportDeprecated)

- (RACCommand *)rac_command {
	return objc_getAssociatedObject(self, UIControlRACCommandKey);
}

- (void)setRac_command:(RACCommand *)command {
	objc_setAssociatedObject(self, UIControlRACCommandKey, command, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	
	// Check for stored signal in order to remove it and add a new one
	RACDisposable *disposable = objc_getAssociatedObject(self, UIControlEnabledDisposableKey);
	[disposable dispose];
	
	if (command == nil) return;
	
	disposable = [command.enabled setKeyPath:@keypath(self.enabled) onObject:self];
	objc_setAssociatedObject(self, UIControlEnabledDisposableKey, disposable, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	
	[self rac_hijackActionAndTargetIfNeeded];
}

- (void)rac_hijackActionAndTargetIfNeeded {
	SEL hijackSelector = @selector(rac_commandPerformAction:);
	if (self.target == self && self.action == hijackSelector) return;
	
	if (self.target != nil) NSLog(@"WARNING: UIBarButtonItem.rac_command hijacks the control's existing target and action.");
	
	self.target = self;
	self.action = hijackSelector;
}

- (void)rac_commandPerformAction:(id)sender {
	[self.rac_command execute:sender];
}

@end

#pragma clang diagnostic pop