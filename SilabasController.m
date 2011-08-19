#import "SilabasController.h"
#import "SScribe.h"
#include <stdio.h>

@implementation SilabasController

#pragma mark Actions
- (IBAction)syllabify:(id)sender
{
	[_scribe release];
	_scribe = [[SScribe alloc] initWithGrammar:_grammar forText:[self textForTranscription] sender:self];
	[self displayAttributedString:[_scribe renderedText]];
}

#pragma mark Accessors
- (NSAttributedString*)textForTranscription {
	return [inputTextView textStorage];
}

#pragma mark Utility Methods
- (void)loadGrammar {
	NSString *pathToGrammar = [[NSBundle mainBundle] pathForResource:@"Western Spanish" ofType:@"plist"];
	
	[_grammar release];
	_grammar = [[NSDictionary alloc] initWithContentsOfFile:pathToGrammar];
}

- (void)populateGrammarPopUp {
	NSMutableString *languageName = [NSMutableString stringWithCapacity:18];
	
	if(_grammar != nil) {
		[languageName appendString:[_grammar objectForKey:@"SLanguage"]];
		[languageName appendString:@" ("];
		[languageName appendString:[_grammar objectForKey:@"SDialect"]];
		[languageName appendString:@")"];
		
		[grammarPopUp removeAllItems];
		[grammarPopUp addItemWithTitle:languageName];
	}
	else
		[grammarPopUp addItemWithTitle:@"No Grammars Detected!"];
}

- (void)awakeFromNib
{
	[inputTextView setFont:[NSFont fontWithName:@"Helvetica" size:18.0]];
	[self loadGrammar];
	[self populateGrammarPopUp];
}

- (void)dealloc {
	[_scribe release];
	[_grammar release];
	
	[super dealloc];
}

#pragma mark Debugging Helpers
- (void)displayString:(NSString*)message {
	NSMutableAttributedString *attributedMessage = [[[NSAttributedString alloc] initWithString:message] autorelease];
	
	[self displayAttributedString:attributedMessage];
}

- (void)displayAttributedString:(NSMutableAttributedString*)message {
	NSFont *font = [NSFont fontWithName:@"Helvetica" size:18.0];
	NSDictionary *attributes = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
	
	[message setAttributes:attributes range:NSMakeRange(0, [message length])];
	[[outputTextView textStorage] setAttributedString:message];
}

- (void)appendString:(NSString*)message {
	NSMutableAttributedString *attributedMessage = [[[NSMutableAttributedString alloc] initWithString:message] autorelease];

	[self appendAttributedString:attributedMessage];
}

- (void)appendAttributedString:(NSMutableAttributedString*)message {
	[[outputTextView textStorage] appendAttributedString:message];
}

@end
