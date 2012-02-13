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
	
	
    private String access_token = '';
    String instance_url = '';
    String restEndPoint = '/services/data';
    
	public void retrieveRemoteData(){
		if(login()){
			String qString = 'Select+Description__c,+Model_Number__c,+Part_Number__c+From+Widget__c';
			String res = sendGetCall(qString);
			List<Widget__c> lst = parseData(res);
			
			Database.upsert(lst, Widget__c.Part_Number__c);
		}
		
	}    		
    
	private Boolean login(){
		Boolean retVal = false;
		Http http = new Http(); 
    	HttpRequest req = new Httprequest();
    	HttpResponse res = null;
		String loginURL = 'https://login.salesforce.com/services/oauth2/token';
        
        String client_id = 'database.com Remote Access Consumer Key';
        String clientSecret = 'database.com Remote Access Consumer Secret';
        String uName = 'database.com username';
        String pwd = 'database.com password';
        String securityToken = 'database.com security token';
        
        try{
        	req = new Httprequest();
	        req.setEndpoint(loginUrl);
	        req.setMethod('POST');
	        String postBody = 'grant_type=password&username=' + uName 
	        					+ '&password=' + pwd + securityToken 
	        					+ '&client_id=' + client_id 
	        					+ '&client_secret=' + clientSecret;
	        req.setBody(postBody);            
	        res = http.send(req); 
	        system.debug('res.getBody()=' + res.getBody());
	        if(res.getStatusCode() == 200){
	        	retVal = true;
	        	parseLoginResponse(res);
	        }        
        }
        catch(Exception e){        	
        }
     return retVal;   
	}
	
	private void parseLoginResponse(HttpResponse res){
		JSONParser parser = JSON.createParser(res.getBody());
       	while (parser.nextToken() != null) {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)){ // && (parser.getText() == 'totalPrice')) {
                String curName = parser.getCurrentName();	                
                if(curName == 'instance_url'){
                	parser.nextToken();
                	instance_url = parser.getText();
                } else if(curName == 'access_token'){
                	parser.nextToken();
                	access_token = parser.getText();
                } else{
           			parser.nextToken();
                }
        	}
    	}
	}
	
	private String sendGetCall(String queryString){
		
		String restURI = instance_url + restEndPoint + '/v23.0/query/?q=' + queryString;
		Http http = new Http(); 
    	HttpRequest req = new Httprequest();
    	HttpResponse res = null;
	 
       	req.setMethod('GET');
       	req.setEndpoint(restURI); 
       	req.setHeader('Authorization', 'OAuth ' + access_token);
       	req.setHeader('X-PrettyPrint', '1');
       	res = http.send(req);
       	system.debug('res.getBody()=' + res.getBody());
    	return res.getBody();
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