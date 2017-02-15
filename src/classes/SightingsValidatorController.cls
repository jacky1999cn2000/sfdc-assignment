public with sharing class SightingsValidatorController {
	/* current user */
	public User validator { get; set; }

	/* properties used for pagination */
	public Integer noOfRecords{ get; set; }
  public Integer size{ get; set; }

	/* properties used for SOQL query */
	public String radius { get; set; }
	public Decimal latitude { get; set; }
	public Decimal longitude { get; set; }
	public String specialization { get; set; }

	/* comma delimited sighting ids for approve/reject (passed in by javascript function) */
	public String sightingIds { get; set; }
	/* indicate validate type (approve, reject, or reset) */
	public String validateType { get; set; }

	/* StandardSetController for pagination */
	public ApexPages.StandardSetController setCon {
		get{
			if(setCon == null){
				if(validUser){
					size = 5;
					String queryString = 'SELECT Id,CreatedById,CreatedBy.Name,Date__c,Location__c,Location__Latitude__s,Location__Longitude__s,Number_of_Animals__c,Species__r.Name,Species__r.Rarity__c,Validation_Status__c FROM Sighting__c WHERE Validation_Status__c = \'Not Validated\' AND DISTANCE(Location__c, GEOLOCATION(' + latitude + ',' + longitude + '), \'mi\') < ' + radius + ' ORDER BY Date__c ASC, Species__r.Name ASC';
					setCon = new ApexPages.StandardSetController(Database.getQueryLocator(queryString));
					setCon.setPageSize(size);
					noOfRecords = setCon.getResultSize();
				}
			}

			return setCon;
		}
		set;
	}

	/*
	* indicate whether the current user is valid:
	* 1. user should have valid values for Location__c and Validation_Specialization__c
	* 2. if user's profile is 'Data Validator', then user should join at least one 'Validator Public Groups'
	*
	* P.S. this is not required by the assignment, but added it here for better user experience
	* P.S.S. more robust code should also check whether the public group matches user's validataion specialization,
	* but it's not in the scope of this assignment
	*/
	public Boolean validUser {
		get {
			if(validUser == null){
				if(latitude == null || longitude == null){
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Current user\'s \'Default Sighting Location\' field is not valid, please check again.'));
					validUser = false;
				}else if(specialization == null){
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Current user has not selected a value for \'Validator Specialization\' field, please check again.'));
					validUser = false;
				}else{
					List<Profile> profileList = [SELECT Id FROM Profile WHERE Name = 'Data Validator'];
					List<GroupMember> groupMemberList = [SELECT Group.Name, Group.Type, UserOrGroupId FROM GroupMember WHERE UserOrGroupId = :UserInfo.getUserId() AND Group.Type = 'Regular' AND Group.Name LIKE '%Validators%'];
					if(profileList.size() == 1 && profileList[0].Id == UserInfo.getProfileId() && groupMemberList.size() == 0){
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Current user has \'Data Validator\' profile but does not belong to any \'Validator Public Group\', are you sure about it?'));
						validUser = false;
					}else{
						validUser = true;
					}
				}
			}

			return validUser;
		}
		set;
	}

	/*
		retrieve current user and initialize some properties
	*/
	public SightingsValidatorController() {
		validator = [SELECT Default_Sighting_Location__Latitude__s,Default_Sighting_Location__Longitude__s,Validation_Specialization__c FROM User WHERE Id=:UserInfo.getUserId()];
		radius = '150';
		latitude = validator.Default_Sighting_Location__Latitude__s;
		longitude = validator.Default_Sighting_Location__Longitude__s;
		specialization = validator.Validation_Specialization__c;
	}

	/*
		get function for sightings
	*/
	public List<Sighting__c> getSightings(){
		List<Sighting__c> sightingList = new List<Sighting__c>();
		if(setCon != null){
			for(Sighting__c sighting : (List<Sighting__c>)setCon.getRecords())
				sightingList.add(sighting);
		}

		return sightingList;
	}

	/*
		get function for options
	*/
	public List<SelectOption> getOptions() {
    List<SelectOption> options = new List<SelectOption>();
    options.add(new SelectOption('100','100 km'));
    options.add(new SelectOption('150','150 km'));
    options.add(new SelectOption('200','200 km'));
    return options;
  }


	/*
		re-query sighting records based on current radius, latitude, and longitude properties
	*/
	public pageReference search() {
		setCon = null;
    getSightings();
    setCon.setPageNumber(1);
    return null;
  }

	/*
		handle approve, reject and reset actions
	*/
	public pageReference validate(){
		// only do the following for approve or reject
		if(validateType.toUpperCase() == 'APPROVE' || validateType.toUpperCase() == 'REJECT'){

			if(String.isEmpty(sightingIds)){
				// if no records being selected, then notify the user
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'You haven\'t selected any records.'));
			}else{
				/*
					1. retrieve sightings based on ids
					2. update Validation_Status__c field
					3. partial save updated records
					4. display appropriate messages
				*/
				List<Id> sightingIdList = sightingIds.split(',');
				List<Sighting__c> sightingToUpdateList = [SELECT Id, Validation_Status__c FROM Sighting__c WHERE Id IN :sightingIdList];

				for(Sighting__c sighting : sightingToUpdateList){
					if(validateType.toUpperCase() == 'APPROVE'){
						sighting.Validation_Status__c = 'Approved';
					}else{
						sighting.Validation_Status__c = 'Rejected';
					}
				}

				Boolean allRecordsUpdatedSuccessfully = true;
				String message = '';

				Database.SaveResult[] srList = Database.update(sightingToUpdateList, false);

				for(Database.SaveResult sr : srList){
			    if(!sr.isSuccess()){
						allRecordsUpdatedSuccessfully = false;
						for(Database.Error err : sr.getErrors()) {
							message = err.getMessage();
			      }
			    }
				}

				if(allRecordsUpdatedSuccessfully){
					message = validateType.toUpperCase() == 'APPROVE' ? 'All selected records successfully approved.' : 'All selected records successfully rejected.';
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, message));
				}else{
					message = 'Some of the records did not save.' + message + '.Please try again.';
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));
				}
			}
		}

		setCon = null;
		getSightings();
		setCon.setPageNumber(1);

		return null;
	}
}
