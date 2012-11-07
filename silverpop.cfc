<cfcomponent displayname="silverpop">

	<cffunction name="dump">
		<cfargument name="var">
		<cfdump var="#arguments.var#">
	</cffunction>

	<cffunction name="sendRequest">
		<cfargument name="xml" required="true">
		<cfargument name="jsessionid" required="false" default="#this.jsessionid#">				
		
		<cfset var response = StructNew()>
		
		<cfif this.debugMode eq true>
			<cfset dump(xml)>
		</cfif>	
		
		<cfset response['success'] = false>		
		<cftry>
			<cfhttp url="http://api4.silverpop.com/XMLAPI" method="POST">
				<cfhttpparam type="header" name="Content-Type" value="text/xml;charset=UTF-8">
				<cfhttpparam type="body" value="#arguments.xml#">
				<cfif len(trim(this.jsessionid))>
					<cfhttpparam type="url" name="jsessionid" value="#this.jsessionid#">
				</cfif>
			</cfhttp>
			<cfif isxml(cfhttp.filecontent)>
				<cfset result = ConvertXmlToStruct(cfhttp.filecontent)>
				<cfif result['Body']['RESULT']['SUCCESS'] neq 'TRUE'>
					<cfset result['Body']['RESULT']['Fault'] = result['Body']['Fault']>
					<cfset response['error'] = result['Body']['Fault']>
				<cfelse>	
					<cfset response['success'] = true>
					<cfset response['response'] = result['Body']['RESULT']>
				</cfif>
			<cfelse>
				<cfset response['error'] = "Response is not XML">
			</cfif>
			<cfcatch type="Any">
				<cfset response['error'] = cfcatch.Message>
			</cfcatch>
		</cftry>
		<cfif this.debugMode eq true>
			<cfset dump(response)>
		</cfif>
		<cfreturn response>
	</cffunction>

	<cfscript>
		
	function init(debug) {
		this.jsessionid = "";
		this.organizationid = "";
		this.debugMode = iif(isDefined('arguments.debug') and arguments.debug eq true, 'true', 'false');
		return this;
	}
	
	function login(username, password) {
		var response = "";
		var xml = XmlNew();
	    xml.Envelope = XmlElemNew(xml, "Envelope");
	    xml.Envelope.Body = XmlElemNew(xml, "Body");
	    xml.Envelope.Body.Login = XmlElemNew(xml, "Login");
	    xml.Envelope.Body.Login.USERNAME = XmlElemNew(xml, "USERNAME");
	    xml.Envelope.Body.Login.PASSWORD = XmlElemNew(xml, "PASSWORD");
	    xml.Envelope.Body.Login.USERNAME.XmlText = username;
	    xml.Envelope.Body.Login.PASSWORD.XmlText = password;
		response = this.sendRequest(xml);
		if(response.success eq true) {
			this.jsessionid = response.response.SESSIONID;
			this.organizationid = response.response.ORGANIZATION_ID;
		}
		return response;
	}
	
	function logout() {
	 	var response = "";
		var xml = XmlNew();
	    xml.Envelope = XmlElemNew(xml, "Envelope");
	    xml.Envelope.Body = XmlElemNew(xml, "Body");
	    xml.Envelope.Body.Logout = XmlElemNew(xml, "Logout");
	    response = this.sendRequest(xml);
		if(response.SUCCESS eq 'TRUE') {
			this.jsessionid = "";
		}
		return response;
	}
	
	function GetLists(visibility, list_type) {
			/* 
			*	VISIBILITY:
			*	0 - Private
			*	1 - Shared
			*	
			*	LIST TYPE:
			*	0 - Databases
			*	1 - Queries
			*	2 - Databases, Contact Lists and Queries
			*	5 - Test Lists
			*	6 - Seed Lists
			*	13 - Suppression Lists
			*	15 - Relational Tables
			*	18 - Contact Lists
			*/
		var xml = XmlNew();
	    xml.Envelope = XmlElemNew(xml, "Envelope");
	    xml.Envelope.Body = XmlElemNew(xml, "Body");
	    xml.Envelope.Body.GetLists = XmlElemNew(xml, "GetLists");
	    xml.Envelope.Body.GetLists.VISIBILITY = XmlElemNew(xml, "VISIBILITY");
	    xml.Envelope.Body.GetLists.LIST_TYPE = XmlElemNew(xml, "LIST_TYPE");
	    xml.Envelope.Body.GetLists.VISIBILITY.XmlText = visibility;
	    xml.Envelope.Body.GetLists.LIST_TYPE.XmlText = list_type; 
		return this.sendRequest(xml);
	}
	
	function GetListMetaData(list_id) {
		var xml = XmlNew();
	    xml.Envelope = XmlElemNew(xml, "Envelope");
	    xml.Envelope.Body = XmlElemNew(xml, "Body");
	    xml.Envelope.Body.GetListMetaData = XmlElemNew(xml, "GetListMetaData");
	    xml.Envelope.Body.GetListMetaData.LIST_ID = XmlElemNew(xml, "LIST_ID");
	    xml.Envelope.Body.GetListMetaData.LIST_ID.XmlText = list_id;
		return this.sendRequest(xml);
	}
	
	function AddRecipient(list_id, created_from, data) {
		/*
		* 	CREATED_FROM:
		* 	0 - Imported from a database
		*	1 - Added manually
		*	2 - Opted in
		*	3 - Created from tracking database 
		* 
		* 	DATA: Struct with name/value pairs
		*/
		var i = 1;
		var xml = XmlNew();
	    xml.Envelope = XmlElemNew(xml, "Envelope");
	    xml.Envelope.Body = XmlElemNew(xml, "Body");
	    xml.Envelope.Body.AddRecipient = XmlElemNew(xml, "AddRecipient");
	    xml.Envelope.Body.AddRecipient.LIST_ID = XmlElemNew(xml, "LIST_ID");
	    xml.Envelope.Body.AddRecipient.LIST_ID.XmlText = list_id;
	    xml.Envelope.Body.AddRecipient.CREATED_FROM = XmlElemNew(xml, "CREATED_FROM");
	    xml.Envelope.Body.AddRecipient.CREATED_FROM.XmlText = created_from;
	    i = arrayLen(xml.Envelope.Body.AddRecipient.XmlChildren);
	    for(name in data) {
	    	i = i + 1;
	    	xml.Envelope.Body.AddRecipient.XmlChildren[i] = XmlElemNew(xml, "COLUMN");
	    	xml.Envelope.Body.AddRecipient.XmlChildren[i].NAME = XmlElemNew(xml, "NAME");
	    	xml.Envelope.Body.AddRecipient.XmlChildren[i].VALUE = XmlElemNew(xml, "VALUE");
	    	xml.Envelope.Body.AddRecipient.XmlChildren[i].NAME.XmlText = name;
	    	xml.Envelope.Body.AddRecipient.XmlChildren[i].VALUE.XmlText = data[name];
	    }
		return this.sendRequest(xml);
	}
	
	function UpdateRecipient(list_id, created_from, old_email, data) {
		/*
		* 	CREATED_FROM:
		* 	0 - Imported from a database
		*	1 - Added manually
		*	2 - Opted in
		*	3 - Created from tracking database 
		* 
		* 	DATA: Struct with name/value pairs
		*/
		var i = 1;
		var xml = XmlNew();
	    xml.Envelope = XmlElemNew(xml, "Envelope");
	    xml.Envelope.Body = XmlElemNew(xml, "Body");
	    xml.Envelope.Body.UpdateRecipient = XmlElemNew(xml, "UpdateRecipient");
	    xml.Envelope.Body.UpdateRecipient.LIST_ID = XmlElemNew(xml, "LIST_ID");
	    xml.Envelope.Body.UpdateRecipient.LIST_ID.XmlText = list_id;
	    xml.Envelope.Body.UpdateRecipient.CREATED_FROM = XmlElemNew(xml, "CREATED_FROM");
	    xml.Envelope.Body.UpdateRecipient.CREATED_FROM.XmlText = created_from;
	    xml.Envelope.Body.UpdateRecipient.OLD_EMAIL = XmlElemNew(xml, "OLD_EMAIL");
	    xml.Envelope.Body.UpdateRecipient.OLD_EMAIL.XmlText = old_email;
	    i = arrayLen(xml.Envelope.Body.UpdateRecipient.XmlChildren);
	    for(name in data) {
	    	i = i + 1;
	    	xml.Envelope.Body.UpdateRecipient.XmlChildren[i] = XmlElemNew(xml, "COLUMN");
	    	xml.Envelope.Body.UpdateRecipient.XmlChildren[i].NAME = XmlElemNew(xml, "NAME");
	    	xml.Envelope.Body.UpdateRecipient.XmlChildren[i].VALUE = XmlElemNew(xml, "VALUE");
	    	xml.Envelope.Body.UpdateRecipient.XmlChildren[i].NAME.XmlText = name;
	    	xml.Envelope.Body.UpdateRecipient.XmlChildren[i].VALUE.XmlText = data[name];
	    }
		return this.sendRequest(xml);
	}
	
	function RemoveRecipient(list_id, email) {
		var xml = XmlNew();
	    xml.Envelope = XmlElemNew(xml, "Envelope");
	    xml.Envelope.Body = XmlElemNew(xml, "Body");
	    xml.Envelope.Body.RemoveRecipient = XmlElemNew(xml, "RemoveRecipient");
	    xml.Envelope.Body.RemoveRecipient.LIST_ID = XmlElemNew(xml, "LIST_ID");
	    xml.Envelope.Body.RemoveRecipient.LIST_ID.XmlText = list_id;
	    xml.Envelope.Body.RemoveRecipient.EMAIL = XmlElemNew(xml, "EMAIL");
	    xml.Envelope.Body.RemoveRecipient.EMAIL.XmlText = email;
	    
		return this.sendRequest(xml);
	}
	
	function OptInRecipient(list_id, created_from, old_email) {
		/*
		* 	CREATED_FROM:
		* 	0 - Imported from a database
		*	1 - Added manually
		*	2 - Opted in
		*	3 - Created from tracking database 
		* 
		* 	DATA: Struct with name/value pairs
		*/
		var i = 1;
		var xml = XmlNew();
		var data = StructNew();
		data['OPT_OUT'] = "False";
	    xml.Envelope = XmlElemNew(xml, "Envelope");
	    xml.Envelope.Body = XmlElemNew(xml, "Body");
	    xml.Envelope.Body.UpdateRecipient = XmlElemNew(xml, "UpdateRecipient");
	    xml.Envelope.Body.UpdateRecipient.LIST_ID = XmlElemNew(xml, "LIST_ID");
	    xml.Envelope.Body.UpdateRecipient.LIST_ID.XmlText = list_id;
	    xml.Envelope.Body.UpdateRecipient.CREATED_FROM = XmlElemNew(xml, "CREATED_FROM");
	    xml.Envelope.Body.UpdateRecipient.CREATED_FROM.XmlText = created_from;

    	xml.Envelope.Body.UpdateRecipient.OLD_EMAIL = XmlElemNew(xml, "OLD_EMAIL");
    	xml.Envelope.Body.UpdateRecipient.OLD_EMAIL.XmlText = old_email;
	    xml.Envelope.Body.UpdateRecipient.send_autoreply = XmlElemNew(xml, "SEND_AUTOREPLY");
    	xml.Envelope.Body.UpdateRecipient.send_autoreply.XmlText = "true";
	    i = arrayLen(xml.Envelope.Body.UpdateRecipient.XmlChildren);
	    for(name in data) {
	    	i = i + 1;
	    	xml.Envelope.Body.UpdateRecipient.XmlChildren[i] = XmlElemNew(xml, "COLUMN");
	    	xml.Envelope.Body.UpdateRecipient.XmlChildren[i].NAME = XmlElemNew(xml, "NAME");
	    	xml.Envelope.Body.UpdateRecipient.XmlChildren[i].VALUE = XmlElemNew(xml, "VALUE");
	    	xml.Envelope.Body.UpdateRecipient.XmlChildren[i].NAME.XmlText = name;
	    	xml.Envelope.Body.UpdateRecipient.XmlChildren[i].VALUE.XmlText = data[name];
	    }
//	    xml.Envelope.Body.UpdateRecipient.SNOOZE_SETTINGS = XmlElemNew(xml, "SNOOZE_SETTINGS");
//	    xml.Envelope.Body.UpdateRecipient.SNOOZE_SETTINGS.SNOOZED = XmlElemNew(xml, "SNOOZED");	    
//	    xml.Envelope.Body.UpdateRecipient.SNOOZE_SETTINGS.SNOOZED.XmlText = "false";
//	    xml.Envelope.Body.UpdateRecipient.SNOOZE_SETTINGS.RESUME_SEND_DATE = XmlElemNew(xml, "RESUME_SEND_DATE");	    
//	    xml.Envelope.Body.UpdateRecipient.SNOOZE_SETTINGS.RESUME_SEND_DATE.XmlText = "03/10/2012"; 
		return this.sendRequest(xml);
	}
	
	/*function DoubleOptInRecipient(list_id, email) {
		var i = 1;
		var xml = XmlNew();
		var data = structNew();
		data.email = email;
	    xml.Envelope = XmlElemNew(xml, "Envelope");
	    xml.Envelope.Body = XmlElemNew(xml, "Body");
	    xml.Envelope.Body.DoubleOptInRecipient = XmlElemNew(xml, "DoubleOptInRecipient");
	    xml.Envelope.Body.DoubleOptInRecipient.LIST_ID = XmlElemNew(xml, "LIST_ID");
	    xml.Envelope.Body.DoubleOptInRecipient.LIST_ID.XmlText = list_id;
	    xml.Envelope.Body.DoubleOptInRecipient.SEND_AUTOREPLY = XmlElemNew(xml, "SEND_AUTOREPLY");
    	xml.Envelope.Body.DoubleOptInRecipient.SEND_AUTOREPLY.XmlText = "true";
	    i = arrayLen(xml.Envelope.Body.DoubleOptInRecipient.XmlChildren);	    
	    for(name in data) {
	    	i = i + 1;
	    	xml.Envelope.Body.DoubleOptInRecipient.XmlChildren[i] = XmlElemNew(xml, "COLUMN");
	    	xml.Envelope.Body.DoubleOptInRecipient.XmlChildren[i].NAME = XmlElemNew(xml, "NAME");
	    	xml.Envelope.Body.DoubleOptInRecipient.XmlChildren[i].VALUE = XmlElemNew(xml, "VALUE");
	    	xml.Envelope.Body.DoubleOptInRecipient.XmlChildren[i].NAME.XmlText = name;
	    	xml.Envelope.Body.DoubleOptInRecipient.XmlChildren[i].VALUE.XmlText = data[name];
	    }
		return this.sendRequest(xml);
	}*/
	
	function SendMailing(MailingId, RecipientEmail) {
		var xml = XmlNew();
	    xml.Envelope = XmlElemNew(xml, "Envelope");
	    xml.Envelope.Body = XmlElemNew(xml, "Body");
	    xml.Envelope.Body.SendMailing = XmlElemNew(xml, "SendMailing");
	    xml.Envelope.Body.SendMailing.MailingId = XmlElemNew(xml, "MailingId");
	    xml.Envelope.Body.SendMailing.MailingId.XmlText = MailingId;
	    xml.Envelope.Body.SendMailing.RecipientEmail = XmlElemNew(xml, "RecipientEmail");
	    xml.Envelope.Body.SendMailing.RecipientEmail.XmlText = RecipientEmail;
		return this.sendRequest(xml);
	}
	
	function GetContactMailingDetails(sure_from_code) {
		var xml = XmlNew();
	    xml.Envelope = XmlElemNew(xml, "Envelope");
	    xml.Envelope.Body = XmlElemNew(xml, "Body");
	    xml.Envelope.Body.GetContactMailingDetails = XmlElemNew(xml, "GetContactMailingDetails");
	    xml.Envelope.Body.GetContactMailingDetails.SURE_FROM_CODE = XmlElemNew(xml, "SURE_FROM_CODE");
	    xml.Envelope.Body.GetContactMailingDetails.SURE_FROM_CODE.XmlText = sure_from_code;
	    xml.Envelope.Body.GetContactMailingDetails.ORGANIZATION_ID = XmlElemNew(xml, "ORGANIZATION_ID");
	    xml.Envelope.Body.GetContactMailingDetails.ORGANIZATION_ID.XmlText = this.organizationid;
		return this.sendRequest(xml);
	}
	
	function SelectRecipientData(list_id, email) {
		var xml = XmlNew();
	    xml.Envelope = XmlElemNew(xml, "Envelope");
	    xml.Envelope.Body = XmlElemNew(xml, "Body");
	    xml.Envelope.Body.SelectRecipientData = XmlElemNew(xml, "SelectRecipientData");
	    xml.Envelope.Body.SelectRecipientData.LIST_ID = XmlElemNew(xml, "LIST_ID");
	    xml.Envelope.Body.SelectRecipientData.LIST_ID.XmlText = list_id;
	    xml.Envelope.Body.SelectRecipientData.EMAIL = XmlElemNew(xml, "EMAIL");
	    xml.Envelope.Body.SelectRecipientData.EMAIL.XmlText = email;
		return this.sendRequest(xml);
	}
	
	function GetMailingTemplates(visibility) {
		/* 
			*	VISIBILITY:
			*	0 - Private
			*	1 - Shared
		*/
		var xml = XmlNew();
	    xml.Envelope = XmlElemNew(xml, "Envelope");
	    xml.Envelope.Body = XmlElemNew(xml, "Body");
	    xml.Envelope.Body.GetMailingTemplates = XmlElemNew(xml, "GetMailingTemplates");
	    xml.Envelope.Body.GetMailingTemplates.visibility = XmlElemNew(xml, "VISIBILITY");
	    xml.Envelope.Body.GetMailingTemplates.visibility.XmlText = visibility;
		return this.sendRequest(xml);
	}
	
	function PreviewMailing(MailingId) {
		var xml = XmlNew();
	    xml.Envelope = XmlElemNew(xml, "Envelope");
	    xml.Envelope.Body = XmlElemNew(xml, "Body");
	    xml.Envelope.Body.PreviewMailing = XmlElemNew(xml, "PreviewMailing");
	    xml.Envelope.Body.PreviewMailing.MailingId = XmlElemNew(xml, "MailingId");
	    xml.Envelope.Body.PreviewMailing.MailingId.XmlText = MailingId;
		return this.sendRequest(xml);
	}
	
	function ListRecipientMailings(list_id, recipient_id) {
		var xml = XmlNew();
	    xml.Envelope = XmlElemNew(xml, "Envelope");
	    xml.Envelope.Body = XmlElemNew(xml, "Body");
	    xml.Envelope.Body.ListRecipientMailings = XmlElemNew(xml, "ListRecipientMailings");
	    xml.Envelope.Body.ListRecipientMailings.list_id = XmlElemNew(xml, "LIST_ID");
	    xml.Envelope.Body.ListRecipientMailings.list_id.XmlText = list_id;
	    xml.Envelope.Body.ListRecipientMailings.recipient_id = XmlElemNew(xml, "RECIPIENT_ID");
	    xml.Envelope.Body.ListRecipientMailings.recipient_id.XmlText = recipient_id;
		return this.sendRequest(xml);
	}
	
	function ScheduleMailing(TEMPLATE_ID, LIST_ID, MAILING_NAME, VISIBILITY){
		var xml = XmlNew();
	    xml.Envelope = XmlElemNew(xml, "Envelope");
	    xml.Envelope.Body = XmlElemNew(xml, "Body");
	    xml.Envelope.Body.ScheduleMailing = XmlElemNew(xml, "ScheduleMailing");
	    xml.Envelope.Body.ScheduleMailing.TEMPLATE_ID = XmlElemNew(xml, "TEMPLATE_ID");
	    xml.Envelope.Body.ScheduleMailing.TEMPLATE_ID.XmlText = TEMPLATE_ID;
	    xml.Envelope.Body.ScheduleMailing.LIST_ID = XmlElemNew(xml, "LIST_ID");
	    xml.Envelope.Body.ScheduleMailing.LIST_ID.XmlText = LIST_ID;
	    xml.Envelope.Body.ScheduleMailing.MAILING_NAME = XmlElemNew(xml, "MAILING_NAME");
	    xml.Envelope.Body.ScheduleMailing.MAILING_NAME.XmlText = MAILING_NAME;
	    xml.Envelope.Body.ScheduleMailing.VISIBILITY = XmlElemNew(xml, "VISIBILITY");
	    xml.Envelope.Body.ScheduleMailing.VISIBILITY.XmlText = VISIBILITY;
	    xml.Envelope.Body.ScheduleMailing.SEND_HTML = XmlElemNew(xml, "SEND_HTML");
	    xml.Envelope.Body.ScheduleMailing.SEND_HTML.XmlText = 'true';
	    xml.Envelope.Body.ScheduleMailing.SCHEDULED = XmlElemNew(xml, "SCHEDULED");
	    xml.Envelope.Body.ScheduleMailing.SCHEDULED.XmlText = '01/15/2012 12:00:01 PM';
		return this.sendRequest(xml);
	}
	
	function generateMappingFile(list_id, columns) {
		var xml = XmlNew();
		var c = 1;
	    xml.LIST_IMPORT = XmlElemNew(xml, "LIST_IMPORT");
	    xml.LIST_IMPORT.LIST_INFO = XmlElemNew(xml, "LIST_INFO");
	    xml.LIST_IMPORT.LIST_INFO.ACTION = XmlElemNew(xml, "ACTION");
	    xml.LIST_IMPORT.LIST_INFO.ACTION.XmlText = "ADD_AND_UPDATE";
	    xml.LIST_IMPORT.LIST_INFO.LIST_ID = XmlElemNew(xml, "LIST_ID");
	    xml.LIST_IMPORT.LIST_INFO.LIST_ID.XmlText = arguments.list_id;	    
	    xml.LIST_IMPORT.LIST_INFO.LIST_VISIBILITY = XmlElemNew(xml, "LIST_VISIBILITY");
	    xml.LIST_IMPORT.LIST_INFO.LIST_VISIBILITY.XmlText = "1";
	    xml.LIST_IMPORT.LIST_INFO.FILE_TYPE = XmlElemNew(xml, "FILE_TYPE");
	    xml.LIST_IMPORT.LIST_INFO.FILE_TYPE.XmlText = "0";
	    xml.LIST_IMPORT.LIST_INFO.HASHEADERS = XmlElemNew(xml, "HASHEADERS");
	    xml.LIST_IMPORT.LIST_INFO.HASHEADERS.XmlText = "false";
	 	    
	 	xml.LIST_IMPORT.LIST_INFO.LIST_DATE_FORMAT = XmlElemNew(xml, "LIST_DATE_FORMAT");
	    xml.LIST_IMPORT.LIST_INFO.LIST_DATE_FORMAT.XmlText = "yyyy-mm-dd";    	 	    
	 	    
	    xml.LIST_IMPORT.MAPPING = XmlElemNew(xml, "MAPPING");
	    for (;c lte arraylen(columns); c = c + 1) { 
		    xml.LIST_IMPORT.MAPPING.XmlChildren[c] = XmlElemNew(xml, "COLUMN");
		    xml.LIST_IMPORT.MAPPING.XmlChildren[c].INDEX = XmlElemNew(xml, "INDEX");
		    xml.LIST_IMPORT.MAPPING.XmlChildren[c].INDEX.XmlText = c;
		    xml.LIST_IMPORT.MAPPING.XmlChildren[c].NAME = XmlElemNew(xml, "NAME");
		    xml.LIST_IMPORT.MAPPING.XmlChildren[c].NAME.XmlText = columns[c]['name'];
		    xml.LIST_IMPORT.MAPPING.XmlChildren[c].INCLUDE = XmlElemNew(xml, "INCLUDE");
		    xml.LIST_IMPORT.MAPPING.XmlChildren[c].INCLUDE.XmlText = "true";
	    }
	    return xml;
	}
	
	function importData(mapping_file, source_file) {
		var xml = XmlNew();
	    xml.Envelope = XmlElemNew(xml, "Envelope");
	    xml.Envelope.Body = XmlElemNew(xml, "Body");
	    xml.Envelope.Body.ImportList = XmlElemNew(xml, "ImportList");
	    xml.Envelope.Body.ImportList.MAP_FILE = XmlElemNew(xml, "MAP_FILE");
	    xml.Envelope.Body.ImportList.MAP_FILE.XmlText = mapping_file;
	    xml.Envelope.Body.ImportList.SOURCE_FILE = XmlElemNew(xml, "SOURCE_FILE");
	    xml.Envelope.Body.ImportList.SOURCE_FILE.XmlText = source_file;
		return this.sendRequest(xml);
	}
	
	function AddContactToContactList(contact_list_id, contact_id) {
		var xml = XmlNew();
	    xml.Envelope = XmlElemNew(xml, "Envelope");
	    xml.Envelope.Body = XmlElemNew(xml, "Body");
	    xml.Envelope.Body.AddContactToContactList = XmlElemNew(xml, "AddContactToContactList");
	    xml.Envelope.Body.AddContactToContactList.contact_list_id = XmlElemNew(xml, "CONTACT_LIST_ID");
	    xml.Envelope.Body.AddContactToContactList.contact_list_id.XmlText = contact_list_id;
	    xml.Envelope.Body.AddContactToContactList.contact_id = XmlElemNew(xml, "CONTACT_ID");
	    xml.Envelope.Body.AddContactToContactList.contact_id.XmlText = contact_id;
		return this.sendRequest(xml);
	}
	
	</cfscript>
 
	<cffunction name="ConvertXmlToStruct" access="public" returntype="struct" output="false"
		hint="Parse raw XML response body into ColdFusion structs and arrays and return it.">
		<cfargument name="xmlNode" type="string" required="true" />
		<!---Setup local variables for recurse: --->
		<cfset var i = 0 />
		<cfset var axml = arguments.xmlNode />
		<cfset var astr = StructNew() />
		<cfset var n = "" />
		<cfset var tmpContainer = "" />
		<cfset axml = XmlSearch(XmlParse(arguments.xmlNode),"/node()")>
		<cfset axml = axml[1] />
		<!--- For each children of context node: --->
		<cfloop from="1" to="#arrayLen(axml.XmlChildren)#" index="i">
			<!--- Read XML node name without namespace: --->
			<cfset n = replace(axml.XmlChildren[i].XmlName, axml.XmlChildren[i].XmlNsPrefix&":", "") />
			<!--- If key with that name exists within output struct ... --->
			<cfif structKeyExists(astr, n)>
				<!--- ... and is not an array... --->
				<cfif not isArray(astr[n])>
					<!--- ... get this item into temp variable, ... --->
					<cfset tmpContainer = astr[n] />
					<!--- ... setup array for this item beacuse we have multiple items with same name, ... --->
					<cfset astr[n] = arrayNew(1) />
					<!--- ... and reassing temp item as a first element of new array: --->
					<cfset astr[n][1] = tmpContainer />
				<cfelse>
					<!--- Item is already an array: --->
				</cfif>
				<cfif arrayLen(axml.XmlChildren[i].XmlChildren) gt 0>
					<!--- recurse call: get complex item: --->
					<cfset astr[n][arrayLen(astr[n])+1] = ConvertXmlToStruct(axml.XmlChildren[i], structNew()) />
				<cfelse>
					<!--- else: assign node value as last element of array: --->
					<cfset astr[n][arrayLen(astr[n])+1] = axml.XmlChildren[i].XmlText />
				</cfif>
			<cfelse>
				<!---
					If context child node has child nodes (which means it will be complex type): --->
				<cfif arrayLen(axml.XmlChildren[i].XmlChildren) gt 0>
					<!--- recurse call: get complex item: --->
					<cfset astr[n] = ConvertXmlToStruct(axml.XmlChildren[i], structNew()) />
				<cfelse>
					<!--- else: assign node value as last element of array: --->
					<!--- if there are any attributes on this element--->
					<cfif IsStruct(aXml.XmlChildren[i].XmlAttributes) AND StructCount(aXml.XmlChildren[i].XmlAttributes) GT 0>
						<!--- assign the text --->
						<cfset astr[n] = axml.XmlChildren[i].XmlText />
						<!--- check if there are no attributes with xmlns: , we dont want namespaces to be in the response--->
						<cfset attrib_list = StructKeylist(axml.XmlChildren[i].XmlAttributes) />
						<cfloop from="1" to="#listLen(attrib_list)#" index="attrib">
							<cfif ListgetAt(attrib_list,attrib) CONTAINS "xmlns:">
								<!--- remove any namespace attributes--->
								<cfset Structdelete(axml.XmlChildren[i].XmlAttributes, listgetAt(attrib_list,attrib))>
							</cfif>
						</cfloop>
						<!--- if there are any atributes left, append them to the response--->
						<cfif StructCount(axml.XmlChildren[i].XmlAttributes) GT 0>
							<cfset astr[n&'_attributes'] = axml.XmlChildren[i].XmlAttributes />
						</cfif>
					<cfelse>
						<cfset astr[n] = axml.XmlChildren[i].XmlText />
					</cfif>
				</cfif>
			</cfif>
		</cfloop>
		<!--- return struct: --->
		<cfreturn astr />
	</cffunction>


</cfcomponent>
