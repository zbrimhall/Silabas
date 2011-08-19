//
//  SScribe.h
//  Silabas
//
//  Created by Cody Brimhall on 9/4/07.
//  Copyright 2007 Cody Brimhall. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SilabasController;

@interface SScribe : NSObject {
	SilabasController *_controller;
	NSDictionary *_grammar;
	NSAttributedString *_originalText;
	NSMutableAttributedString *_renderedText;
	NSCharacterSet *_letters;
	NSCharacterSet *_punctuation;
	NSCharacterSet *_consonants;
	NSCharacterSet *_vowels;
	NSCharacterSet *_nonSyllabicVowels;
	NSDictionary *_identities;
	NSArray *_orthographicClusters;
}

// Initializers
- (id)initWithGrammar:(NSDictionary*)grammar forText:(NSAttributedString*)text sender:(id)sender;

// Accessors
- (NSMutableAttributedString*)renderedText;

// Utility Methods
- (void)processText;
- (NSArray*)wordsInText;
- (void)transcribe:(NSMutableString*)wordBuffer;
- (void)syllabify:(NSMutableString*)wordBuffer;
- (void)renderText:(NSArray*)words;

// Debugging Methods
- (void)setRenderedTextToErrorMessage:(NSString*)message;

@end
