//
//  cMessageCell.m
//  chatObjectiveC
//
//  Created by DE4ME on 21.11.2021.
//

#import "cMessageCell.h"
#import "cMessage.h"


@implementation cMessageCell

- (void)setObjectValue:(id)objectValue {
    if ([objectValue isKindOfClass:cMessage.class]){
        cMessage* message = (cMessage*)objectValue;
        switch (message.messageType) {
            case MessageTypeMe:
                self.textField.textColor = [NSColor textColor];
                self.textField.alignment = NSTextAlignmentRight;
                break;
            case MessageTypeOther:
                self.textField.textColor = [NSColor textColor];
                self.textField.alignment = NSTextAlignmentRight;
                break;
            case MessageTypeSystem:
                self.textField.textColor = [NSColor placeholderTextColor];
                self.textField.alignment = NSTextAlignmentCenter;
                break;
        }
        self.textField.stringValue = message.message;
        return;
    }
}

@end
