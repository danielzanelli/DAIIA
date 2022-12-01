/**
* Name: Assignment3
* Based on the internal skeleton template. 
* Author: Mehdi, Daniel
* Tags: 
*/

model Assignment3


global {
	
	int numberOfQueens <- 12;
	
	bool queens_ok <- false;
	
	bool verbose <- true;

	init {
		int index <- 0;
		create Queen number: numberOfQueens;
	}
}


species Queen skills: [fipa]{
    
	ChessBoard myCell;
	int id; 
	int index <- 0;
	float size <- 30/numberOfQueens;
	Queen predecessor;
	Queen successor;
	
	list reposRequestContents <- ['repostion'];
	bool sendPredReposReqTime <- false;
	
	bool successorInformTime <- false;
	list informSuccessorContents <- ['reposition done'];
	
	list<ChessBoard> predsCell  <- [];
	list previous_poses <- [];
	int num_back_traces <- 0;
	
	init {
		self.id <- int(regex_matches(self.name, '[0-9]+$')[0]);
		do initializeCell;

		if self.id >= 1 {
			self.predecessor <- Queen[self.id - 1];
		}
		if self.id <= numberOfQueens - 2 {
			self.successor <- Queen[self.id + 1];
		}
		if self.id = 0 {
			self.successorInformTime <- true;
		}
	}	
	
	action initializeCell {
		myCell <- ChessBoard[id, id];
	}
	
	aspect base {
        draw circle(size) color: #yellow ;
       	self.location <- myCell.location ;
    }
    
    reflex send_predecessor_request when:(self.id >= 1 and self.sendPredReposReqTime) {
		if verbose {
			write self.name + ': sending request to predecessor, repostion';
		}
		
		do start_conversation to:[self.predecessor] performative:'request' contents:self.reposRequestContents; // protocol:'fipa-inform'
		self.sendPredReposReqTime <- false;
	}
    
    reflex read_successor_request when: !empty(requests) {
		message requestFromSuccessor <- (requests at 0);
		if verbose {
			write self.name + ': received request msg, ' + requestFromSuccessor.contents;
		}
		if requestFromSuccessor.contents[0] = self.reposRequestContents[0] {
			self.num_back_traces <- self.num_back_traces + 1;
			bool repose_bool <- self.repose();
			if repose_bool {
				if verbose {
					write self.name + ': reposed to another available cell -> (' + myCell.grid_x + ', ' + myCell.grid_y + ')';
				}
				self.successorInformTime <- true;
			}
			else {
				self.sendPredReposReqTime <- true;
				if verbose {
					write self.name + ': reposition is not possible';
				}
			}
		}
	}
	
	action updateCell (int col) {
    	myCell <- ChessBoard[col, myCell.grid_y];
    	self.previous_poses <- self.previous_poses + myCell;
    	write self.name + ': my new cell is ' + myCell + ': (' + myCell.grid_x + ', ' + myCell.grid_y + ')';
    	self.location <- myCell.location;
    }
	
	bool isSafe (int col) {
		point target_p <- {col, self.myCell.grid_y};
		loop predCell over: self.predsCell {
			point predCellPoint <- {predCell.grid_x, predCell.grid_y};
			if predCellPoint.x = target_p.x {
				if verbose {
					write self.name + ': can be attacked from same column at ' + target_p;
				}
				return false;
			}
			// Let's see if we hit this target point by other preds in upper left part
			loop while: (predCellPoint.x <= numberOfQueens) and (predCellPoint.y <= numberOfQueens) {
				if predCellPoint = target_p {
					if verbose {
						write (self.name + ': can be attacked from upper left dir at ' + predCellPoint);
					}
					return false;
				}
				predCellPoint <- predCellPoint + {1 , 1};
			}
			// Let's see if we hit this target point by other preds in upper right part
			predCellPoint <- {predCell.grid_x, predCell.grid_y};
			loop while: (predCellPoint.x >= 0) and (predCellPoint.y <= numberOfQueens) {
				if predCellPoint = target_p {
					if verbose {
						write self.name + ': can be attacked from upper right dir at ' + predCellPoint;
					}
					return false;
				}
				predCellPoint <- predCellPoint + {-1 , 1};
//				write self.name + ': predCellPoint now is ' + predCellPoint + ' - target_p now is ' + target_p;
			}
		}
		return true;
	}
	
	bool repose {
		self.predsCell <- [];
		loop q over: Queen.population {
			if q.id < self.id {
				self.predsCell <- self.predsCell + q.myCell;
			}
		}
		int temp <- self.num_back_traces;
		loop col from:0 to:(numberOfQueens-1) {
			if verbose {
					write self.name + ': checking column ' + col;
				}
			if self.isSafe(col:col) {
				if temp = 0 {
					do updateCell(col:col);
					return true;
				}
				temp <- temp - 1;
				if verbose {
					write self.name + ': jump over my previous column ' + col;
				}
			}
		}
		return false;
	}
	
	reflex send_successor_inform when:(self.id <= (numberOfQueens - 2) and self.successorInformTime) {
		if verbose {
			write self.name + ': sending inform to successor , reposition done';
		}
		do start_conversation to:[self.successor] performative:'inform' contents:self.informSuccessorContents; // protocol:'fipa-inform'
		self.successorInformTime <- false;
	}
    
    reflex read_predecessor_inform when: !empty(informs) {
		message informFromPredecessor <- (informs at 0);
		if verbose {
			write self.name + ': received inform msg, ' + informFromPredecessor.contents;
		}
		if informFromPredecessor.contents[0] = self.informSuccessorContents[0] {
			self.num_back_traces <- 0;
			bool repose_bool <- self.repose();
			if repose_bool {
				if verbose {
					write self.name + ': reposed to another available cell -> (' + myCell.grid_x + ', ' + myCell.grid_y + ')';
				}
				self.successorInformTime <- true;
				if self.id > (numberOfQueens - 2) {
					queens_ok <- true;
				}
			}
			else {
				self.sendPredReposReqTime <- true;
				if verbose {
					write self.name + ': reposition is not possible';
				}
			}
		}
	}
}
    
    
grid ChessBoard width: numberOfQueens height: numberOfQueens {
	init{
		write "my column index is:" + grid_x;
		write "my row index is:" + grid_y;
		if( (even(grid_x) and even(grid_y)) or (!even(grid_x) and !even(grid_y)) ){
			color <- #black;
		}
		else {
			color <- #white;
		}
	}
}


experiment gui_experiment type: gui{
	output{
		display ChessBoard{
			grid ChessBoard border: #black ;
			species Queen aspect: base;
		}
	}
}