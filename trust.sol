pragma solidity ^0.4.10;

/* Tim Kernell - 17 June 2017

 WARNING - THIS CONTRACT IS IN TEST MODE. IT SHOULD NOT BE USED TO STORE REAL ETHER!

 This is an Ethereum smart contract that acts as a trust. A user transfers ether
 to the contract and then adds some people whom he or she trusts. Then for a period
 of time the initial user has no control over the funds and the trusted new owners
 have the ability to move the ether as long as every single one of them agrees.
 After a certain amount of time, the original user regains control of the contract
 and can transfer the ether back to his or her own account.
*/

contract Trust {
    address public beneficiary;			// Gains ownership of any funds left after deadline
    address public initialOwner;		// Creates contract & sets trust owners
    uint public deadline;			// Determines when beneficiary gains control
    uint public setupDeadline;			// Determines when trust owners gain control
    uint public board;				// Keeps track of number of trustees
    
    
	// The 'votes' array handles votes to move funds out of trust & into other account(s)
    mapping (uint => address) public trustees;
    mapping (address => mapping (address => uint256)) public votes;
    
    event TrusteeAdded(address trustee);
    event TrusteeVotedToSendFunds(address trustee, address recipient, uint256 amount);
    event TrusteeWithdrewFunds(address trustee, uint256 amount);
    event BeneficiaryWithdrew(address beneficiary);
    
    // only initial owner
	modifier onlyInitialOwner {
	    require(msg.sender == initialOwner);
	    _;
	}
	
	// Limits activites to only trustees
	modifier onlyTrustee {
	    bool isTrustee = false;
	    
	    for (uint i = 0; i < board; i++) { 
	        if (trustees[i] == msg.sender) isTrustee = true;
	    }
		
	    require(isTrustee == true);
	    _;
	}
	
	modifier duringSetup {
		require(now <= setupDeadline);
		_;
	}
	
	modifier duringTrust {
		require(now >= setupDeadline);
		require(now <= deadline);
		_;
	}
    
    // Setup function
    function Trust(
        address futureBeneficiary,	
        uint setupDurationInMinutes,
        uint durationInMinutes
        ) {
            beneficiary = futureBeneficiary;
            setupDeadline = now + setupDurationInMinutes * 1 minutes;
            deadline = setupDeadline + durationInMinutes * 1 minutes;
            initialOwner = msg.sender;
        }
    
    function addTrustee(address newTrustee) onlyInitialOwner duringSetup {
            trustees[board] = newTrustee;
            board++;
            TrusteeAdded(newTrustee);
        }
        
    function trusteeVoteToSend(address _to, uint256 _value) onlyTrustee duringTrust {
        if (_to == 0x0) throw;
        if (this.balance < _value) throw;
        votes[msg.sender][_to] = _value;
        TrusteeVotedToSendFunds(msg.sender, _to, _value);
    }
   
    // Withdraws funds after trust owners unanimously agree
    function withdrawAfterVotes(uint256 _value) onlyTrustee duringTrust {
        if (this.balance < _value) throw;
        
        uint256 prevValue = votes[trustees[0]][msg.sender];
        uint256 prevValue2;
        
        require(prevValue == _value);
     
		for (uint i=1; i<board; i++) {
			prevValue2 = votes[trustees[i]][msg.sender];
			require(prevValue2 == prevValue);
			prevValue = prevValue2;
		}
        
		for (i=0; i<board; i++) {
			votes[trustees[i]][msg.sender] = 0;
		}
		TrusteeWithdrewFunds(msg.sender, _value);
        msg.sender.transfer(prevValue);
    }
    
    // Beneficiary can withdraw in the end
    function beneficiaryWithdraw() onlyInitialOwner {
        if (now < deadline) throw;
        require(beneficiary.send(this.balance));
        BeneficiaryWithdrew(msg.sender); 
        
    }
    
    function() payable {}
    
    // clean up
    function kill() onlyInitialOwner {
        selfdestruct(initialOwner);
    }
}
	
