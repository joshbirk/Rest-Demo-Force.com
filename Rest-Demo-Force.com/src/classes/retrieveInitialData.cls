/*
Copyright (c) 2012, Neal Hobert.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, 
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, 
    this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, 
    this list of conditions and the following disclaimer in the documentation 
    and/or other materials provided with the distribution.
    * Neither the name of the salesforce.com, Inc. nor the names of its contributors 
    may be used to endorse or promote products derived from this software 
    without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED 
OF THE POSSIBILITY OF SUCH DAMAGE.

*/

public with sharing class retrieveInitialData {

	public void retrieveRemoteData(){
		RestUtility ru = new RestUtility();
		if(ru.login('remoteAccessConsuberId', 'remoteAccessClientSecret', 'dbUserName', 'password', 'securityToken')){
			String qString = 'Select+Description__c,+Model_Number__c,+Part_Number__c+From+Widget__c';
			String res = ru.getSOQLQuery(qString);
			List<Widget__c> lst = parseData(res);
			Database.upsert(lst, Widget__c.Part_Number__c);
		}
		
	}    		
    
    private List<Widget__c> parseData(String resBody){
		List<Widget__c> lst = new List<Widget__c>();
		JSONParser parser = JSON.createParser(resBody);
    	while (parser.nextToken() != null) {   
	        if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
	            while (parser.nextToken() != null) {
	                // Advance to the start object marker to 
	                //  find next Widget__c. 
	                if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
	                    // Read entire invoice object, including its array of line items. 
	                    Widget__c wgt = (Widget__c)parser.readValueAs(Widget__c.class);
	                    parser.skipChildren();
	                    lst.add(wgt);
	                }
	            }
	        }
	    }
		return lst;
	}
    
}