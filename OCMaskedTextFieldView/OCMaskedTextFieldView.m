//
//  OCMaskedTextField.m
//  OCFieldMask
//
//  Created by Ömer Cora on 09/04/14.
//  Copyright (c) 2014 MakaraKukara. All rights reserved.
//

/*
 
 Copyright 2014 Omer Cora
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

#import "OCMaskedTextFieldView.h"

#define MASK_CHAR_NUMERIC      @"#"
#define MASK_CHAR_ALPHANUMERIC @"&"
#define MASK_CHAR_LETTER       @"?"

@interface OCMaskedTextFieldView ()

//mask
@property (nonatomic, copy) NSString *format;

//masking character for blank parts;
@property (nonatomic, copy) NSString *numericBlank;
@property (nonatomic, copy) NSString *alphaNumericBlank;
@property (nonatomic, copy) NSString *letterBlank;

//user input is stored here
@property (nonatomic, copy) NSString *inputText;

//subViews
@property (nonatomic, strong) UITextField *maskedTextField;
@property (nonatomic, strong) UIButton *button;

@end

@implementation OCMaskedTextFieldView
#pragma mark - Init

- (id)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame andMask:@"" showMask:NO];
}

- (id)initWithFrame: (CGRect)frame andMask: (NSString*)maskString
{
    return [self initWithFrame:frame andMask:maskString showMask:NO];
}

- (id)initWithFrame:(CGRect)frame andMask: (NSString*)maskString showMask:(BOOL)showMask
{
    if (self = [super initWithFrame:frame])
    {
        self.format = maskString;
        [self configureViewShowMask:showMask];
        [self autoKeyboardDecision];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        [self configureViewShowMask:NO];
    }
    return self;
}

#pragma mark - Configuration Methods

-(void)configureViewShowMask:(BOOL)showMask
{
    self.showPlaceholder = NO;
    self.inputText = @"";
    
    self.numericBlank      = @"_";
    self.alphaNumericBlank = @"_";
    self.letterBlank       = @"_";
    
    [self configureTextField];
    [self configureButton];
    
    if (showMask)
    {
        [self textField:self.maskedTextField shouldChangeCharactersInRange:NSMakeRange(0, 0) replacementString:@""];
    }
}

-(void)configureTextField
{
    self.maskedTextField = [[UITextField alloc] init];
    [self.maskedTextField setFrame:self.bounds];
    [self addSubview:self.maskedTextField];
    self.maskedTextField.delegate = self;
}

-(void)configureButton
{
    self.button = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.button setBackgroundColor:[UIColor clearColor]];
    [self.button setAlpha:1];
    CGRect rect = self.bounds;
    [self.button setFrame:rect];
    [self.button addTarget:self action:@selector(buttonTouched) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.button];
}

- (void)setMask: (NSString*) maskString
{
    self.format = maskString;
    [self.maskedTextField resignFirstResponder];
    [self autoKeyboardDecision];
    self.maskedTextField.text = @"";
}

- (void)setNumericBlank: (NSString*) numblank alphanumericBlank: (NSString*)alphaNumBlank letterBlank:(NSString*)letBlank
{
    self.numericBlank = numblank;
    self.alphaNumericBlank = alphaNumBlank;
    self.letterBlank = letBlank;
    
    [self.maskedTextField resignFirstResponder];
    self.maskedTextField.text = @"";
}

-(void)buttonTouched
{
    [self.maskedTextField becomeFirstResponder];
}

- (NSString*)getRawInputText
{
    return self.inputText;
}

- (void)
setShowPlaceholder:(BOOL)showPlaceholder
{
	_showPlaceholder = showPlaceholder;
	if (showPlaceholder && !self.maskedTextField.isFirstResponder) {
		self.maskedTextField.text = @"";
	}
}

- (BOOL)isFieldComplete
{
    NSString *speacialChars = [NSString stringWithFormat:@"%@%@%@",MASK_CHAR_ALPHANUMERIC,MASK_CHAR_NUMERIC,MASK_CHAR_LETTER];
    NSCharacterSet *characterSet = [[NSCharacterSet characterSetWithCharactersInString:speacialChars] invertedSet];
    NSString *rawFormat = [self.format stringByTrimmingCharactersInSet:characterSet];
    rawFormat = [rawFormat stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    return rawFormat.length == self.inputText.length;
}


#pragma mark - Text Field Delegate Methods

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self selectTextForInput:textField atRange:NSMakeRange([self calculateCaretLocation], 0)];
    
    if (self.showPlaceholder && self.inputText.length == 0)
    {
        [self textField:self.maskedTextField shouldChangeCharactersInRange:NSMakeRange(0, 0) replacementString:@""];
    }
}

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    if (self.showPlaceholder && self.inputText.length == 0)
    {
        textField.text = @"";
    }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    return [self applySimpleMaskOnTextfield:textField range:range replacementString:string];
}

#pragma mark - Main Masking Operation
- (BOOL)applySimpleMaskOnTextfield:(UITextField*)textField range:(NSRange)range replacementString:(NSString *)string
{
    if ([string isEqualToString:@""])
    {
        //Delete character mode
        self.inputText = [self.inputText substringToIndex:self.inputText.length-(self.inputText.length>0)];
    }
    else
    {
        //Add character mode
        
        //dont allow a longer string to be pasted (is it disabled by the button already)
        if (string.length > 1)
        {
            return NO;
        }
        //return if the input value is different
        if (![self isStringValidForMask:string])
        {
            return NO;
        }
        //add one character
        self.inputText = [self.inputText stringByAppendingString:string];
    }
    
    NSString *finalString = @"";
    int k = 0;
    int caretLocation = -1;
    for (int i = 0; i < self.format.length; i++)
    {
        NSString* formatCharacter = [self.format substringWithRange:NSMakeRange(i, 1)];
        if ([self isSpecialCharacter:formatCharacter])
        {
            if (k < self.inputText.length)
            {
                NSString *inputSubstring = [self.inputText substringWithRange:NSMakeRange(k, 1)];
                k++;
                finalString = [finalString stringByAppendingString:inputSubstring];
            }
            else
            {
                finalString = [finalString stringByAppendingString:[self blankForSpecialCharacter:formatCharacter]];
            }
        }
        else
        {
            finalString = [finalString stringByAppendingString:formatCharacter];
        }
    }
    
    caretLocation = [self calculateCaretLocation];
    
    //set the text manually
    textField.text = finalString;
    [self selectTextForInput:textField atRange:NSMakeRange(caretLocation, 0)];
    
    return NO;
}

- (void)showMask
{
    self.inputText = @"";
    [self textField:self.maskedTextField shouldChangeCharactersInRange:NSMakeRange(0, 0) replacementString:@""];
}

- (void)setPlaceholderMode:(BOOL)mode
{
    //NO by default
    self.showPlaceholder = mode;
}

#pragma mark - Text Field Caret placement
//taken from answer: http://stackoverflow.com/a/11532718
- (void)selectTextForInput:(UITextField *)input atRange:(NSRange)range
{
    UITextPosition *start = [input positionFromPosition:[input beginningOfDocument]
                                                 offset:range.location];
    UITextPosition *end = [input positionFromPosition:start
                                               offset:range.length];
    [input setSelectedTextRange:[input textRangeFromPosition:start toPosition:end]];
}

- (int)calculateCaretLocation
{
    int k = 0;
    int caretLoc = -1;
    for (int i = 0; i < self.format.length; i++)
    {
        NSString* formatCharacter = [self.format substringWithRange:NSMakeRange(i, 1)];
        if ([self isSpecialCharacter:formatCharacter])
        {
            if (k == self.inputText.length)
            {
                caretLoc = i;
            }
            k++;
        }
    }
    if (caretLoc == -1)
    {
        caretLoc = self.format.length;
    }
    return caretLoc;
}

- (int)specialCharacterCountForString:(NSString*)string
{
    int specialCharCount = 0;
    for (int i = 0; i < string.length; i++)
    {
        NSString* formatCharacter = [string substringWithRange:NSMakeRange(i, 1)];
        if ([self isSpecialCharacter:formatCharacter])
        {
            specialCharCount++;
        }
    }
    return specialCharCount;
}

#pragma mark - characterSet Validation

- (BOOL)isStringValidForMask: (NSString*)string
{
    int counter = 0;
    
    //iterate through the format string until the next special character slot to be edited is found
    for (int i = 0; i < self.format.length; i++)
    {
        NSString* formatCharacter = [self.format substringWithRange:NSMakeRange(i, 1)];
        if ([self isSpecialCharacter:formatCharacter])
        {
            //"counter"th special character
            
            //current mask character is to be tested with a valid character set
            if (counter == self.inputText.length)
            {
                NSCharacterSet* charSet = [self characterSetForSpecialCharacter:formatCharacter];
                NSRange r = [string rangeOfCharacterFromSet: charSet];
                
                if (r.location != NSNotFound)
                {
                    //string is valid for this set
                    return YES;
                }
                else
                {
                    return NO;
                }
            }
            counter++;
        }
    }
    return NO;
}

#pragma mark - Special Character (MASK_CHAR_x)

-(BOOL)isSpecialCharacter: (NSString*)specialCharacter
{
    return  [specialCharacter isEqualToString:MASK_CHAR_NUMERIC]      ||
    [specialCharacter isEqualToString:MASK_CHAR_ALPHANUMERIC] ||
    [specialCharacter isEqualToString:MASK_CHAR_LETTER];
}

-(NSString*)blankForSpecialCharacter:(NSString*)specialCharacter
{
    if ([specialCharacter isEqualToString:MASK_CHAR_NUMERIC])
    {
        return self.numericBlank;
    }
    else if ([specialCharacter isEqualToString:MASK_CHAR_ALPHANUMERIC])
    {
        return self.alphaNumericBlank;
    }
    else if ([specialCharacter isEqualToString:MASK_CHAR_LETTER])
    {
        return self.letterBlank;
    }
    else
    {
        return @"_";
    }
}

-(NSCharacterSet*)characterSetForSpecialCharacter: (NSString*)specialCharacter
{
    if ([specialCharacter isEqualToString:MASK_CHAR_NUMERIC])
    {
        return [NSCharacterSet decimalDigitCharacterSet];
    }
    else if ([specialCharacter isEqualToString:MASK_CHAR_ALPHANUMERIC])
    {
        return [NSCharacterSet alphanumericCharacterSet];
    }
    else if ([specialCharacter isEqualToString:MASK_CHAR_LETTER])
    {
        return [NSCharacterSet letterCharacterSet];
    }
    else
    {
        return NO;
    }
}

//code taken from: http://www.informit.com/articles/article.aspx?p=1684315&seqNum=3
#define BUFFER_SIZE 32
- (void)setRawInput:(NSString*)rawInput
{
    int hardIndex = 0;
    NSArray *indexArr = [self getSpecialCharIndexArray];
    
    NSRange range = { 0, BUFFER_SIZE };
    NSUInteger end = [rawInput length];
    while (range.location < end)
    {
        unichar buffer[BUFFER_SIZE];
        if (range.location + range.length > end)
        {
            range.length = end - range.location;
        }
        [rawInput getCharacters: buffer range: range];
        range.location += BUFFER_SIZE;
        for (unsigned i=0 ; i<range.length ; i++)
        {
            
            if (hardIndex >= indexArr.count)
            {
                return;
            }
            
            unichar c = buffer[i];
            NSString* s = [NSString stringWithCharacters:&c length:1];
            
            int loc = [[indexArr objectAtIndex:hardIndex] intValue];
            [self applySimpleMaskOnTextfield:self.maskedTextField range:NSMakeRange(loc, 1) replacementString:s];
            
            hardIndex++;
        }
    }
}

-(NSArray*)getSpecialCharIndexArray
{
    int hardIndex = 0;
    
    NSMutableArray *indexArr = [[NSMutableArray alloc] init];
    NSRange range = { 0, BUFFER_SIZE };
    NSUInteger end = [self.format length];
    while (range.location < end)
    {
        unichar buffer[BUFFER_SIZE];
        if (range.location + range.length > end)
        {
            range.length = end - range.location;
        }
        [self.format getCharacters: buffer range: range];
        range.location += BUFFER_SIZE;
        for (unsigned i=0 ; i<range.length ; i++)
        {
            hardIndex++;
            
            unichar c = buffer[i];
            NSString* s = [NSString stringWithCharacters:&c length:1];
            if ([self isSpecialCharacter:s])
            {
                [indexArr addObject:[NSNumber numberWithInt:hardIndex]];
            }
        }
    }
    return [NSArray arrayWithArray:indexArr];
}

-(void)autoKeyboardDecision
{
    int hardIndex = 0;
    NSRange range = { 0, BUFFER_SIZE };
    NSUInteger end = [self.format length];
    while (range.location < end)
    {
        unichar buffer[BUFFER_SIZE];
        if (range.location + range.length > end)
        {
            range.length = end - range.location;
        }
        [self.format getCharacters: buffer range: range];
        range.location += BUFFER_SIZE;
        for (unsigned i=0 ; i<range.length ; i++)
        {
            hardIndex++;
            
            unichar c = buffer[i];
            NSString* s = [NSString stringWithCharacters:&c length:1];
            if ([s isEqualToString:MASK_CHAR_ALPHANUMERIC] ||
                [s isEqualToString:MASK_CHAR_LETTER])
            {
                return;
            }
        }
    }
    [self.maskedTextField setKeyboardType:UIKeyboardTypeNumberPad];
}

#pragma mark - Clear

-(void)dealloc
{
    self.maskedTextField.delegate = nil;
}

@end
