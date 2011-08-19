//
//  SScribe.m
//  Sílabas
//
//  Created by Cody Brimhall on 9/4/07.
//  Copyright 2007 Cody Brimhall. All rights reserved.
//

#import "SScribe.h"
#import "SilabasController.h"
#include <stdlib.h>
#include <stdio.h>

@implementation SScribe

#pragma mark Initializers
- (id)initWithGrammar:(NSDictionary*)grammar forText:(NSAttributedString*)text sender:(id)sender{
	if((self = [super init]) != nil) {
		_originalText = [[NSAttributedString alloc] initWithAttributedString:text];
		_grammar = [[NSDictionary alloc] initWithDictionary:grammar];
		_consonants = [[NSCharacterSet characterSetWithCharactersInString:[_grammar objectForKey:@"SConsonants"]] retain];
		_vowels = [[NSCharacterSet characterSetWithCharactersInString:[_grammar objectForKey:@"SVowels"]] retain];
		_nonSyllabicVowels = [[NSCharacterSet characterSetWithCharactersInString:[_grammar objectForKey:@"SNonSyllabicVowels"]] retain];
		_letters = [[NSCharacterSet letterCharacterSet] retain];
		_punctuation = [[NSCharacterSet punctuationCharacterSet] retain];
		_identities = [_grammar objectForKey:@"SPhonemicIdentities"];
		_orthographicClusters = [[NSArray alloc] initWithArray:[_grammar objectForKey:@"SOrthographicClusters"]];
		
		[self processText];
	}
	
	return self;
}

#pragma mark Accessors
- (NSMutableAttributedString*)renderedText {
	return _renderedText;
}

#pragma mark Utility Methods
- (void)processText {
	NSArray *words = [self wordsInText];
	NSEnumerator *wordsEnumerator = [words objectEnumerator];
	NSMutableString *word;
	
	while(word = [wordsEnumerator nextObject]) {
		[self transcribe:word];
		[self syllabify:word];
	}
	
	[self renderText:words];
}

- (NSArray*)wordsInText {
	NSMutableArray *wordArray = [NSMutableArray array];
	NSMutableString *wordBuffer;
	BOOL inWord = NO;
	int stringIndex = 0;
	unichar currentCharacter;
	
	for(stringIndex = 0; stringIndex < [_originalText length]; stringIndex++) {
		currentCharacter = [[_originalText string] characterAtIndex:stringIndex];
		
		if([_letters characterIsMember:currentCharacter]) {
			if(![_punctuation characterIsMember:currentCharacter]) {
				if(!inWord) {
					inWord = YES;
					wordBuffer = [NSMutableString stringWithCapacity:10];
					[wordBuffer appendString:@"+"];
				}
				
				[wordBuffer appendString:[NSString stringWithCharacters:&currentCharacter length:1]];
			}
		}
		else {
			if(inWord) {
				[wordBuffer appendString:@"+"];
				[wordArray addObject:wordBuffer];
				
				inWord = NO;
				wordBuffer = nil;
			}
		}
	}
	
	if(wordBuffer != nil) {
		[wordBuffer appendString:@"+"];
		[wordArray addObject:wordBuffer];
	}
	
	return wordArray;
}

- (void)transcribe:(NSMutableString*)wordBuffer {
	NSString *phoneme;
	int wordIndex;
	NSRange firstCharRange;
	NSRange lastCharRange;
	
	_identities = [_grammar objectForKey:@"SPhonemicIdentities"];
	
	if(_identities == nil) {
		[self setRenderedTextToErrorMessage:@"Could not find a phonemic identities dictionary!"];
	}
	else {
		[wordBuffer replaceCharactersInRange:NSMakeRange(0, [wordBuffer length]) withString:[wordBuffer lowercaseString]];
		wordIndex = 0;
		
		while(wordIndex < ([wordBuffer length] - 1)) {
			if((phoneme = [_identities objectForKey:[wordBuffer substringWithRange:NSMakeRange(wordIndex, 2)]]) != nil) {
				[wordBuffer replaceCharactersInRange:NSMakeRange(wordIndex, 2) withString:phoneme];
				wordIndex += [phoneme length];
			}
			else if((phoneme = [_identities objectForKey:[wordBuffer substringWithRange:NSMakeRange(wordIndex, 1)]]) != nil) {
				[wordBuffer replaceCharactersInRange:NSMakeRange(wordIndex, 1) withString:phoneme];
				wordIndex += [phoneme length];
			}
			else {
				wordIndex++;
			}
		}

		firstCharRange = NSMakeRange(0, 1);
		if([[wordBuffer substringWithRange:firstCharRange] isEqualToString:@"+"])
			[wordBuffer deleteCharactersInRange:firstCharRange];
		
		lastCharRange = NSMakeRange([wordBuffer length]-1, 1);
		if([[wordBuffer substringWithRange:lastCharRange] isEqualToString:@"+"])
			[wordBuffer deleteCharactersInRange:lastCharRange];
	}
}

