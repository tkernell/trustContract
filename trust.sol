pragma solidity ^0.4.10;

/* Tim Kernell - 17 June 2017

 WARNING - THIS CONTRACT IS IN TEST MODE. IT SHOULD NOT BE USED TO STORE REAL ETHER!

 This is an Ethereum smart contract that acts as a trust. A user transfers ether
 to the contract and then adds some people who he or she trusts. Then for a period
 of time the initial user has no control over the funds and the trusted new owners
 have the ability to move the ether as long as every single one of them agrees.
 After a certain amount of time, the original user regains control of the contract
 and can transfer the ether back to his or her own account.
*/

contract Trust {
    address public beneficiary;
    address public initialOwner;
    uint public deadline;
    uint public setupDeadline;
    bool trustClosed = false;
    uint nonce;
    
    struct TrustOwners {
        address splitOwner;
    }
    
    mapping (uint => TrustOwners) public owners;
    mapping (address => mapping (address => uint256)) public votes;
    
    // only initial owner
	modifier onlyInitialOwner {
	    require(msg.sender == initialOwner);
	    _;
	}
	
	modifier onlyTrustOwner {
	    bool isTrustOwner = false;
	    
	    for (uint i = 0; i < nonce; i ++) { 
	        if (owners[i].splitOwner == msg.sender) isTrustOwner = true;
	        
	    }
	    require(isTrustOwner == true);
	    _;
	}
    
    function Trust(
        address futureBeneficiary,
        uint setupDurationInMinutes,
        uint durationInMinutes
        ) {
            beneficiary = futureBeneficiary;
            setupDeadline = setupDurationInMinutes * 1 minutes;
            deadline = setupDeadline + durationInMinutes * 1 minutes;
            initialOwner = msg.sender;
        }
        
    function addOwner(address newOwner) onlyInitialOwner {
            if (now > setupDeadline) throw;
            owners[nonce].splitOwner = newOwner;
            nonce++;
        }
        
    function ownerVoteToSend(address _to, uint256 _value) onlyTrustOwner {
        if (now > deadline) throw;
        if (now < setupDeadline) throw;
        if (_to == 0x0) throw;
        if (this.balance < _value) throw;
        votes[msg.sender][_to] = _value;
    }
    
    
    // Withdraws funds after trust owners unanimously agree
    function withdrawAfterVotes(uint256 _value) onlyTrustOwner {
        if (now > deadline) throw;
        if (now < setupDeadline) throw;
        if (this.balance < _value) throw;
        
        uint8 iter = 1;
        uint256 prevValue = votes[owners[iter].splitOwner][msg.sender];
        uint256 prevValue2;
        
        if (prevValue != _value) {
            throw;
        }
        
        while (iter < nonce) {
            prevValue2 = votes[owners[iter].splitOwner][msg.sender];
            if (prevValue2 != prevValue) {
                throw;
            }
            prevValue = prevValue2;
            iter++;
        }
        
        msg.sender.transfer(prevValue);
    }
    
    function beneficiaryWithdraw() onlyInitialOwner {
        if (now < deadline) throw;
        beneficiary.transfer(this.balance);
    }
    
    function() payable {
    }
    
    // clean up
	function kill() onlyInitialOwner {
	    selfdestruct(initialOwner);
	}
}
	