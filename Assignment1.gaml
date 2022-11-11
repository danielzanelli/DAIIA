/**
* Name: Assignment1
* Based on the internal empty template. 
* Author: Daniel, Mehdi
* Tags: 
*/


model Assignment1

/* Insert your model definition here */


global {
	int numberOfPeople <- 30;
	int numberOfStores <- 5;
	int distanceThreshold <- 10;
	
	init {
		create Person number:numberOfPeople;
		create Store number:numberOfStores;
				
		// ------------------ START OF THE NEW PART ------------------
		loop counter from: 1 to: numberOfPeople {
        	Person my_agent <- Person[counter - 1];
        	my_agent <- my_agent.setName(counter);
        }
		
		loop counter from: 1 to: numberOfStores {
        	Store my_agent <- Store[counter - 1];
        	my_agent <- my_agent.setName(counter);
        }
        // ------------------ END OF THE NEW PART ------------------   
	}
}

species Person skills: [moving] {

	string personName <- "Undefined";
	int hunger <- 100 update: updateHunger();
	int thirst <- 100 update: updateThirst();
	
	bool infoAvailable <- false;
	
	Store target;
	
	Store foodStores <- [];
	Store drinkStores <- [];
	


	action setName(int num) {
		personName <- "Person " + num;
	}

    int updateHunger{
    	//write "Updating " + personName;
    	if (hunger <= 0){    		
    		//if(infoAvailable and target = nil){
    		//	target <- 
    		//}
    		write "Hunger for person " + personName + " in now " + hunger;
    		return 0;
    	}
    	else{
    		write "Hunger for person " + personName + " in now " + (hunger - 1 );
    		return hunger - 1;
    	}
	}

    int updateThirst{
    	//write "Updating " + personName;
    	if (thirst <= 0){    		
    		//if(infoAvailable and target = nil){
    		//	target <- 
    		//}
    		write "Thirst for person " + personName + " in now " + thirst;
    		return 0;
    	}
    	else{
    		write "Thirst for person " + personName + " in now " + (thirst - 1 );
    		return thirst - 1;
    	}
    }
	
	aspect base {
		rgb agentColor <- rgb("green");
		
		if (hunger = 0 and thirst = 0) {
			agentColor <- rgb("red");
		} else if (thirst = 0) {
			agentColor <- rgb("darkorange");
		} else if (hunger = 0) {
			agentColor <- rgb("purple");
		}
		
		draw circle(1) color: agentColor;
	}
	
	reflex move {
		if(target != nil){
			do goto target: target;
		} else{
			do wander;			
		}
	}
	
	reflex reportApproachingToStore when: !empty(Store at_distance distanceThreshold) {
		ask Store at_distance distanceThreshold {
			if(myself.hunger = 0 and self.hasFood){
				write myself.personName + " has eaten at " + self.storeName ;
				myself.hunger <- 100;
			}else if(myself.thirst = 0 and self.hasDrink){
				write myself.personName + " has drank at " + self.storeName ;
				myself.thirst <- 100;
			}
		}
	}

}


species Store {

	bool hasFood <- false;
	bool hasDrink <- false;	
	string storeName <- "Undefined";
	
	//Initialize with probability 1/3 'has drinks', 1/3 'has food' and 1/3 'has both'
	
	init{		
		if (flip(0.333)){
			hasFood <- true;
			hasDrink <- true;
		}else{
			if flip(0.5){
				hasDrink <- true;
			}else{
				hasFood <- true;				
			}
		}
	}
	

	action setName(int num) {
		storeName <- "Store " + num;
	}

	aspect base {
		rgb agentColor <- rgb("lightgray");
		
		if (hasFood and hasDrink) {
			agentColor <- rgb("darkgreen");
		} else if (hasFood) {
			agentColor <- rgb("skyblue");
		} else if (hasDrink) {
			agentColor <- rgb("lightskyblue");
		}
		
		draw square(2) color: agentColor;
	}
}


experiment myAssignment type:gui {
	output {
		display myDisplay {
			species Person aspect:base;
			species Store aspect:base;
		}
	}
}