- (void)syllabify:(NSMutableString*)wordBuffer {
	int index = 0;
	int offset = 0;
	int insertionPoint;
	int consonantCount;
	unichar charBuffer;
	NSString *charBuffer2;
	
	// Let's make a state machine, shall we?  Please, O God, have mercy on this coder's soul!
	// Syllabification rules (possibly simplified, but I don't know):
	// VCV		: V-CV
	// VCCV		: V-CCV when CC == {'pl', 'bl', 'tl' (LAm), 'gl', 'fl', 'pr', 'br', 'tr', 'dr', 'gr', 'fr'}
	//			: VC-CV otherwise
	// VCCCV	: VC-CCV when CC == {see above}
	//			: VCC-CV otherwise
	// VCCCCV	: VCC-CCV
	// VV		: VV when V- or -V == {'i', 'u'} <-- unaccented
	//			: V-V otherwise
	//
	// So, without further ado...
	
start:
	consonantCount = 0;
	index += offset;
	offset = 0;

	if(!((index + offset) < [wordBuffer length]))
		goto die;
	
	charBuffer = [wordBuffer characterAtIndex:(index + offset++)];
	charBuffer2 = [wordBuffer substringWithRange:NSMakeRange(index+offset-1,1)];
	
	if([_vowels characterIsMember:charBuffer])
		goto v1;
	
	goto start;

v1:
	if(!((index + offset) < [wordBuffer length]))
		goto die;
	
	charBuffer = [wordBuffer characterAtIndex:(index + offset++)];
	charBuffer2 = [wordBuffer substringWithRange:NSMakeRange(index+offset-1,1)];
	
	if([_vowels characterIsMember:charBuffer])
		goto finish;
	else if([_consonants characterIsMember:charBuffer]) {
		if(consonantCount++ < 4)
			goto v1;
	}
	
	goto start;
	
finish:
	switch(offset) {
		case 2:	// VV
			if([_nonSyllabicVowels characterIsMember:[wordBuffer characterAtIndex:index]] || [_nonSyllabicVowels characterIsMember:[wordBuffer characterAtIndex:index+1]]) {
				insertionPoint = -1;
				index--;
			}
			else
				insertionPoint = (index + 1);
				
			break;
		case 3: // VCV
			insertionPoint = (index + 1);
			break;
		case 4: // VCCV
			if([_orthographicClusters containsObject:[wordBuffer substringWithRange:NSMakeRange(index+1, 2)]])
				insertionPoint = (index + 1);
			else
				insertionPoint = (index + 2);
			break;
		case 5: // VCCCV
			if([_orthographicClusters containsObject:[wordBuffer substringWithRange:NSMakeRange(index+2, 2)]])
				insertionPoint = (index + 2);
			else
				insertionPoint = (index + 3);
			break;
		case 6: // VCCCCV
			insertionPoint = (index + 3);
			break;
	}
	
	if(insertionPoint >= 0)
		[wordBuffer insertString:@"-" atIndex:insertionPoint];
	
//	index++; // Bump the index ahead because we added a character
	goto start;
	
die:
	index = 0;  // Pointless statement so that we can end the method by dying.
}

- (void)renderText:(NSArray*)words {
	NSMutableString *stringBuffer = [NSMutableString stringWithCapacity:255];	// Arbitrary figure
	NSEnumerator *wordEnumerator = [words objectEnumerator];
	NSString *word;
	
	[stringBuffer appendString:@"["];
	
	while(word = [wordEnumerator nextObject]) {
		[stringBuffer appendString:[word stringByAppendingString:@" "]];
	}
	
	// The above loop leaves a trailing space, which we want to replace with the closing "]"
	[stringBuffer replaceCharactersInRange:NSMakeRange([stringBuffer length]-1, 1) withString:@"]"];
	
	[_renderedText release];
	_renderedText = [[NSMutableAttributedString alloc] initWithString:stringBuffer];
}

#pragma mark Deconstructor
- (void)dealloc {
	[_originalText release];
	[_renderedText release];
	[_grammar release];
	[_consonants release];
	[_vowels release];
	[_nonSyllabicVowels release];
	[_letters release];
	[_punctuation release];
	[_orthographicClusters release];
	
	[super dealloc];
}

#pragma mark Debugging Methods
- (void)setRenderedTextToErrorMessage:(NSString*)message {
	NSMutableString *messageBuffer = [NSMutableString stringWithCapacity:255];
	
	[messageBuffer appendString:@"*** "];
	[messageBuffer appendString:message];
	[messageBuffer appendString:@" ***"];
	
	[_renderedText release];
	_renderedText = [[NSMutableAttributedString alloc] initWithString:message];
}

@end
