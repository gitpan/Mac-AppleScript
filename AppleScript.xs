#include <Carbon/Carbon.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* Based on Apple code from
   http://developer.apple.com/qa/qa2001/qa1026.html */

MODULE = Mac::AppleScript		PACKAGE = Mac::AppleScript		

SV *
RunAppleScript(SV *text)
PPCODE:
{
    ComponentInstance theComponent;
    AEDesc scriptTextDesc;
    OSStatus err = noErr;
    OSAID scriptID, resultID;
    
    /* set up locals to a known state */
    theComponent = NULL;
    AECreateDesc(typeNull, NULL, 0, &scriptTextDesc);
    scriptID = kOSANullScript;
    resultID = kOSANullScript;

    /* open the scripting component */
    theComponent = OpenDefaultComponent(kOSAComponentType,
                    typeAppleScript);
    if (theComponent == NULL) { 
      err = paramErr;
      croak("Can't open scripting component");
    }

    /* put the script text into an aedesc */
    err = AECreateDesc(typeChar, SvPV_nolen(text), sv_len(text), &scriptTextDesc);
    if (err == noErr) {
	
      /* compile the script */
      err = OSACompile(theComponent, &scriptTextDesc,
		       kOSAModeNull, &scriptID);
      if (err == noErr) {
	
	/* run the script */
	err = OSAExecute(theComponent, scriptID, kOSANullScript,
			 kOSAModeNull, &resultID);
	
	/* collect the results - if any */
	/* We skip this, as we're not getting results at the moment */
	/*
	  if (resultData != NULL) {
	    AECreateDesc(typeNull, NULL, 0, resultData);
	    if (err == errOSAScriptError) {
	    OSAScriptError(theComponent, kOSAErrorMessage,
	    typeChar, resultData);
	    } else if (err == noErr && resultID != kOSANullScript) {
	    OSADisplay(theComponent, resultID, typeChar,
	  kOSAModeNull, resultData);
	  }
	  }
	  */
	if (err != noErr) {
	  printf("Got an error %i trying to OSAExecute\n", err);
	}
      } else {
	printf("Got an error %i trying to OSACompile\n", err);
      }
    } else {
      printf("Got an error %i trying to AECreateDesc\n", err);
    }
    AEDisposeDesc(&scriptTextDesc);
    if (err) {
      if (scriptID != kOSANullScript) {
	puts("The scriptID was valid");
      }
      if (resultID != kOSANullScript) {
	puts("The resultID was valid");
      }
      if (theComponent != NULL) {
	puts("theComponent was valid");
      }
    }
    if (scriptID != kOSANullScript) OSADispose(theComponent, scriptID);
    if (resultID != kOSANullScript) OSADispose(theComponent, resultID);
    if (theComponent != NULL) CloseComponent(theComponent);
    if (err) {
      printf("Argh! Error %i\n", err);
      XSRETURN_EMPTY;
    }
    XSRETURN_YES;
}
