// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "ds-test/test.sol";
import "forge-std/stdlib.sol";
import "forge-std/Vm.sol";
import "../Box.sol";

contract BoxTest is DSTest {
    Vm public constant vm = Vm(HEVM_ADDRESS);
    Box token;
    
    uint256 constant PAYMENT = 0.001 ether;
    
    address constant OTHER_ADDRESS = address(1);
    address constant OWNER = address(2);
    address constant PAYMENT_RECIPIENT = address(3);  

    function setUp() public {
        vm.prank(OWNER);
        token = new Box();
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

    function testMintWithInsufficientPayment(uint96 amount) public {
        vm.assume(amount < PAYMENT);

        vm.expectRevert(Box.InsufficientPayment.selector);
        token.mint{ value: amount }();

        assertEq(address(token).balance, 0 ether);
    }

    function testMintWithinCap() public {
        for (uint256 index = 0; index < token.SUPPLY_CAP(); index++) {
            token.mint{ value: PAYMENT }();
        }

        assertEq(token.totalSupply(), token.SUPPLY_CAP());
    }

    function testMintOverCap() public {
        for (uint256 index = 0; index < token.SUPPLY_CAP(); index++) {
            token.mint{ value: PAYMENT }();
        }

        vm.expectRevert(Box.SupplyCapReached.selector);
        token.mint{ value: PAYMENT }();

        assertEq(token.totalSupply(), token.SUPPLY_CAP());
    }

    function testOwnerMint() public {
        vm.prank(OWNER);
        token.ownerMint();

        assertEq(token.totalSupply(), 88);
        assertEq(token.ownerOf(0), OWNER);
    }

    function testOwnerMintWhenNotOwner() public {
        vm.prank(OTHER_ADDRESS);
        vm.expectRevert("Ownable: caller is not the owner");
        token.ownerMint();
    }

    function testOwnerMintWhenOwnerAlreadyMinted() public {
        vm.prank(OWNER);
        token.ownerMint();

        vm.prank(OWNER);
        vm.expectRevert(Box.OwnerAlreadyMinted.selector);
        token.ownerMint();
    }

    function testOwnerMintNearCap() public {
        for (uint256 index = 0; index < token.SUPPLY_CAP() - 1; index++) {
            token.mint{ value: PAYMENT }();
        }

        vm.prank(OWNER);
        token.ownerMint();

        assertEq(token.totalSupply(), token.SUPPLY_CAP());
        assertEq(token.ownerOf(token.totalSupply() - 1), OWNER);
    }

    /// Payment

    function testWithdraw(uint96 amount) public {
        vm.assume(amount >= PAYMENT);
        token.mint{ value: amount }();

        vm.prank(OWNER);
        token.withdraw(PAYMENT_RECIPIENT);

        assertEq(address(PAYMENT_RECIPIENT).balance, amount); 
    }

    function testWithdrawWhenNotOwner(uint96 amount) public {
        vm.assume(amount >= PAYMENT);
        token.mint{ value: amount }();

        vm.prank(OTHER_ADDRESS);
        vm.expectRevert("Ownable: caller is not the owner");
        token.withdraw(OTHER_ADDRESS);

        assertEq(address(token).balance, amount); 
        assertEq(address(OTHER_ADDRESS).balance, 0 ether); 
    }

    /// Token URI

    function testTokenURI() public {
        token.mint{ value: PAYMENT }();

        token.tokenURI(0);
    }

    function testTokenURINonexistentToken() public {
        vm.expectRevert(Box.NonexistentToken.selector);
        token.tokenURI(0);
    }

    /// Render

    function testRender() public {
        token.mint{ value: PAYMENT }();

        //emit log_string(token.render(0));
    }

    /// Token Naming

    function testTokenName() public {
        token.mint{ value: PAYMENT }();

        assertEq(token.tokenName(0), "Box #0");
    }
}
