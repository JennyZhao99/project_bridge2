// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./BridgeToken.sol";

contract Destination is AccessControl {
    bytes32 public constant WARDEN_ROLE = keccak256("BRIDGE_WARDEN_ROLE");
    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");
	mapping( address => address) public underlying_tokens;
	mapping( address => address) public wrapped_tokens;
	address[] public tokens;

	event Creation( address indexed underlying_token, address indexed wrapped_token );
	event Wrap( address indexed underlying_token, address indexed wrapped_token, address indexed to, uint256 amount );
	event Unwrap( address indexed underlying_token, address indexed wrapped_token, address frm, address indexed to, uint256 amount );

    constructor( address admin ) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(CREATOR_ROLE, admin);
        _grantRole(WARDEN_ROLE, admin);
    }

	function wrap(address _underlying_token, address _recipient, uint256 _amount ) public onlyRole(WARDEN_ROLE) {
		//YOUR CODE HERE
        // Verify the underlying token has a registered wrapped token
        require(wrapped_tokens[_underlying_token] != address(0), "Token haven't been registered");
        
        address wrappedToken = wrapped_tokens[_underlying_token];

        // Mint wrapped tokens to recipient
        BridgeToken(wrappedToken).mint(_recipient, _amount);
        
        emit Wrap(_underlying_token, wrappedToken, _recipient, _amount);
	}

	function unwrap(address _wrapped_token, address _recipient, uint256 _amount ) public {
		//YOUR CODE HERE
        // Verify the wrapped token is valid
        address underlyingToken = underlying_tokens[_wrapped_token];
        require(underlyingToken != address(0), "Invalid wrapped token");

        // Burn the wrapped tokens from caller's balance
        BridgeToken(_wrapped_token).burnFrom(msg.sender, _amount);
        
        emit Unwrap(underlyingToken, _wrapped_token, msg.sender, _recipient, _amount);
	}

	function createToken(address _underlying_token, string memory name, string memory symbol ) public onlyRole(CREATOR_ROLE) returns(address) {
		//YOUR CODE HERE
        // Ensure this underlying token doesn't already have a wrapped token
        require(wrapped_tokens[_underlying_token] == address(0), "Token have already been created");

        // Deploy new BridgeToken contract with modified name/symbol
        BridgeToken newToken = new BridgeToken(
            _underlying_token,
            string(abi.encodePacked("Bridge ", name)),
            string(abi.encodePacked(symbol, ".e")),
            address(this)
        );

        // Store the token relationships
        wrapped_tokens[_underlying_token] = address(newToken);
        underlying_tokens[address(newToken)] = _underlying_token;
        tokens.push(address(newToken));
        
        emit Creation(_underlying_token, address(newToken));
        
        return address(newToken);
	}

}


