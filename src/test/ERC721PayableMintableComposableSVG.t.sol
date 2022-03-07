// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {DSTest} from "ds-test/test.sol";
import {Vm} from "forge-std/Vm.sol";
import {MockERC721ComposableSVG} from "./mocks/MockERC721ComposableSVG.sol";
import {ERC721PayableMintable} from "../ERC721PayableMintable.sol";
import {ERC721PayableMintableComposableSVG} from "../ERC721PayableMintableComposableSVG.sol";
import {MockERC721PayableMintableComposableSVG} from "./mocks/MockERC721PayableMintableComposableSVG.sol";

contract ERC721PayableMintableComposableSVGTest is DSTest {
    Vm public constant vm = Vm(HEVM_ADDRESS);
    MockERC721PayableMintableComposableSVG token;
    
    uint256 constant PAYMENT = 0.001 ether;
    
    address constant OTHER_ADDRESS = address(1);
    address constant OWNER = address(2);
    address constant PAYMENT_RECIPIENT = address(3);
    address constant TOKEN_HOLDER = address(4);
    
    string constant NAME = "Name";
    string constant SYMBOL = "SYM";

    uint256 public constant PRICE = 0.001 ether;
    uint256 public constant OWNER_ALLOCATION = 88;  
    uint256 public constant SUPPLY_CAP = 888;

    int256 public constant Z_INDEX = 0;


    function setUp() public {
        vm.prank(OWNER);
        token = new MockERC721PayableMintableComposableSVG();
    }

    function testMetadata() public {
        assertEq(token.name(), NAME);
        assertEq(token.symbol(), SYMBOL);
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

    /// Compose

    function testAddBackground(int256 zIndex) public {
        vm.assume(zIndex < Z_INDEX);
        token.mint{ value: PAYMENT }();

        MockERC721ComposableSVG composable = new MockERC721ComposableSVG(zIndex);
        composable.mint();

        composable.transferToToken(0, address(token), 0);

        assertEq(composable.ownerOf(0), address(token));
    }

    function testEjectBackgroundToEOA() public {
        payable(TOKEN_HOLDER).transfer(1 ether);
        
        vm.prank(TOKEN_HOLDER);
        token.mint{ value: PAYMENT }();

        MockERC721ComposableSVG composable = new MockERC721ComposableSVG(-1);
        vm.prank(TOKEN_HOLDER);
        composable.mint();

        vm.prank(TOKEN_HOLDER);
        composable.transferToToken(0, address(token), 0);

        vm.prank(TOKEN_HOLDER);
        token.ejectToken(0, address(composable), 0);
    }

    function testAddForeground(int256 zIndex) public {
        vm.assume(zIndex > Z_INDEX);
        token.mint{ value: PAYMENT }();

        MockERC721ComposableSVG composable = new MockERC721ComposableSVG(zIndex);
        composable.mint();

        composable.transferToToken(0, address(token), 0);

        assertEq(composable.ownerOf(0), address(token));
    }

    function testEjectForegroundToEOA() public {
        payable(TOKEN_HOLDER).transfer(1 ether);
        
        vm.prank(TOKEN_HOLDER);
        token.mint{ value: PAYMENT }();

        MockERC721ComposableSVG composable = new MockERC721ComposableSVG(1);
        vm.prank(TOKEN_HOLDER);
        composable.mint();

        vm.prank(TOKEN_HOLDER);
        composable.transferToToken(0, address(token), 0);

        vm.prank(TOKEN_HOLDER);
        token.ejectToken(0, address(composable), 0);
    }

    function testAddForegroundAndBackground() public {
        token.mint{ value: PAYMENT }();

        MockERC721ComposableSVG foreground = new MockERC721ComposableSVG(1);
        foreground.mint();
        foreground.transferToToken(0, address(token), 0);

        MockERC721ComposableSVG background = new MockERC721ComposableSVG(1);
        background.mint();
        background.transferToToken(0, address(token), 0);

        assertEq(foreground.ownerOf(0), address(token));
        assertEq(background.ownerOf(0), address(token));
    }
}
