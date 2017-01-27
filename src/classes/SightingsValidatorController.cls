public class SightingsValidatorController {

	public User validator { get; private set; }
	public String test {
		get{
			if(test == null){
				test = 'initial value';
			}
			return test;
		}
		private set;
	}

	public SightingsValidatorController() {
		validator = [SELECT Default_Sighting_Location__Latitude__s,Default_Sighting_Location__Longitude__s FROM User WHERE Id=:UserInfo.getUserId()];
	}

	public pageReference search() {
    System.debug('***search!');
		 test = 'test';
        return null;
  }
}
