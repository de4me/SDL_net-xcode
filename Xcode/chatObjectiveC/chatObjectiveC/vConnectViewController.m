//
//  vConnectViewController.m
//  chatObjectiveC
//
//  Created by DE4ME on 21.11.2021.
//

#import "vConnectViewController.h"
#import "vMainViewController.h"
#import "cConnectCredentials.h"


@interface vConnectViewController ()

@property IBOutlet NSTextField* nickTextField;
@property IBOutlet NSTextField* ipTextField;

@end


@implementation vConnectViewController

- (void)viewDidAppear {
    [super viewDidAppear];
    [self.ipTextField becomeFirstResponder];
}

- (IBAction)cancelClick:(id)sender {
    [self.view.window close];
}

-(void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationController isKindOfClass:NSWindowController.class]) {
        NSWindow* window = [(NSWindowController*)(segue.destinationController) window];
        cConnectCredentials* credentials = [cConnectCredentials connectCredentialsWithServer:self.ipTextField.stringValue nick:self.nickTextField.stringValue];
        [window.contentViewController setRepresentedObject:credentials];
        [self.view.window close];
    }
}

@end
