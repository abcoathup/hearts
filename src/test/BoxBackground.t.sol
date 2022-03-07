// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {DSTest} from "ds-test/test.sol";
import {Vm} from "forge-std/Vm.sol";
import {ERC721PayableMintable} from "../ERC721PayableMintable.sol";
import {BoxBackground} from "../BoxBackground.sol";

contract BoxBackgroundTest is DSTest {
    Vm public constant vm = Vm(HEVM_ADDRESS);
    BoxBackground token;
    
    uint256 constant PAYMENT = 0.0001 ether;
    
    address constant OTHER_ADDRESS = address(1);
    address constant OWNER = address(2);
    address constant PAYMENT_RECIPIENT = address(3);
    address constant TOKEN_HOLDER = address(4);

    string constant TOKEN_NAME = "Token Name";
    

    function setUp() public {
        vm.prank(OWNER);
        token = new BoxBackground();
    }

    function testMetadata() public {
        assertEq(token.name(), "Box");
        assertEq(token.symbol(), "BOX");
    }
    
    /// Mint

    function testMint(uint96 amount) public {
        vm.assume(amount >= PAYMENT);
        token.mint{ value: amount }();

        assertEq(address(token).balance, amount);
        assertEq(token.totalSupply(), 1);
        assertEq(token.balanceOf(address(this)), 1);
        assertEq(token.ownerOf(0), address(this));
    }

    /// Token URI

    function testTokenURI() public {
        token.mint{ value: PAYMENT }();

        token.tokenURI(0);
    }

    function testTokenURINonexistentToken() public {
        vm.expectRevert(ERC721PayableMintable.NonexistentToken.selector);
        token.tokenURI(0);
    }

    /// Render

    function testRender() public {
        token.mint{ value: PAYMENT }();

        emit log_string(token.render(0));
    }
}
