// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "ds-test/test.sol";
import "forge-std/stdlib.sol";
import "forge-std/Vm.sol";
import "../Box.sol";
import "./mocks/MockComposable.sol";

contract BoxTest is DSTest {
    Vm public constant vm = Vm(HEVM_ADDRESS);
    Box token;
    
    uint256 constant PAYMENT = 0.0001 ether;
    
    address constant OTHER_ADDRESS = address(1);
    address constant OWNER = address(2);
    address constant PAYMENT_RECIPIENT = address(3);
    address constant TOKEN_HOLDER = address(4);

    string constant TOKEN_NAME = "Token Name";
    

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

    function testAddBackground(int256 zIndex) public {
        vm.assume(zIndex < 0);
        token.mint{ value: PAYMENT }();

        MockComposable composable = new MockComposable(zIndex);
        composable.mint();

        string memory renderedToken = token.render(0);

        composable.transferToToken(0, address(token), 0);

        assertTrue(keccak256(abi.encodePacked(token.render(0))) != keccak256(abi.encodePacked(renderedToken)));
        assertEq(composable.ownerOf(0), address(token));
    }

    function testEjectBackgroundToEOA() public {
        payable(TOKEN_HOLDER).transfer(1 ether);
        
        vm.prank(TOKEN_HOLDER);
        token.mint{ value: PAYMENT }();

        MockComposable composable = new MockComposable(-1);
        vm.prank(TOKEN_HOLDER);
        composable.mint();

        vm.prank(TOKEN_HOLDER);
        composable.transferToToken(0, address(token), 0);

        vm.prank(TOKEN_HOLDER);
        token.ejectToken(0, address(composable), 0);
    }

    function testAddForeground(int256 zIndex) public {
        vm.assume(zIndex > 0);
        token.mint{ value: PAYMENT }();

        MockComposable composable = new MockComposable(zIndex);
        composable.mint();

        string memory renderedToken = token.render(0);

        composable.transferToToken(0, address(token), 0);

        assertTrue(keccak256(abi.encodePacked(token.render(0))) != keccak256(abi.encodePacked(renderedToken)));
        assertEq(composable.ownerOf(0), address(token));
    }

    function testEjectForegroundToEOA() public {
        payable(TOKEN_HOLDER).transfer(1 ether);
        
        vm.prank(TOKEN_HOLDER);
        token.mint{ value: PAYMENT }();

        MockComposable composable = new MockComposable(1);
        vm.prank(TOKEN_HOLDER);
        composable.mint();

        vm.prank(TOKEN_HOLDER);
        composable.transferToToken(0, address(token), 0);

        vm.prank(TOKEN_HOLDER);
        token.ejectToken(0, address(composable), 0);
    }

    function testAddForegroundAndBackground() public {
        token.mint{ value: PAYMENT }();

        string memory renderedToken = token.render(0);

        MockComposable foreground = new MockComposable(1);
        foreground.mint();
        foreground.transferToToken(0, address(token), 0);

        MockComposable background = new MockComposable(1);
        background.mint();
        background.transferToToken(0, address(token), 0);

        assertTrue(keccak256(abi.encodePacked(token.render(0))) != keccak256(abi.encodePacked(renderedToken)));
        assertEq(foreground.ownerOf(0), address(token));
        assertEq(background.ownerOf(0), address(token));
    }
}
